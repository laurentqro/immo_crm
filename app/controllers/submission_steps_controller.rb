# frozen_string_literal: true

# Wizard controller for step-by-step annual submission workflow.
# Steps:
#   1. Review Aggregates - Review calculated values from transactions/clients
#   2. Confirm Policies - Confirm settings-based policy values
#   3. Fresh Questions - Answer manual entry questions
#   4. Validate & Download - Validate XBRL and download file
class SubmissionStepsController < ApplicationController
  include OrganizationScoped

  VALID_STEPS = (1..4).to_a.freeze

  before_action :set_submission
  before_action :validate_step

  def show
    authorize @submission, :show?

    case @step
    when 1
      show_step_1
    when 2
      show_step_2
    when 3
      show_step_3
    when 4
      show_step_4
    end

    respond_to do |format|
      format.html { render step_template }
      format.turbo_stream { render step_template }
    end
  end

  def update
    # For step 4 complete action, check complete? policy instead of update?
    if @step == 4 && params[:commit] == "complete"
      authorize @submission, :complete?
    else
      authorize @submission, :update?
    end

    if params[:commit] == "back"
      redirect_to_previous_step
      return
    end

    case @step
    when 1
      update_step_1
    when 2
      update_step_2
    when 3
      update_step_3
    when 4
      update_step_4
    end
  end

  def confirm
    authorize @submission, :confirm?

    case @step
    when 2
      confirm_policy_values
      redirect_to submission_submission_step_path(@submission, step: @step),
                  notice: "Policy values confirmed."
    when 4
      handle_step_4_confirm
    else
      redirect_to submission_submission_step_path(@submission, step: @step)
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
    previous = @step > 1 ? @step - 1 : 1
    redirect_to submission_submission_step_path(@submission, step: previous)
  end

  def redirect_to_next_step
    create_step_audit_log("continue")
    next_step = @step < 4 ? @step + 1 : 4
    redirect_to submission_submission_step_path(@submission, step: next_step)
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
                  notice: "Changes saved."
    end
  end

  def step_1_params
    params.fetch(:submission, {}).permit(
      submission_values_attributes: [:id, :value]
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
      redirect_to submission_submission_step_path(@submission, step: @step)
    end
  end

  def confirm_policy_values
    @submission.submission_values.from_settings.find_each do |value|
      value.update!(confirmed_at: Time.current) unless value.confirmed?
    end
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
                  notice: "Answers saved."
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

  # === Step 4: Validate & Download ===

  def show_step_4
    @validation_result = perform_validation
    @xbrl_preview = generate_xbrl_preview
  end

  def update_step_4
    if params[:commit] == "complete" && @submission.may_complete?
      @submission.complete!
      redirect_to @submission, notice: "Submission completed successfully."
    elsif params[:commit] == "back"
      redirect_to_previous_step
    else
      redirect_to submission_submission_step_path(@submission, step: @step)
    end
  end

  def handle_step_4_confirm
    if params[:action_type] == "revalidate"
      @validation_result = perform_validation(force: true)
      redirect_to submission_submission_step_path(@submission, step: @step),
                  notice: "Validation re-run."
    elsif @submission.in_review? && @validation_result&.valid?
      @submission.validate_submission!
      redirect_to submission_submission_step_path(@submission, step: @step),
                  notice: "Submission validated successfully."
    else
      redirect_to submission_submission_step_path(@submission, step: @step)
    end
  end

  def perform_validation(force: false)
    return @cached_validation if @cached_validation && !force

    xbrl_content = XbrlGenerator.new(@submission).generate
    @cached_validation = ValidationService.new(xbrl_content).validate
  rescue StandardError => e
    @cached_validation = ValidationService::Result.new(
      valid: false,
      errors: [{ code: "SYS001", message: "Validation service unavailable: #{e.message}" }],
      warnings: []
    )
  end

  def generate_xbrl_preview
    XbrlGenerator.new(@submission).generate
  rescue StandardError
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
      { key: "rejected_clients", label: "Were any clients rejected this year?", type: "boolean" },
      { key: "rejected_count", label: "How many clients were rejected?", type: "number", depends_on: "rejected_clients" },
      { key: "sar_filed", label: "Were any SARs filed this year?", type: "boolean" },
      { key: "sar_count", label: "How many SARs were filed?", type: "number", depends_on: "sar_filed" },
      { key: "training_completed", label: "Was AML training completed this year?", type: "boolean" },
      { key: "procedure_updates", label: "Were internal procedures updated?", type: "boolean" }
    ]
  end

  def update_submission_values(attributes)
    attributes.each_value do |attrs|
      next unless attrs[:id].present?

      value = @submission.submission_values.find_by(id: attrs[:id])
      next unless value

      if attrs[:value].present? && attrs[:value] != value.value
        value.update!(value: attrs[:value], overridden: true)
      end
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
end
