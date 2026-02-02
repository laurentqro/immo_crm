class MigrateOwnershipPctToOwnershipPercentage < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE beneficial_owners
      SET ownership_percentage = ownership_pct
      WHERE ownership_pct IS NOT NULL
    SQL

    remove_column :beneficial_owners, :ownership_pct
  end

  def down
    add_column :beneficial_owners, :ownership_pct, :decimal, precision: 5, scale: 2

    execute <<-SQL
      UPDATE beneficial_owners
      SET ownership_pct = ownership_percentage
      WHERE ownership_percentage IS NOT NULL
    SQL
  end
end
