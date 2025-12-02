# frozen_string_literal: true

# Controller for organization-wide settings management.
# Settings are displayed in categorized sections and can be updated in batch.
# Settings use singular resource routes (GET/PATCH /settings) since there's one settings page per org.
class SettingsController < ApplicationController
  include OrganizationScoped

  def index
    authorize Setting
    @settings = policy_scope(Setting).order(:category, :key)
    @settings_by_category = @settings.group_by(&:category)
    @current_category = params[:category] || "entity_info"
  end

  def update
    authorize Setting
    updated_count = 0
    current_key = nil

    ActiveRecord::Base.transaction do
      settings_params.each do |key, value|
        # Skip unknown keys - only allow keys defined in schema
        schema = Setting::SCHEMA[key]
        next unless schema

        current_key = key
        setting = current_organization.settings.find_or_initialize_by(key: key)

        # Set schema attributes for new settings
        if setting.new_record?
          setting.value_type = schema[:value_type]
          setting.category = schema[:category]
          setting.xbrl_element = schema[:xbrl]
        end

        setting.update!(value: value.to_s)
        updated_count += 1
      end
    end

    respond_to do |format|
      format.html { redirect_to settings_path, notice: "#{updated_count} #{'setting'.pluralize(updated_count)} saved successfully." }
      format.turbo_stream { flash.now[:notice] = "#{updated_count} #{'setting'.pluralize(updated_count)} saved successfully." }
    end
  rescue ActiveRecord::RecordInvalid => e
    error_msg = current_key ? "Failed to save '#{current_key}': #{e.record.errors.full_messages.join(', ')}" : e.message
    respond_to do |format|
      format.html { redirect_to settings_path, alert: error_msg }
      format.turbo_stream { flash.now[:alert] = error_msg }
    end
  end

  private

  # Only permit known setting keys from the schema - prevents mass assignment attacks.
  # Uses slice to extract only allowed keys, then permit to convert to permitted params.
  # @see https://api.rubyonrails.org/classes/ActionController/Parameters.html
  def settings_params
    params.require(:settings).slice(*Setting::SCHEMA.keys).permit!
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new({}).permit!
  end
end
