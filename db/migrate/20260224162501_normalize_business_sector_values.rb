# frozen_string_literal: true

# Data-only migration: maps free-text business_sector values to AMSF constants.
# No schema change — the column stays string.
class NormalizeBusinessSectorValues < ActiveRecord::Migration[8.1]
  # Mapping from known free-text values (from seeds/manual entry) to AMSF constants.
  MAPPING = {
    "Real Estate Investment" => "REAL_ESTATE",
    "Private Banking" => "FUND_MANAGEMENT",
    "Asset Management" => "FUND_MANAGEMENT",
    "Family Office" => "MULTI_FAMILY_OFFICE",
    "Holding Company" => "HOLDING_COMPANY",
    "International Trade" => "IMPORT_EXPORT",
    "Consulting" => nil,
    "Technology" => nil,
    "Hospitality" => nil,
    "Luxury Goods" => "HIGH_VALUE_GOODS"
  }.freeze

  # Reverse mapping for rollback (best-effort — some info is lost)
  REVERSE_MAPPING = {
    "REAL_ESTATE" => "Real Estate Investment",
    "FUND_MANAGEMENT" => "Asset Management",
    "MULTI_FAMILY_OFFICE" => "Family Office",
    "HOLDING_COMPANY" => "Holding Company",
    "IMPORT_EXPORT" => "International Trade",
    "HIGH_VALUE_GOODS" => "Luxury Goods"
  }.freeze

  def up
    MAPPING.each do |old_value, new_value|
      execute <<~SQL.squish
        UPDATE clients SET business_sector = #{new_value ? quote(new_value) : 'NULL'}
        WHERE business_sector = #{quote(old_value)}
      SQL
    end

    # Null out any remaining values that aren't valid AMSF constants
    valid_sectors = AmsfConstants::BUSINESS_SECTORS.map { |s| quote(s) }.join(", ")
    execute <<~SQL.squish
      UPDATE clients SET business_sector = NULL
      WHERE business_sector IS NOT NULL
      AND business_sector NOT IN (#{valid_sectors})
    SQL
  end

  def down
    REVERSE_MAPPING.each do |new_value, old_value|
      execute <<~SQL.squish
        UPDATE clients SET business_sector = #{quote(old_value)}
        WHERE business_sector = #{quote(new_value)}
      SQL
    end
  end
end
