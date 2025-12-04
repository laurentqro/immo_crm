# frozen_string_literal: true

# Wizard controller for step-by-step annual submission workflow.
# Steps:
#   1. Review Aggregates - Review calculated values from transactions/clients
#   2. Confirm Policies - Confirm settings-based policy values
#   3. Fresh Questions - Answer manual entry questions
#   4. Property Management - Review managed property statistics (US1)
#   5. Revenue Review - Review revenue statistics (US1)
#   6. Training Statistics - Review training data (US1)
#   7. Validate & Download - Validate XBRL and download file
class SubmissionStepsController < ApplicationController
  include OrganizationScoped

  VALID_STEPS = (1..7).to_a.freeze

  before_action :set_submission
  before_action :validate_step, except: [:lock, :unlock]
  # Note: Lock check moved to with_lock_verification helper for atomic check+update

  def show
    authorize @submission, :show?

    case @step
    when 1 then show_step_1
    when 2 then show_step_2
    when 3 then show_step_3
    when 4 then show_step_4
    when 5 then show_step_5
    when 6 then show_step_6
    when 7 then show_step_7
    end

    # Always render HTML - this is a full page wizard, not turbo stream updates
    render step_template
  end

  def update
    # For step 7 complete action, check complete? policy instead of update?
    if @step == 7 && params[:commit] == "complete"
      authorize @submission, :complete?
    else
      authorize @submission, :update?
    end

    if params[:commit] == "back"
      redirect_to_previous_step
      return
    end

    # Use pessimistic locking to prevent race conditions during update
    with_lock_verification do
      case @step
      when 1 then update_step_1
      when 2 then update_step_2
      when 3 then update_step_3
      when 4 then update_step_4
      when 5 then update_step_5
      when 6 then update_step_6
      when 7 then update_step_7
      end
    end
  end

  # === Lock/Unlock Actions (FR-029) ===

  def lock
    authorize @submission, :update?

    # Only allow locking editable submissions (draft or in_review)
    unless @submission.editable?
      redirect_to submission_submission_step_path(@submission, step: params[:step] || 1),
        alert: "Cannot lock a #{@submission.status} submission.", status: :see_other
      return
    end

    @submission.acquire_lock!(Current.user)
    redirect_to submission_submission_step_path(@submission, step: params[:step] || 1),
      notice: "Submission locked for editing.", status: :see_other
  rescue Submission::LockError => e
    redirect_to submission_submission_step_path(@submission, step: params[:step] || 1),
      alert: e.message, status: :see_other
  end

  def unlock
    # Force unlock requires admin permissions
    if params[:force].present?
      authorize @submission, :force_unlock?
      @submission.release_lock!(Current.user, force: true)
    else
      authorize @submission, :update?
      @submission.release_lock!(Current.user)
    end

    redirect_to submission_submission_step_path(@submission, step: params[:step] || 1),
      notice: "Submission unlocked.", status: :see_other
  rescue Submission::LockError => e
    redirect_to submission_submission_step_path(@submission, step: params[:step] || 1),
      alert: e.message, status: :see_other
  end

  def confirm
    authorize @submission, :confirm?

    # Use pessimistic locking to prevent race conditions during confirm
    with_lock_verification do
      case @step
      when 2
        confirm_policy_values
        redirect_to submission_submission_step_path(@submission, step: @step),
          notice: "Policy values confirmed.", status: :see_other
      when 7
        handle_step_7_confirm
      else
        redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
      end
    end
  end

  private

  def set_submission
    @submission = policy_scope(Submission).find_by(id: params[:submission_id])
    render_not_found unless @submission
  end

  def validate_step
    @step = params[:step].to_i
    render_not_found unless VALID_STEPS.include?(@step)
  end

  def step_template
    "submission_steps/step_#{@step}"
  end

  def redirect_to_previous_step
    create_step_audit_log("back")
    previous = (@step > 1) ? @step - 1 : 1
    redirect_to submission_submission_step_path(@submission, step: previous), status: :see_other
  end

  def redirect_to_next_step
    create_step_audit_log("continue")
    next_step = (@step < 7) ? @step + 1 : 7
    redirect_to submission_submission_step_path(@submission, step: next_step), status: :see_other
  end

  # Execute block with pessimistic locking to prevent race conditions.
  # Uses SELECT FOR UPDATE to atomically check lock state AND perform update.
  # Redirects with alert if locked by another user.
  def with_lock_verification
    @submission.with_lock do
      if @submission.locked? && !@submission.locked_by?(Current.user)
        redirect_to submission_submission_step_path(@submission, step: @step),
          alert: "Submission is being edited by another user.", status: :see_other
        return
      end
      yield
    end
  end

  # === Step 1: Review Aggregates ===

  def show_step_1
    # Ensure values are calculated
    if @submission.submission_values.empty?
      CalculationEngine.new(@submission).populate_submission_values!
    end

    @client_stats = calculate_client_statistics
    @transaction_stats = calculate_transaction_statistics
    @submission_values = @submission.submission_values.calculated.order(:element_name)
  end

  def update_step_1
    if step_1_params.present? && step_1_params[:submission_values_attributes].present?
      update_submission_values(step_1_params[:submission_values_attributes])
    end

    if params[:commit] == "continue"
      redirect_to_next_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step),
        notice: "Changes saved.", status: :see_other
    end
  end

  def step_1_params
    params.fetch(:submission, {}).permit(
      submission_values_attributes: [:id, :value, :override_reason]
    )
  end

  # === Step 2: Confirm Policies ===

  def show_step_2
    @policy_values = @submission.submission_values.from_settings.order(:element_name)
    @settings = current_organization.settings.first
  end

  def update_step_2
    if params[:commit] == "continue"
      redirect_to_next_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
    end
  end

  def confirm_policy_values
    # Use bulk update for better performance
    @submission.submission_values.from_settings.unconfirmed
      .update_all(confirmed_at: Time.current)
  end

  # === Step 3: Fresh Questions ===

  def show_step_3
    @manual_values = @submission.submission_values.manual.order(:element_name)
    @questions = manual_questions
  end

  def update_step_3
    if step_3_params.present? && step_3_params[:manual_values].present?
      save_manual_answers(step_3_params[:manual_values])
    end

    if params[:commit] == "continue"
      redirect_to_next_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step),
        notice: "Answers saved.", status: :see_other
    end
  end

  def step_3_params
    params.fetch(:submission, {}).permit(manual_values: {})
  end

  def save_manual_answers(manual_values)
    manual_values.each do |element_name, value|
      sv = @submission.submission_values.find_or_initialize_by(element_name: element_name)
      sv.value = value
      sv.source = "manual"
      sv.save!
    end
  end

  # === Step 4: Property Management Statistics (US1) ===

  def show_step_4
    @engine = CalculationEngine.new(@submission)
    @property_stats = @engine.managed_property_statistics
    @comparator = YearOverYearComparator.new(@submission)
    @yoy_comparison = build_yoy_comparison(@property_stats.keys)
  end

  def update_step_4
    if params[:commit] == "continue"
      redirect_to_next_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
    end
  end

  # === Step 5: Revenue Review (US1) ===

  def show_step_5
    @engine = CalculationEngine.new(@submission)
    @revenue_stats = @engine.revenue_statistics
    @comparator = YearOverYearComparator.new(@submission)
    @yoy_comparison = build_yoy_comparison(@revenue_stats.keys)
  end

  def update_step_5
    if params[:commit] == "continue"
      redirect_to_next_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
    end
  end

  # === Step 6: Training Statistics (US1) ===

  def show_step_6
    @engine = CalculationEngine.new(@submission)
    @training_stats = @engine.training_statistics
    @extended_stats = @engine.extended_client_statistics
    @comparator = YearOverYearComparator.new(@submission)
    @yoy_comparison = build_yoy_comparison(@training_stats.keys + @extended_stats.keys)
  end

  def update_step_6
    if params[:commit] == "continue"
      redirect_to_next_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
    end
  end

  # === Step 7: Validate & Download ===

  def show_step_7
    @validation_result = perform_validation
    @xbrl_preview = generate_xbrl_preview
  end

  def update_step_7
    if params[:commit] == "complete" && @submission.may_complete?
      @submission.complete!
      redirect_to @submission, notice: "Submission completed successfully.", status: :see_other
    elsif params[:commit] == "back"
      redirect_to_previous_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
    end
  end

  def handle_step_7_confirm
    if params[:action_type] == "revalidate"
      @validation_result = perform_validation(force: true)
      redirect_to submission_submission_step_path(@submission, step: @step),
        notice: "Validation re-run.", status: :see_other
    elsif @submission.in_review? && @validation_result&.valid?
      @submission.validate_submission!
      redirect_to submission_submission_step_path(@submission, step: @step),
        notice: "Submission validated successfully.", status: :see_other
    else
      redirect_to submission_submission_step_path(@submission, step: @step), status: :see_other
    end
  end

  def perform_validation(force: false)
    return @cached_validation if @cached_validation && !force

    xbrl_content = XbrlGenerator.new(@submission).generate
    @cached_validation = ValidationService.new(xbrl_content).validate
  rescue XbrlGenerator::XbrlDataError,
    ValidationService::ServiceUnavailableError,
    Nokogiri::XML::SyntaxError => e
    @cached_validation = ValidationService::Result.new(
      valid: false,
      errors: [{code: "SYS001", message: "Validation service unavailable: #{e.message}"}],
      warnings: []
    )
  end

  def generate_xbrl_preview
    XbrlGenerator.new(@submission).generate
  rescue XbrlGenerator::XbrlDataError, Nokogiri::XML::SyntaxError
    nil
  end

  # === Helper Methods ===

  def calculate_client_statistics
    {
      total: current_organization.clients.count,
      natural_persons: current_organization.clients.natural_persons.count,
      legal_entities: current_organization.clients.legal_entities.count,
      ppes: current_organization.clients.peps.count
    }
  end

  def calculate_transaction_statistics
    year_start = Date.new(@submission.year, 1, 1)
    year_end = Date.new(@submission.year, 12, 31)

    transactions = current_organization.transactions.where(
      transaction_date: year_start..year_end
    )

    {
      total: transactions.count,
      total_amount: transactions.sum(:transaction_value),
      cash_transactions: transactions.with_cash.count,
      high_risk: 0  # No high_risk scope on transactions yet
    }
  end

  def manual_questions
    # Questions that require manual input each year
    [
      {key: "rejected_clients", label: "Were any clients rejected this year?", type: "boolean"},
      {key: "rejected_count", label: "How many clients were rejected?", type: "number", depends_on: "rejected_clients"},
      {key: "sar_filed", label: "Were any SARs filed this year?", type: "boolean"},
      {key: "sar_count", label: "How many SARs were filed?", type: "number", depends_on: "sar_filed"},
      {key: "training_completed", label: "Was AML training completed this year?", type: "boolean"},
      {key: "procedure_updates", label: "Were internal procedures updated?", type: "boolean"}
    ]
  end

  def update_submission_values(attributes)
    # Preload all submission values by ID to avoid N+1 queries
    ids = attributes.values.filter_map { |attrs| attrs[:id] }
    return if ids.empty?

    overridden_values = []

    # Wrap in transaction to ensure all-or-nothing updates
    @submission.transaction do
      values_by_id = @submission.submission_values.where(id: ids).index_by(&:id)

      attributes.each_value do |attrs|
        next unless attrs[:id].present?

        value = values_by_id[attrs[:id].to_i]
        next unless value

        new_value = attrs[:value]
        override_reason = attrs[:override_reason]

        # Only process if new value provided and different from current
        next unless new_value.present? && new_value != value.value

        old_value = value.value

        # Update the value with user-provided reason or auto-generate one
        if value.calculated?
          # Use .inspect for safe serialization of user-controlled values
          reason = override_reason.presence || "Manual override: value changed from #{old_value.inspect} to #{new_value.inspect}"
          value.update!(
            value: new_value,
            overridden: true,
            override_reason: reason,
            override_user: Current.user
          )
          overridden_values << {value: value, old_value: old_value, new_value: new_value}
        else
          value.update!(value: new_value)
        end
      end

      # Create audit logs inside transaction for compliance reliability (FR-028)
      create_override_audit_logs(overridden_values) if overridden_values.any?
    end
  end

  def create_override_audit_logs(overridden_values)
    unless defined?(AuditLog)
      Rails.logger.warn("[SubmissionSteps] AuditLog not defined, skipping audit trail for overrides")
      return
    end

    overridden_values.each do |override_data|
      AuditLog.create!(
        auditable: override_data[:value],
        user: Current.user,
        organization: current_organization,
        action: "update",
        metadata: {
          # Use changed_fields array format per AuditLog validation rules
          changed_fields: [
            "#{override_data[:value].element_name}: #{override_data[:old_value].inspect} -> #{override_data[:new_value].inspect}"
          ]
        }
      )
    end
  end

  def create_step_audit_log(action)
    return unless defined?(AuditLog)

    AuditLog.create!(
      auditable: @submission,
      user: Current.user,
      organization: current_organization,
      action: "update",
      metadata: {
        changed_fields: ["step_#{@step}_#{action}"]
      }
    )
  end

  # Build year-over-year comparison data for given element names
  def build_yoy_comparison(element_names)
    comparisons = {}
    element_names.each do |element_name|
      comparisons[element_name] = @comparator.comparison_for(element_name)
    end
    comparisons
  end
end
