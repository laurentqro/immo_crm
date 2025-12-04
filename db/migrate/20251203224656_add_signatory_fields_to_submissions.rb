class AddSignatoryFieldsToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :signatory_name, :string
    add_column :submissions, :signatory_title, :string
  end
end
