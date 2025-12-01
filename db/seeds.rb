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

puts "Creating clients..."

# Create natural persons (15 clients)
15.times do |i|
  is_pep = i < 3 # First 3 are PEPs
  risk = case i
         when 0..2 then "HIGH"
         when 3..5 then "MEDIUM"
         else "LOW"
         end

  client = Client.create!(
    organization: organization,
    name: Faker::Name.name,
    client_type: "PP",
    nationality: NATIONALITIES.sample,
    residence_country: COUNTRIES.sample,
    risk_level: risk,
    is_pep: is_pep,
    pep_type: is_pep ? %w[DOMESTIC FOREIGN INTL_ORG].sample : nil,
    became_client_at: Faker::Date.between(from: 5.years.ago, to: Date.today),
    notes: i < 5 ? Faker::Lorem.paragraph(sentence_count: 2) : nil
  )

  puts "  - Created natural person: #{client.name} (#{client.risk_level} risk#{', PEP' if client.is_pep?})"
end

# Create legal entities (10 clients)
10.times do |i|
  is_pep = i < 2 # First 2 have PEP beneficial owners (we'll add them below)
  risk = case i
         when 0..1 then "HIGH"
         when 2..4 then "MEDIUM"
         else "LOW"
         end

  legal_type = %w[SCI SARL SAM SA].sample

  client = Client.create!(
    organization: organization,
    name: "#{Faker::Company.name} #{legal_type}",
    client_type: "PM",
    legal_person_type: legal_type,
    nationality: NATIONALITIES.sample,
    residence_country: COUNTRIES.sample,
    business_sector: BUSINESS_SECTORS.sample,
    risk_level: risk,
    is_pep: is_pep,
    pep_type: is_pep ? %w[DOMESTIC FOREIGN].sample : nil,
    became_client_at: Faker::Date.between(from: 5.years.ago, to: Date.today),
    notes: Faker::Lorem.paragraph(sentence_count: 2)
  )

  # Add 1-3 beneficial owners for each legal entity
  rand(1..3).times do
    is_owner_pep = client.is_pep? && BeneficialOwner.where(client: client).count == 0

    BeneficialOwner.create!(
      client: client,
      name: Faker::Name.name,
      nationality: NATIONALITIES.sample,
      residence_country: COUNTRIES.sample,
      ownership_pct: [25, 33, 50, 51, 75, 100].sample,
      control_type: %w[DIRECT INDIRECT REPRESENTATIVE].sample,
      is_pep: is_owner_pep,
      pep_type: is_owner_pep ? %w[DOMESTIC FOREIGN INTL_ORG].sample : nil
    )
  end

  owner_count = client.beneficial_owners.count
  puts "  - Created legal entity: #{client.name} (#{owner_count} beneficial owner#{'s' if owner_count > 1})"
end

# Create trusts (5 clients)
5.times do |i|
  risk = i < 2 ? "HIGH" : "MEDIUM"

  client = Client.create!(
    organization: organization,
    name: "#{Faker::Name.last_name} Family Trust",
    client_type: "TRUST",
    nationality: %w[CH GB JE GG].sample,
    residence_country: COUNTRIES.sample,
    risk_level: risk,
    became_client_at: Faker::Date.between(from: 5.years.ago, to: Date.today),
    notes: "Trust established for #{Faker::Company.bs}"
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
  client_type: "PP",
  nationality: "FR",
  residence_country: "FR",
  risk_level: "LOW",
  became_client_at: 3.years.ago,
  relationship_ended_at: 6.months.ago,
  notes: "Relationship ended - client relocated"
)
puts "  - Created ended relationship: #{ended_client.name}"

# Summary
puts ""
puts "=" * 50
puts "Seed complete!"
puts "=" * 50
puts ""
puts "Created:"
puts "  - #{Client.natural_persons.count} natural persons"
puts "  - #{Client.legal_entities.count} legal entities"
puts "  - #{Client.trusts.count} trusts"
puts "  - #{BeneficialOwner.count} beneficial owners"
puts ""
puts "Risk distribution:"
puts "  - HIGH: #{Client.where(risk_level: 'HIGH').count}"
puts "  - MEDIUM: #{Client.where(risk_level: 'MEDIUM').count}"
puts "  - LOW: #{Client.where(risk_level: 'LOW').count}"
puts ""
puts "PEP clients: #{Client.peps.count}"
puts ""
puts "Login with: #{test_email} / password123"
