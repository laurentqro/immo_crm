# frozen_string_literal: true

module SettingsHelper
  # Get the value of a setting by key for the current organization
  # Returns the setting value or nil if not found
  def get_setting_value(key)
    return nil unless @settings_by_category

    @settings_by_category.values.flatten.find { |s| s.key == key }&.value
  end
end
