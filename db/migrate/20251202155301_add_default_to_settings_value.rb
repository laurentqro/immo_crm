# frozen_string_literal: true

class AddDefaultToSettingsValue < ActiveRecord::Migration[8.1]
  def up
    # Convert any existing NULLs to empty string before adding constraint
    Setting.where(value: nil).update_all(value: "")

    change_column_default :settings, :value, from: nil, to: ""
    change_column_null :settings, :value, false
  end

  def down
    change_column_null :settings, :value, true
    change_column_default :settings, :value, from: "", to: nil
  end
end
