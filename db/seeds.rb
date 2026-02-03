# frozen_string_literal: true

# Seeds for development/testing environment
# Run with: bin/rails db:seed
#
# Creates test data for the Immo CRM application including:
# - A test user and account
# - An organization (Monaco real estate agency)
# - Sample clients (natural persons, legal entities, trusts)
# - Beneficial owners for legal entities

puts "Seeding database..."

# Only seed in development
unless Rails.env.development?
  puts "Skipping seed data - only runs in development"
  exit
end

# Clean up existing data (be careful in production!)
puts "Cleaning existing data..."
Training.destroy_all
ManagedProperty.destroy_all
StrReport.destroy_all
Transaction.destroy_all
BeneficialOwner.destroy_all
Client.destroy_all
Organization.destroy_all

# Create test user if not exists
test_email = "test@example.com"
user = User.find_by(email: test_email)

unless user
  puts "Creating test user..."
  user = User.create!(
    name: "Test User",
    email: test_email,
    password: "password123",
    password_confirmation: "password123",
    terms_of_service: true
  )
end

# Get or create account (Jumpstart creates personal account automatically)
account = user.accounts.first || user.personal_account

puts "Using account: #{account.name}"

# Create organization if not exists
organization = Organization.find_by(account: account)

unless organization
  puts "Creating organization..."
  organization = Organization.create!(
    account: account,
    name: "Monaco Premier Properties",
    rci_number: "MC#{rand(10000..99999)}",
    country: "MC"
  )
end

puts "Organization: #{organization.name}"

# Country codes commonly seen in Monaco real estate
NATIONALITIES = %w[MC FR IT CH GB US RU CN AE SA].freeze
COUNTRIES = %w[MC FR IT CH GB US AE].freeze

# Business sectors for legal entities
BUSINESS_SECTORS = [
  "Real Estate Investment",
  "Private Banking",
  "Asset Management",
  "Family Office",
  "Holding Company",
  "International Trade",
  "Consulting",
  "Technology",
  "Hospitality",
  "Luxury Goods"
].freeze

# Introducer countries for clients brought in by third parties
INTRODUCER_COUNTRIES = %w[FR CH GB IT US].freeze

# Third-party CDD provider countries (foreign providers)
THIRD_PARTY_CDD_COUNTRIES = %w[FR CH GB LU].freeze

puts "Creating clients..."

# Create natural persons (15 clients)
15.times do |i|
  is_pep = i < 3 # First 3 are PEPs
  risk = case i
         when 0..2 then "HIGH"
         when 3..5 then "MEDIUM"
         else "LOW"
         end

  # ~20% of clients are introduced by third parties (indices 0, 5, 10)
  is_introduced = i % 5 == 0

  # ~15% of clients have third-party CDD (indices 1, 6, 11)
  has_third_party_cdd = (i - 1) % 5 == 0 && i > 0
  third_party_cdd_type = has_third_party_cdd ? %w[LOCAL FOREIGN].sample : nil
  third_party_cdd_country = (has_third_party_cdd && third_party_cdd_type == "FOREIGN") ? THIRD_PARTY_CDD_COUNTRIES.sample : nil

  client = Client.create!(
    organization: organization,
    name: Faker::Name.name,
    client_type: "NATURAL_PERSON",
    nationality: NATIONALITIES.sample,
    residence_country: COUNTRIES.sample,
    risk_level: risk,
    is_pep: is_pep,
    pep_type: is_pep ? %w[DOMESTIC FOREIGN INTL_ORG].sample : nil,
    became_client_at: Faker::Date.between(from: 5.years.ago, to: Date.today),
    notes: i < 5 ? Faker::Lorem.paragraph(sentence_count: 2) : nil,
    introduced_by_third_party: is_introduced,
    introducer_country: is_introduced ? INTRODUCER_COUNTRIES.sample : nil,
    third_party_cdd: has_third_party_cdd,
    third_party_cdd_type: third_party_cdd_type,
    third_party_cdd_country: third_party_cdd_country
  )

  intro_tag = client.introduced_by_third_party? ? ", introduced from #{client.introducer_country}" : ""
  cdd_tag = client.third_party_cdd? ? ", 3rd-party CDD (#{client.third_party_cdd_type}#{client.third_party_cdd_country ? " - #{client.third_party_cdd_country}" : ""})" : ""
  puts "  - Created natural person: #{client.name} (#{client.risk_level} risk#{', PEP' if client.is_pep?}#{intro_tag}#{cdd_tag})"
end

# Countries of incorporation for legal entities (mix of Monaco and common offshore/EU)
INCORPORATION_COUNTRIES = %w[MC FR LU CH GB JE GG LI].freeze

# Create legal entities (10 clients)
10.times do |i|
  is_pep = i < 2 # First 2 have PEP beneficial owners (we'll add them below)
  risk = case i
         when 0..1 then "HIGH"
         when 2..4 then "MEDIUM"
         else "LOW"
         end

  legal_type = %w[SCI SARL SAM SA].sample

  # ~20% of clients are introduced by third parties (indices 0, 5)
  is_introduced = i % 5 == 0

  # ~20% of legal entities have third-party CDD (indices 2, 7)
  has_third_party_cdd = (i - 2) % 5 == 0
  third_party_cdd_type = has_third_party_cdd ? %w[LOCAL FOREIGN].sample : nil
  third_party_cdd_country = (has_third_party_cdd && third_party_cdd_type == "FOREIGN") ? THIRD_PARTY_CDD_COUNTRIES.sample : nil

  # Incorporation country - first 3 are Monaco, rest are mixed
  incorporation_country = i < 3 ? "MC" : INCORPORATION_COUNTRIES.sample

  client = Client.create!(
    organization: organization,
    name: "#{Faker::Company.name} #{legal_type}",
    client_type: "LEGAL_ENTITY",
    legal_person_type: legal_type,
    nationality: NATIONALITIES.sample,
    residence_country: COUNTRIES.sample,
    incorporation_country: incorporation_country,
    business_sector: BUSINESS_SECTORS.sample,
    risk_level: risk,
    is_pep: is_pep,
    pep_type: is_pep ? %w[DOMESTIC FOREIGN].sample : nil,
    became_client_at: Faker::Date.between(from: 5.years.ago, to: Date.today),
    notes: Faker::Lorem.paragraph(sentence_count: 2),
    introduced_by_third_party: is_introduced,
    introducer_country: is_introduced ? INTRODUCER_COUNTRIES.sample : nil,
    third_party_cdd: has_third_party_cdd,
    third_party_cdd_type: third_party_cdd_type,
    third_party_cdd_country: third_party_cdd_country
  )

  # Add 1-3 beneficial owners for each legal entity
  rand(1..3).times do
    is_owner_pep = client.is_pep? && BeneficialOwner.where(client: client).count == 0

    BeneficialOwner.create!(
      client: client,
      name: Faker::Name.name,
      nationality: NATIONALITIES.sample,
      residence_country: COUNTRIES.sample,
      ownership_percentage: [25, 33, 50, 51, 75, 100].sample,
      control_type: %w[DIRECT INDIRECT REPRESENTATIVE].sample,
      is_pep: is_owner_pep,
      pep_type: is_owner_pep ? %w[DOMESTIC FOREIGN INTL_ORG].sample : nil
    )
  end

  owner_count = client.beneficial_owners.count
  puts "  - Created legal entity: #{client.name} (#{owner_count} beneficial owner#{'s' if owner_count > 1})"
end

# Create trusts (5 clients)
# Trustee jurisdictions common for Monaco real estate
TRUSTEE_COUNTRIES = %w[CH GB JE GG LI MC].freeze

5.times do |i|
  risk = i < 2 ? "HIGH" : "MEDIUM"
  trustee_country = TRUSTEE_COUNTRIES.sample
  is_professional = i < 3 # First 3 trusts have professional trustees

  # ~20% of clients are introduced by third parties (index 0)
  is_introduced = i == 0

  # ~40% of trusts have third-party CDD (indices 1, 3) - trusts often use external CDD
  has_third_party_cdd = i == 1 || i == 3
  third_party_cdd_type = has_third_party_cdd ? %w[LOCAL FOREIGN].sample : nil
  third_party_cdd_country = (has_third_party_cdd && third_party_cdd_type == "FOREIGN") ? THIRD_PARTY_CDD_COUNTRIES.sample : nil

  # Incorporation country for trusts - typically offshore jurisdictions
  trust_incorporation_country = i < 2 ? "MC" : %w[JE GG CH LI].sample

  client = Client.create!(
    organization: organization,
    name: "#{Faker::Name.last_name} Family Trust",
    client_type: "TRUST",
    nationality: %w[CH GB JE GG].sample,
    residence_country: COUNTRIES.sample,
    incorporation_country: trust_incorporation_country,
    risk_level: risk,
    became_client_at: Faker::Date.between(from: 5.years.ago, to: Date.today),
    notes: "Trust established for #{Faker::Company.bs}",
    trustee_name: is_professional ? "#{Faker::Company.name} Trust Services" : Faker::Name.name,
    trustee_nationality: NATIONALITIES.sample,
    trustee_country: trustee_country,
    is_professional_trustee: is_professional,
    introduced_by_third_party: is_introduced,
    introducer_country: is_introduced ? INTRODUCER_COUNTRIES.sample : nil,
    third_party_cdd: has_third_party_cdd,
    third_party_cdd_type: third_party_cdd_type,
    third_party_cdd_country: third_party_cdd_country
  )

  # Add 2-4 beneficial owners for each trust
  rand(2..4).times do
    BeneficialOwner.create!(
      client: client,
      name: Faker::Name.name,
      nationality: NATIONALITIES.sample,
      residence_country: COUNTRIES.sample,
      control_type: %w[DIRECT INDIRECT].sample,
      is_pep: false
    )
  end

  owner_count = client.beneficial_owners.count
  puts "  - Created trust: #{client.name} (#{owner_count} beneficial owners)"
end

# Create one ended client relationship
ended_client = Client.create!(
  organization: organization,
  name: Faker::Name.name,
  client_type: "NATURAL_PERSON",
  nationality: "FR",
  residence_country: "FR",
  risk_level: "LOW",
  became_client_at: 3.years.ago,
  relationship_ended_at: 6.months.ago,
  notes: "Relationship ended - client relocated"
)
puts "  - Created ended relationship: #{ended_client.name}"

# ============================================
# Managed Properties (Property Management Contracts)
# ============================================
puts ""
puts "Creating managed properties..."

# Monaco addresses for realistic property data
MONACO_STREETS = [
  "Avenue Princesse Grace",
  "Boulevard des Moulins",
  "Avenue de Monte-Carlo",
  "Rue Grimaldi",
  "Boulevard Albert 1er",
  "Avenue de la Costa",
  "Rue du Portier",
  "Avenue Saint-Michel",
  "Boulevard du Larvotto",
  "Rue des Roses"
].freeze

MONACO_DISTRICTS = %w[Monte-Carlo Fontvieille La\ Condamine Monaco-Ville Larvotto].freeze

# Get clients who can be landlords (legal entities and wealthy individuals)
potential_landlords = Client.where(client_type: %w[LEGAL_ENTITY TRUST])
                            .or(Client.where(client_type: "NATURAL_PERSON", risk_level: %w[HIGH MEDIUM]))
                            .to_a

current_year = Date.current.year

# Create 12 active managed properties
12.times do |i|
  landlord = potential_landlords.sample
  property_type = i < 9 ? "RESIDENTIAL" : "COMMERCIAL"

  # Monaco rental values
  monthly_rent = case property_type
                 when "RESIDENTIAL"
                   [3500, 5000, 6500, 8000, 12000, 18000, 25000, 35000].sample
                 when "COMMERCIAL"
                   [8000, 12000, 20000, 35000, 50000].sample
                 end

  # Fee structure: either percentage (8-12%) or fixed
  use_percentage = rand < 0.7
  fee_percent = use_percentage ? [8, 9, 10, 12].sample : nil
  fee_fixed = use_percentage ? nil : [500, 750, 1000, 1500, 2000].sample

  street = MONACO_STREETS.sample
  building_number = rand(1..100)
  apartment = property_type == "RESIDENTIAL" ? ", Apt #{rand(1..50)}" : ""

  # Start date between 3 years ago and 6 months ago
  start_date = Faker::Date.between(from: 3.years.ago, to: 6.months.ago)

  property = ManagedProperty.create!(
    organization: organization,
    client: landlord,
    property_address: "#{building_number} #{street}#{apartment}, #{MONACO_DISTRICTS.sample}",
    property_type: property_type,
    management_start_date: start_date,
    monthly_rent: monthly_rent,
    management_fee_percent: fee_percent,
    management_fee_fixed: fee_fixed,
    tenant_type: %w[NATURAL_PERSON LEGAL_ENTITY].sample,
    tenant_country: COUNTRIES.sample,
    notes: rand < 0.3 ? Faker::Lorem.sentence : nil
  )

  puts "  - #{property.property_type.downcase.capitalize}: #{property.property_address[0..40]}... (€#{property.monthly_rent}/month)"
end

# Create 3 ended management contracts
3.times do |i|
  landlord = potential_landlords.sample
  start_date = Faker::Date.between(from: 4.years.ago, to: 2.years.ago)
  end_date = Faker::Date.between(from: start_date + 6.months, to: 6.months.ago)

  street = MONACO_STREETS.sample

  property = ManagedProperty.create!(
    organization: organization,
    client: landlord,
    property_address: "#{rand(1..100)} #{street}, Apt #{rand(1..30)}, #{MONACO_DISTRICTS.sample}",
    property_type: "RESIDENTIAL",
    management_start_date: start_date,
    management_end_date: end_date,
    monthly_rent: [4000, 5500, 7000, 9000].sample,
    management_fee_percent: 10,
    tenant_type: "NATURAL_PERSON",
    tenant_country: %w[FR IT CH GB].sample,
    notes: "Contract ended - tenant relocated"
  )

  puts "  - Ended contract: #{property.property_address[0..40]}..."
end

puts "  Created #{ManagedProperty.active.count} active + #{ManagedProperty.ended.count} ended properties"

# ============================================
# Transactions
# ============================================
puts ""
puts "Creating transactions..."

# Get all active clients for transaction assignment
active_clients = Client.where(relationship_ended_at: nil).to_a

# Monaco property value ranges (in EUR)
PROPERTY_VALUES = {
  purchase: {
    min: 500_000,
    max: 50_000_000,
    typical: [800_000, 1_200_000, 2_500_000, 5_000_000, 8_000_000, 15_000_000]
  },
  rental: {
    min: 2_000,
    max: 50_000,
    typical: [3_500, 5_000, 8_000, 12_000, 25_000]
  }
}.freeze

# Create transactions for current year
current_year = Date.current.year
transaction_count = 0

# Create 25 transactions for current year
25.times do |i|
  client = active_clients.sample
  transaction_type = %w[PURCHASE SALE RENTAL].sample

  # Determine value based on transaction type
  value = case transaction_type
          when "PURCHASE", "SALE"
            PROPERTY_VALUES[:purchase][:typical].sample + rand(-100_000..100_000)
          when "RENTAL"
            # Monthly rental * 12 for annual value
            PROPERTY_VALUES[:rental][:typical].sample * 12
          end

  # Payment method - more cash for smaller transactions
  payment_method = if value < 1_000_000 && rand < 0.3
                     %w[CASH MIXED].sample
                   else
                     %w[WIRE CHECK].sample
                   end

  # Cash amount for CASH or MIXED payments
  cash_amount = case payment_method
                when "CASH"
                  value
                when "MIXED"
                  [10_000, 15_000, 20_000, 50_000].sample
                else
                  nil
                end

  # Commission is typically 3-5% of transaction value
  commission = (value * rand(0.03..0.05)).round(2) if transaction_type != "RENTAL"

  # Agency role
  agency_role = %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].sample

  # Purchase purpose (only for purchases)
  purchase_purpose = transaction_type == "PURCHASE" ? %w[RESIDENCE INVESTMENT].sample : nil

  # Random date within current year
  transaction_date = Faker::Date.between(
    from: Date.new(current_year, 1, 1),
    to: [Date.new(current_year, 12, 31), Date.current].min
  )

  transaction = Transaction.create!(
    organization: organization,
    client: client,
    transaction_date: transaction_date,
    transaction_type: transaction_type,
    transaction_value: value,
    payment_method: payment_method,
    cash_amount: cash_amount,
    agency_role: agency_role,
    purchase_purpose: purchase_purpose,
    commission_amount: commission,
    property_country: "MC",
    reference: "TXN-#{current_year}-#{(i + 1).to_s.rjust(4, '0')}",
    notes: rand < 0.3 ? Faker::Lorem.sentence : nil
  )

  transaction_count += 1
  puts "  - #{transaction.reference}: #{transaction.transaction_type_label} €#{transaction.transaction_value.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
end

# Create 15 transactions for previous year
previous_year = current_year - 1
15.times do |i|
  client = active_clients.sample
  transaction_type = %w[PURCHASE SALE RENTAL].sample

  value = case transaction_type
          when "PURCHASE", "SALE"
            PROPERTY_VALUES[:purchase][:typical].sample + rand(-100_000..100_000)
          when "RENTAL"
            PROPERTY_VALUES[:rental][:typical].sample * 12
          end

  payment_method = value < 1_000_000 && rand < 0.3 ? %w[CASH MIXED].sample : %w[WIRE CHECK].sample
  cash_amount = payment_method == "CASH" ? value : (payment_method == "MIXED" ? [10_000, 15_000, 20_000].sample : nil)
  commission = (value * rand(0.03..0.05)).round(2) if transaction_type != "RENTAL"

  transaction_date = Faker::Date.between(
    from: Date.new(previous_year, 1, 1),
    to: Date.new(previous_year, 12, 31)
  )

  Transaction.create!(
    organization: organization,
    client: client,
    transaction_date: transaction_date,
    transaction_type: transaction_type,
    transaction_value: value,
    payment_method: payment_method,
    cash_amount: cash_amount,
    agency_role: %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].sample,
    purchase_purpose: transaction_type == "PURCHASE" ? %w[RESIDENCE INVESTMENT].sample : nil,
    commission_amount: commission,
    property_country: "MC",
    reference: "TXN-#{previous_year}-#{(i + 1).to_s.rjust(4, '0')}"
  )

  transaction_count += 1
end

puts "  - Created #{15} transactions for #{previous_year}"

# ============================================
# STR Reports
# ============================================
puts ""
puts "Creating STR reports..."

# Create a few STR reports linked to transactions
str_count = 0

# Find transactions with cash payments for STR reports
cash_transactions = Transaction.where(payment_method: %w[CASH MIXED])
                               .where.not(cash_amount: nil)
                               .limit(3)

cash_transactions.each do |txn|
  StrReport.create!(
    organization: organization,
    client: txn.client,
    linked_transaction: txn,
    report_date: txn.transaction_date + rand(1..7).days,
    reason: "CASH",
    notes: "Cash payment of €#{txn.cash_amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} flagged for review"
  )
  str_count += 1
  puts "  - STR for cash transaction: #{txn.reference}"
end

# Create STR for PEP clients
pep_clients = Client.peps.limit(2)
pep_clients.each do |client|
  StrReport.create!(
    organization: organization,
    client: client,
    report_date: Faker::Date.between(from: 6.months.ago, to: Date.current),
    reason: "PEP",
    notes: "Politically Exposed Person - enhanced monitoring applied"
  )
  str_count += 1
  puts "  - STR for PEP client: #{client.name}"
end

# Create STR for unusual pattern
StrReport.create!(
  organization: organization,
  client: active_clients.sample,
  report_date: Faker::Date.between(from: 3.months.ago, to: Date.current),
  reason: "UNUSUAL_PATTERN",
  notes: "Multiple rapid transactions in short timeframe - pattern flagged for review"
)
str_count += 1
puts "  - STR for unusual pattern"

# ============================================
# Staff Training Records
# ============================================
puts ""
puts "Creating training records..."

current_year = Date.current.year
previous_year = current_year - 1

# Training topics with weights (some more common than others)
TOPIC_WEIGHTS = {
  "AML_BASICS" => 3,
  "PEP_SCREENING" => 2,
  "STR_FILING" => 2,
  "RISK_ASSESSMENT" => 2,
  "SANCTIONS" => 1,
  "KYC_PROCEDURES" => 2,
  "OTHER" => 1
}.freeze

weighted_topics = TOPIC_WEIGHTS.flat_map { |topic, weight| [topic] * weight }

# Current year trainings (4-6 sessions)
current_year_trainings = rand(4..6)
current_year_trainings.times do |i|
  # First training of year is often a refresher, others vary
  training_type = if i == 0
                    "REFRESHER"
                  else
                    %w[REFRESHER SPECIALIZED].sample
                  end

  # More internal trainings than external
  provider = case rand(10)
             when 0..5 then "INTERNAL"
             when 6..7 then "EXTERNAL"
             when 8 then "AMSF"
             else "ONLINE"
             end

  training_date = Faker::Date.between(
    from: Date.new(current_year, 1, 1),
    to: [Date.new(current_year, 12, 31), Date.current].min
  )

  training = Training.create!(
    organization: organization,
    training_date: training_date,
    training_type: training_type,
    topic: weighted_topics.sample,
    provider: provider,
    staff_count: rand(3..8),
    duration_hours: [1.0, 1.5, 2.0, 2.5, 3.0, 4.0].sample,
    notes: rand < 0.3 ? Faker::Lorem.sentence : nil
  )

  puts "  - #{training.training_date.strftime('%b %Y')}: #{training.topic_label} (#{training.training_type_label})"
end

# Previous year trainings (3-5 sessions)
previous_year_trainings = rand(3..5)
previous_year_trainings.times do |i|
  training_type = if i == 0
                    "REFRESHER"
                  else
                    %w[REFRESHER SPECIALIZED INITIAL].sample
                  end

  provider = %w[INTERNAL INTERNAL INTERNAL EXTERNAL AMSF ONLINE].sample

  Training.create!(
    organization: organization,
    training_date: Faker::Date.between(
      from: Date.new(previous_year, 1, 1),
      to: Date.new(previous_year, 12, 31)
    ),
    training_type: training_type,
    topic: weighted_topics.sample,
    provider: provider,
    staff_count: rand(3..8),
    duration_hours: [1.0, 1.5, 2.0, 2.5, 3.0].sample
  )
end

puts "  Created #{Training.for_year(current_year).count} trainings for #{current_year}"
puts "  Created #{Training.for_year(previous_year).count} trainings for #{previous_year}"

# Summary
puts ""
puts "=" * 50
puts "Seed complete!"
puts "=" * 50
puts ""
puts "Created:"
puts "  Clients:"
puts "    - #{Client.natural_persons.count} natural persons"
puts "    - #{Client.legal_entities.count} legal entities"
puts "    - #{Client.trusts.count} trusts"
puts "    - #{BeneficialOwner.count} beneficial owners"
puts ""
puts "  Transactions:"
puts "    - #{Transaction.for_year(current_year).count} transactions in #{current_year}"
puts "    - #{Transaction.for_year(previous_year).count} transactions in #{previous_year}"
puts "    - Total value (#{current_year}): €#{Transaction.for_year(current_year).sum(:transaction_value).to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts ""
puts "  Transaction types (#{current_year}):"
puts "    - Purchases: #{Transaction.for_year(current_year).purchases.count}"
puts "    - Sales: #{Transaction.for_year(current_year).sales.count}"
puts "    - Rentals: #{Transaction.for_year(current_year).rentals.count}"
puts ""
puts "  STR Reports: #{StrReport.count}"
puts ""
puts "  Managed Properties:"
puts "    - Active: #{ManagedProperty.active.count}"
puts "    - Ended: #{ManagedProperty.ended.count}"
puts "    - Residential: #{ManagedProperty.residential.count}"
puts "    - Commercial: #{ManagedProperty.commercial.count}"
puts ""
puts "  Training Records:"
puts "    - #{current_year}: #{Training.for_year(current_year).count} sessions"
puts "    - #{previous_year}: #{Training.for_year(previous_year).count} sessions"
puts ""
puts "Risk distribution:"
puts "  - HIGH: #{Client.where(risk_level: 'HIGH').count}"
puts "  - MEDIUM: #{Client.where(risk_level: 'MEDIUM').count}"
puts "  - LOW: #{Client.where(risk_level: 'LOW').count}"
puts ""
puts "PEP clients: #{Client.peps.count}"
puts "Introduced clients: #{Client.introduced.count}"
puts "Third-party CDD clients: #{Client.with_third_party_cdd.count} (Local: #{Client.with_local_third_party_cdd.count}, Foreign: #{Client.with_foreign_third_party_cdd.count})"
puts ""
puts "Login with: #{test_email} / password123"
