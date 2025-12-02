# frozen_string_literal: true

# Handles organization setup wizard for new users.
# Two-step flow: Entity Info → Compliance Policies → Dashboard
#
# Data is stored in session until final step to avoid orphan records.
#
# NOTE: Settings model will be implemented in Phase 4 (US4). For now,
# onboarding creates the Organization only. Policy settings will be
# added to the organization after the Setting model is created.
class OnboardingController < ApplicationController
  before_action :redirect_if_organization_exists, only: [:new, :create, :entity_info, :policies]

  # GET /onboarding/new - Start of wizard (shows entity_info form)
  def new
    @organization = Organization.new
    render :entity_info
  end

  # POST /onboarding - Final submission (creates organization)
  def create
    @organization = build_organization_from_params

    if @organization.save
      clear_onboarding_session
      redirect_to dashboard_path, notice: "Organization setup complete! Welcome to Immo CRM."
    else
      render :entity_info, status: :unprocessable_entity
    end
  end

  # GET /onboarding/entity_info - Step 1 form
  def entity_info
    @organization = Organization.new(session_organization_params)
  end

  # POST /onboarding/entity_info - Save step 1, advance to step 2
  def entity_info_submit
    @organization = Organization.new(organization_params.merge(account: current_account))

    if @organization.valid?
      # Store in session, don't persist yet
      session[:onboarding] ||= {}
      session[:onboarding][:organization] = organization_params.to_h
      session[:onboarding][:settings] = settings_params.to_h

      redirect_to policies_onboarding_index_path
    else
      render :entity_info, status: :unprocessable_entity
    end
  end

  # GET /onboarding/policies - Step 2 form
  def policies
    # Ensure step 1 was completed
    # Note: session keys may be symbols or strings depending on Rails version/serializer
    unless onboarding_session_present?
      redirect_to new_onboarding_path, alert: "Please complete entity information first."
      return
    end

    @organization = Organization.new(session_organization_params)
    @settings = session_settings_params
  end

  # POST /onboarding/policies - Complete wizard
  def policies_submit
    unless onboarding_session_present?
      redirect_to new_onboarding_path, alert: "Please complete entity information first."
      return
    end

    @organization = build_organization_from_session

    if @organization.save
      # TODO: Create initial settings when Setting model is implemented (US4)
      clear_onboarding_session
      redirect_to dashboard_path, notice: "Organization setup complete! Welcome to Immo CRM."
    else
      render :policies, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_organization_exists
    return unless current_account&.organization.present?

    redirect_to dashboard_path, notice: "Your organization is already set up."
  end

  def build_organization_from_params
    Organization.new(organization_params.merge(account: current_account))
  end

  def build_organization_from_session
    Organization.new(session_organization_params.merge(account: current_account))
  end

  def organization_params
    params.expect(organization: [:name, :rci_number, :country])
  end

  def settings_params
    params.fetch(:settings, ActionController::Parameters.new).permit(
      :total_employees, :compliance_officers, :annual_revenue
    )
  end

  def policy_settings_params
    params.fetch(:settings, ActionController::Parameters.new).permit(
      :edd_for_peps, :edd_for_high_risk_countries, :edd_for_complex_structures,
      :written_aml_policy, :training_frequency
    )
  end

  # Session key handling: Rails cookie serializer may use symbols (MessagePack) or
  # strings (JSON) depending on configuration. These helpers handle both to ensure
  # compatibility across Rails versions and serializer settings.
  # See: config/initializers/cookies_serializer.rb
  def session_organization_params
    onboarding_data = session[:onboarding] || session["onboarding"]
    return {}.with_indifferent_access unless onboarding_data

    org_data = onboarding_data[:organization] || onboarding_data["organization"] || {}
    org_data.with_indifferent_access
  end

  def session_settings_params
    onboarding_data = session[:onboarding] || session["onboarding"]
    return {}.with_indifferent_access unless onboarding_data

    settings_data = onboarding_data[:settings] || onboarding_data["settings"] || {}
    settings_data.with_indifferent_access
  end

  # Check if onboarding session data is present.
  # Handles both symbol and string keys for cross-serializer compatibility.
  def onboarding_session_present?
    onboarding_data = session[:onboarding] || session["onboarding"]
    return false unless onboarding_data

    org_data = onboarding_data[:organization] || onboarding_data["organization"]
    org_data.present?
  end

  def clear_onboarding_session
    session.delete(:onboarding)
    session.delete("onboarding")
  end
end
