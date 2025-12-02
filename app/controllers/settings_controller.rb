# frozen_string_literal: true

# Controller for organization-wide settings management.
# Settings are displayed in categorized sections and can be updated in batch.
class SettingsController < ApplicationController
  include OrganizationScoped

  # Schema for known settings with their types and categories
  SETTING_SCHEMA = {
    # Entity Info
    "entity_name" => {value_type: "string", category: "entity_info", xbrl: "a0101"},
    "total_employees" => {value_type: "integer", category: "entity_info", xbrl: "a0102"},
    "compliance_officers" => {value_type: "integer", category: "entity_info", xbrl: "a0103"},
    "annual_revenue" => {value_type: "decimal", category: "entity_info", xbrl: "a0104"},
    # KYC Procedures
    "edd_for_peps" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4101"},
    "edd_for_high_risk_countries" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4102"},
    "edd_for_complex_structures" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4103"},
    "sdd_applied" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4104"},
    # Compliance Policies
    "written_aml_policy" => {value_type: "boolean", category: "compliance_policies", xbrl: "a5101"},
    "policy_last_updated" => {value_type: "date", category: "compliance_policies", xbrl: "a5102"},
    "risk_assessment_performed" => {value_type: "boolean", category: "compliance_policies", xbrl: "a5103"},
    "internal_controls" => {value_type: "boolean", category: "compliance_policies", xbrl: "a5104"},
    # Training
    "training_frequency" => {value_type: "enum", category: "training", xbrl: "a6101"},
    "last_training_date" => {value_type: "date", category: "training", xbrl: "a6102"},
    "training_covers_aml" => {value_type: "boolean", category: "training", xbrl: "a6103"}
  }.freeze

  def index
    authorize Setting
    @settings = policy_scope(Setting).order(:category, :key)
    @settings_by_category = @settings.group_by(&:category)
    @current_category = params[:category] || "entity_info"
  end

  def update
    authorize Setting

    ActiveRecord::Base.transaction do
      settings_params.each do |key, value|
        setting = current_organization.settings.find_or_initialize_by(key: key)

        # Set schema attributes for new settings
        if setting.new_record? && SETTING_SCHEMA.key?(key)
          schema = SETTING_SCHEMA[key]
          setting.value_type = schema[:value_type]
          setting.category = schema[:category]
          setting.xbrl_element = schema[:xbrl]
        end

        setting.update!(value: value.to_s)
      end
    end

    respond_to do |format|
      format.html { redirect_to settings_path, notice: "Settings saved successfully." }
      format.turbo_stream { flash.now[:notice] = "Settings saved successfully." }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to settings_path, alert: "Failed to save settings: #{e.message}" }
      format.turbo_stream { flash.now[:alert] = "Failed to save settings: #{e.message}" }
    end
  end

  private

  def settings_params
    params.fetch(:settings, {}).permit!
  end
end
