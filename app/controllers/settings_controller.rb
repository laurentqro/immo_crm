# frozen_string_literal: true

# Controller for organization-wide settings management.
# Settings are displayed in categorized sections and can be updated in batch.
# Settings use singular resource routes (GET/PATCH /settings) since there's one settings page per org.
class SettingsController < ApplicationController
  include OrganizationScoped

  # GET /settings - Display all settings for the organization
  # Uses `show` action for RESTful consistency with singular resource routing
  def show
    authorize Setting
    @settings = policy_scope(Setting).order(:category, :key)
    @settings_by_category = @settings.group_by(&:category)
    @current_category = params[:category] || "entity_info"
  end

  def update
    authorize Setting
    updated_count = 0

    ActiveRecord::Base.transaction do
      settings_params.each do |key, value|
        setting = current_organization.settings.find_or_initialize_by(key: key)
        setting.category ||= category_for_key(key)
        setting.value = value.to_s
        setting.save!
        updated_count += 1
      end
    end

    respond_to do |format|
      format.html { redirect_to settings_path, notice: "#{updated_count} #{'setting'.pluralize(updated_count)} saved successfully." }
      format.turbo_stream { flash.now[:notice] = "#{updated_count} #{'setting'.pluralize(updated_count)} saved successfully." }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to settings_path, alert: "Failed to save settings: #{e.record.errors.full_messages.join(', ')}" }
      format.turbo_stream { flash.now[:alert] = "Failed to save settings: #{e.record.errors.full_messages.join(', ')}" }
    end
  end

  private

  # Maps setting keys to their categories
  SETTING_CATEGORIES = {
    "entity_name" => "entity_info",
    "legal_form" => "entity_info",
    "amsf_registration_number" => "entity_info",
    "total_employees" => "entity_info",
    "compliance_officers" => "entity_info",
    "annual_revenue" => "entity_info",
    "activity_sales" => "entity_info",
    "activity_rentals" => "entity_info",
    "activity_property_management" => "entity_info",
    "staff_total" => "entity_info",
    "staff_compliance" => "entity_info",
    "uses_external_compliance" => "entity_info",
    "edd_for_peps" => "kyc_procedures",
    "edd_for_high_risk_countries" => "kyc_procedures",
    "edd_for_complex_structures" => "kyc_procedures",
    "sdd_applied" => "kyc_procedures",
    "written_aml_policy" => "compliance_policies",
    "policy_last_updated" => "compliance_policies",
    "risk_assessment_performed" => "compliance_policies",
    "internal_controls" => "compliance_policies",
    "training_frequency" => "training",
    "last_training_date" => "training",
    "training_covers_aml" => "training"
  }.freeze

  def category_for_key(key)
    SETTING_CATEGORIES[key] || "entity_info"
  end

  def settings_params
    params.expect(settings: [
      :entity_name,
      :legal_form,
      :amsf_registration_number,
      :total_employees,
      :compliance_officers,
      :annual_revenue,
      :activity_sales,
      :activity_rentals,
      :activity_property_management,
      :staff_total,
      :staff_compliance,
      :uses_external_compliance,
      :edd_for_peps,
      :edd_for_high_risk_countries,
      :edd_for_complex_structures,
      :sdd_applied,
      :written_aml_policy,
      :policy_last_updated,
      :risk_assessment_performed,
      :internal_controls,
      :training_frequency,
      :last_training_date,
      :training_covers_aml
    ])
  end
end
