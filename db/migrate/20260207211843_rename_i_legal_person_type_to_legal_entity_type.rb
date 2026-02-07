# frozen_string_literal: true

class RenameILegalPersonTypeToLegalEntityType < ActiveRecord::Migration[8.1]
  def change
    rename_column :clients, :legal_person_type, :legal_entity_type
    rename_column :clients, :legal_person_type_other, :legal_entity_type_other
  end
end
