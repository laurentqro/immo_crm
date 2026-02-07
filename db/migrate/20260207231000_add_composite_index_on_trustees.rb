# frozen_string_literal: true

class AddCompositeIndexOnTrustees < ActiveRecord::Migration[8.1]
  def change
    add_index :trustees, [:client_id, :is_professional]
  end
end
