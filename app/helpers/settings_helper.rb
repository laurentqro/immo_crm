# frozen_string_literal: true

module SettingsHelper
  # Get the value of a setting by key for the current organization.
  # Returns the setting value or the default if not found.
  #
  # @param key [String] The setting key to look up
  # @param default [Object] The default value if setting not found (default: nil)
  # @return [String, nil] The setting value or default
  def get_setting_value(key, default = nil)
    return default unless @settings_by_category

    @settings_by_category.values.flatten.find { |s| s.key == key }&.value || default
  end
end
