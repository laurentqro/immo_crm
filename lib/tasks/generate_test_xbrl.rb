# frozen_string_literal: true

# Script to generate a test XBRL instance document for Arelle validation
# Run with: bin/rails runner lib/tasks/generate_test_xbrl.rb
#
# This creates sample data and outputs an XBRL file you can open in Arelle
# to see validation results against the AMSF taxonomy.

puts "=" * 60
puts "XBRL Test Instance Generator"
puts "=" * 60

# Use existing organization (each Account has exactly one Organization)
organization = Organization.first

if organization.nil?
  puts "❌ No organization found. Please create one first via the UI."
  puts "   Or run: bin/rails db:seed"
  exit 1
end

puts "\n📋 Organization: #{organization.name} (RCI: #{organization.rci_number})"

# Find existing submission or create a new one
submission = organization.submissions.find_by(year: 2024) ||
  organization.submissions.create!(year: 2024, taxonomy_version: "2025")

puts "📅 Submission: Year #{submission.year}, Status: #{submission.status}"

# Sample data representing a realistic Monaco real estate firm
sample_values = {
  # Client Statistics
  "a1101" => { value: "47", source: "calculated" },      # Total clients
  "a1102" => { value: "35", source: "calculated" },      # Natural persons
  "a11502B" => { value: "10", source: "calculated" },    # Legal entities
  "a11802B" => { value: "2", source: "calculated" },     # Trusts
  "a12002B" => { value: "3", source: "calculated" },     # PEPs
  "a1401" => { value: "5", source: "calculated" },       # High-risk clients

  # Beneficial Owners
  "a1501" => { value: "52", source: "calculated" },      # Total BOs identified
  "a1502B" => { value: "2", source: "calculated" },      # PEP BOs
  "a1204O" => { value: "Oui", source: "calculated" },    # BOs with >25% ownership

  # Transactions
  "a2102B" => { value: "12", source: "calculated" },     # Purchase count
  "a2105B" => { value: "8", source: "calculated" },      # Sale count
  "a2108B" => { value: "15", source: "calculated" },     # Rental count
  "a2109B" => { value: "45000000.00", source: "calculated" }, # Total value EUR
  "a2102BB" => { value: "28000000.00", source: "calculated" }, # Purchase value
  "a2105BB" => { value: "17000000.00", source: "calculated" }, # Sale value

  # Payment Methods
  "a2202" => { value: "Non", source: "calculated" },     # Cash transactions?
  "a2501A" => { value: "Non", source: "calculated" },    # Virtual assets?

  # STR Reports
  "a3102" => { value: "1", source: "calculated" },       # STRs filed

  # Country breakdown (dimensional data)
  "a1103" => {
    value: { "FR" => 15, "IT" => 8, "GB" => 6, "MC" => 5, "RU" => 4, "CH" => 3, "US" => 3, "AE" => 3 }.to_json,
    source: "calculated"
  }
}

# Create or update submission values
puts "\n📊 Creating submission values..."
sample_values.each do |element_name, config|
  sv = submission.submission_values.find_or_initialize_by(element_name: element_name)
  sv.update!(value: config[:value], source: config[:source])
  puts "   ✓ #{element_name}: #{config[:value].to_s.truncate(50)}"
end

# Generate XBRL
puts "\n🔧 Generating XBRL instance document..."
generator = XbrlGenerator.new(submission)
xbrl_content = generator.generate

# Save to file
output_dir = Rails.root.join("tmp", "xbrl")
FileUtils.mkdir_p(output_dir)
output_file = output_dir.join(generator.suggested_filename)

File.write(output_file, xbrl_content)

puts "\n" + "=" * 60
puts "✅ SUCCESS! Instance document created:"
puts "=" * 60
puts "\n📁 File: #{output_file}"
puts "\n📏 Size: #{File.size(output_file)} bytes"
puts "\n🔍 To validate in Arelle:"
puts "   1. Open Arelle"
puts "   2. File → Open"
puts "   3. Select: #{output_file}"
puts "   4. Check the Messages panel for validation results"
puts "\n💡 Tip: Also load the taxonomy (docs/strix_Real_Estate_AML_CFT_survey_2025.xsd)"
puts "   to see how your elements map to taxonomy concepts."
puts "\n" + "=" * 60
