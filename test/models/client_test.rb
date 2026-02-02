# frozen_string_literal: true

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid client with required attributes" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON"
    )
    assert client.valid?
  end

  test "requires name" do
    client = Client.new(
      organization: @organization,
      client_type: "NATURAL_PERSON"
    )
    assert_not client.valid?
    assert_includes client.errors[:name], "can't be blank"
  end

  test "requires client_type" do
    client = Client.new(
      organization: @organization,
      name: "John Doe"
    )
    assert_not client.valid?
    assert_includes client.errors[:client_type], "can't be blank"
  end

  test "requires organization" do
    client = Client.new(
      name: "John Doe",
      client_type: "NATURAL_PERSON"
    )
    assert_not client.valid?
    assert_includes client.errors[:organization], "must exist"
  end

  test "client_type must be valid" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:client_type], "is not included in the list"
  end

  test "accepts all valid client_types" do
    %w[NATURAL_PERSON LEGAL_ENTITY TRUST].each do |type|
      client = Client.new(
        organization: @organization,
        name: "Test Client",
        client_type: type
      )
      # LEGAL_ENTITY requires legal_person_type
      client.legal_person_type = "SCI" if type == "LEGAL_ENTITY"
      # TRUST requires trustee fields
      if type == "TRUST"
        client.trustee_name = "Test Trustee"
        client.trustee_nationality = "MC"
        client.trustee_country = "MC"
      end
      assert client.valid?, "Expected client_type '#{type}' to be valid"
    end
  end

  # === Conditional Validations ===

  test "requires legal_person_type for PM clients" do
    client = Client.new(
      organization: @organization,
      name: "Monaco Corp",
      client_type: "LEGAL_ENTITY"
    )
    assert_not client.valid?
    assert_includes client.errors[:legal_person_type], "can't be blank"
  end

  test "legal_person_type not required for PP clients" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON"
    )
    assert client.valid?
  end

  test "legal_person_type must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "Monaco Corp",
      client_type: "LEGAL_ENTITY",
      legal_person_type: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:legal_person_type], "is not included in the list"
  end

  test "accepts all valid legal_person_types" do
    %w[SCI SARL SAM SNC SA OTHER].each do |type|
      client = Client.new(
        organization: @organization,
        name: "Test Corp",
        client_type: "LEGAL_ENTITY",
        legal_person_type: type
      )
      assert client.valid?, "Expected legal_person_type '#{type}' to be valid"
    end
  end

  test "requires pep_type when is_pep is true" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      is_pep: true
    )
    assert_not client.valid?
    assert_includes client.errors[:pep_type], "can't be blank"
  end

  test "pep_type not required when is_pep is false" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      is_pep: false
    )
    assert client.valid?
  end

  test "pep_type must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      is_pep: true,
      pep_type: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:pep_type], "is not included in the list"
  end

  test "accepts all valid pep_types" do
    %w[DOMESTIC FOREIGN INTL_ORG].each do |type|
      client = Client.new(
        organization: @organization,
        name: "PEP Client",
        client_type: "NATURAL_PERSON",
        is_pep: true,
        pep_type: type
      )
      assert client.valid?, "Expected pep_type '#{type}' to be valid"
    end
  end

  test "requires vasp_type when is_vasp is true" do
    client = Client.new(
      organization: @organization,
      name: "Crypto Exchange",
      client_type: "LEGAL_ENTITY",
      legal_person_type: "SARL",
      is_vasp: true
    )
    assert_not client.valid?
    assert_includes client.errors[:vasp_type], "can't be blank"
  end

  test "vasp_type not required when is_vasp is false" do
    client = Client.new(
      organization: @organization,
      name: "Regular Corp",
      client_type: "LEGAL_ENTITY",
      legal_person_type: "SARL",
      is_vasp: false
    )
    assert client.valid?
  end

  test "accepts all valid vasp_types" do
    %w[CUSTODIAN EXCHANGE ICO OTHER].each do |type|
      client = Client.new(
        organization: @organization,
        name: "VASP Client",
        client_type: "LEGAL_ENTITY",
        legal_person_type: "SARL",
        is_vasp: true,
        vasp_type: type
      )
      assert client.valid?, "Expected vasp_type '#{type}' to be valid"
    end
  end

  # === Optional Field Validations ===

  test "risk_level must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      risk_level: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:risk_level], "is not included in the list"
  end

  test "accepts all valid risk_levels" do
    %w[LOW MEDIUM HIGH].each do |level|
      client = Client.new(
        organization: @organization,
        name: "Test Client",
        client_type: "NATURAL_PERSON",
        risk_level: level
      )
      assert client.valid?, "Expected risk_level '#{level}' to be valid"
    end
  end

  test "rejection_reason must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "Rejected Client",
      client_type: "NATURAL_PERSON",
      rejection_reason: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:rejection_reason], "is not included in the list"
  end

  test "accepts all valid rejection_reasons" do
    %w[AML_CFT OTHER].each do |reason|
      client = Client.new(
        organization: @organization,
        name: "Rejected Client",
        client_type: "NATURAL_PERSON",
        rejection_reason: reason
      )
      assert client.valid?, "Expected rejection_reason '#{reason}' to be valid"
    end
  end

  test "residence_status must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      residence_status: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:residence_status], "is not included in the list"
  end

  test "accepts all valid residence_statuses" do
    %w[RESIDENT NON_RESIDENT].each do |status|
      client = Client.new(
        organization: @organization,
        name: "Test Client",
        client_type: "NATURAL_PERSON",
        residence_status: status
      )
      assert client.valid?, "Expected residence_status '#{status}' to be valid"
    end
  end

  test "residence_status can be blank" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      residence_status: nil
    )
    assert client.valid?
  end

  test "country_code must be ISO 3166-1 alpha-2 format when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      country_code: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:country_code], "must be ISO 3166-1 alpha-2 format"
  end

  test "accepts valid ISO country codes" do
    %w[FR MC US GB DE].each do |code|
      client = Client.new(
        organization: @organization,
        name: "Test Client",
        client_type: "NATURAL_PERSON",
        country_code: code
      )
      assert client.valid?, "Expected country_code '#{code}' to be valid"
    end
  end

  test "country_code can be blank" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      country_code: nil
    )
    assert client.valid?
  end

  # === Scopes ===

  test "natural_persons scope returns only PP clients" do
    pp_client = clients(:natural_person)
    pm_client = clients(:legal_entity)

    natural_persons = Client.natural_persons
    assert_includes natural_persons, pp_client
    assert_not_includes natural_persons, pm_client
  end

  test "legal_entities scope returns only PM clients" do
    pp_client = clients(:natural_person)
    pm_client = clients(:legal_entity)

    legal_entities = Client.legal_entities
    assert_includes legal_entities, pm_client
    assert_not_includes legal_entities, pp_client
  end

  test "trusts scope returns only TRUST clients" do
    trust_client = clients(:trust)
    pp_client = clients(:natural_person)

    trusts = Client.trusts
    assert_includes trusts, trust_client
    assert_not_includes trusts, pp_client
  end

  test "peps scope returns only PEP clients" do
    pep_client = clients(:pep_client)
    regular_client = clients(:natural_person)

    peps = Client.peps
    assert_includes peps, pep_client
    assert_not_includes peps, regular_client
  end

  test "high_risk scope returns only HIGH risk clients" do
    high_risk_client = clients(:high_risk_client)
    regular_client = clients(:natural_person)

    high_risk = Client.high_risk
    assert_includes high_risk, high_risk_client
    assert_not_includes high_risk, regular_client
  end

  test "active scope excludes clients with relationship_ended_at" do
    active_client = clients(:natural_person)
    ended_client = clients(:ended_relationship)

    active = Client.active
    assert_includes active, active_client
    assert_not_includes active, ended_client
  end

  # === Soft Delete (Discard) ===

  test "soft deletes client with discard" do
    client = clients(:natural_person)
    assert_nil client.deleted_at

    client.discard
    assert_not_nil client.deleted_at
    assert client.discarded?
  end

  test "kept scope excludes discarded clients" do
    client = clients(:natural_person)
    client.discard

    assert_not_includes Client.kept, client
  end

  test "with_discarded scope includes discarded clients" do
    client = clients(:natural_person)
    client.discard

    assert_includes Client.with_discarded, client
  end

  test "undiscard restores soft-deleted client" do
    client = clients(:natural_person)
    client.discard
    assert client.discarded?

    client.undiscard
    assert_not client.discarded?
    assert_nil client.deleted_at
  end

  # === Associations ===

  test "belongs to organization" do
    client = clients(:natural_person)
    assert_equal @organization, client.organization
  end

  test "has many beneficial_owners" do
    client = clients(:legal_entity)
    assert_respond_to client, :beneficial_owners
  end

  test "destroys beneficial_owners when destroyed" do
    client = clients(:legal_entity_with_owners)
    beneficial_owner_count = client.beneficial_owners.count
    assert beneficial_owner_count > 0

    assert_difference "BeneficialOwner.count", -beneficial_owner_count do
      client.destroy
    end
  end

  # === Organization Scoping ===

  test "for_organization scope filters by organization" do
    org_one_client = clients(:natural_person)
    org_two_client = clients(:other_org_client)

    org_one_clients = Client.for_organization(@organization)
    assert_includes org_one_clients, org_one_client
    assert_not_includes org_one_clients, org_two_client
  end

  # === Auditable ===

  test "includes Auditable concern" do
    assert Client.include?(Auditable)
  end

  test "creates audit log on create" do
    assert_difference "AuditLog.count", 1 do
      Client.create!(
        organization: @organization,
        name: "New Client",
        client_type: "NATURAL_PERSON"
      )
    end

    audit_log = AuditLog.last
    assert_equal "create", audit_log.action
    assert_equal "Client", audit_log.auditable_type
  end

  test "creates audit log on update" do
    client = clients(:natural_person)

    assert_difference "AuditLog.count", 1 do
      client.update!(name: "Updated Name")
    end

    audit_log = AuditLog.last
    assert_equal "update", audit_log.action
    assert_includes audit_log.metadata["changed_fields"], "name"
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert Client.include?(AmsfConstants)
  end

  # === Due Diligence Fields (AMSF Data Capture) ===

  test "due_diligence_level must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      due_diligence_level: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:due_diligence_level], "is not included in the list"
  end

  test "accepts all valid due_diligence_levels" do
    %w[STANDARD SIMPLIFIED REINFORCED].each do |level|
      attrs = {
        organization: @organization,
        name: "Test Client",
        client_type: "NATURAL_PERSON",
        due_diligence_level: level
      }
      # SIMPLIFIED requires a reason
      attrs[:simplified_dd_reason] = "Low-risk domestic client" if level == "SIMPLIFIED"

      client = Client.new(attrs)
      assert client.valid?, "Expected due_diligence_level '#{level}' to be valid"
    end
  end

  test "due_diligence_level can be blank" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      due_diligence_level: nil
    )
    assert client.valid?
  end

  test "requires simplified_dd_reason when due_diligence_level is SIMPLIFIED" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      due_diligence_level: "SIMPLIFIED"
    )
    assert_not client.valid?
    assert_includes client.errors[:simplified_dd_reason], "can't be blank"
  end

  test "simplified_dd_reason not required when due_diligence_level is not SIMPLIFIED" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      due_diligence_level: "STANDARD"
    )
    assert client.valid?
  end

  test "relationship_end_reason must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      relationship_end_reason: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:relationship_end_reason], "is not included in the list"
  end

  test "accepts all valid relationship_end_reasons" do
    %w[CLIENT_REQUEST AML_CONCERN INACTIVITY BUSINESS_DECISION OTHER].each do |reason|
      client = Client.new(
        organization: @organization,
        name: "Test Client",
        client_type: "NATURAL_PERSON",
        relationship_end_reason: reason
      )
      assert client.valid?, "Expected relationship_end_reason '#{reason}' to be valid"
    end
  end

  test "relationship_end_reason can be blank" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      relationship_end_reason: nil
    )
    assert client.valid?
  end

  test "professional_category must be valid when present" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      professional_category: "INVALID"
    )
    assert_not client.valid?
    assert_includes client.errors[:professional_category], "is not included in the list"
  end

  test "accepts all valid professional_categories" do
    %w[LEGAL ACCOUNTANT NOTARY REAL_ESTATE FINANCIAL OTHER NONE].each do |category|
      client = Client.new(
        organization: @organization,
        name: "Test Client",
        client_type: "NATURAL_PERSON",
        professional_category: category
      )
      assert client.valid?, "Expected professional_category '#{category}' to be valid"
    end
  end

  test "professional_category can be blank" do
    client = Client.new(
      organization: @organization,
      name: "John Doe",
      client_type: "NATURAL_PERSON",
      professional_category: nil
    )
    assert client.valid?
  end

  test "source_of_funds_verified defaults to false" do
    client = Client.new
    assert_equal false, client.source_of_funds_verified
  end

  test "source_of_wealth_verified defaults to false" do
    client = Client.new
    assert_equal false, client.source_of_wealth_verified
  end
end
