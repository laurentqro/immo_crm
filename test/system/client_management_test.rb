# frozen_string_literal: true

require "application_system_test_case"

class ClientManagementTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @legal_entity = clients(:legal_entity)
  end

  # === Client List ===

  test "user can view client list" do
    login_as @user, scope: :user

    visit clients_path

    assert_text "Clients"
    assert_text @client.name
  end

  test "client list shows type indicators" do
    login_as @user, scope: :user

    visit clients_path

    # Should show client type badges
    assert_selector "[data-client-type='NATURAL_PERSON']"
  end

  test "user can filter clients by type" do
    login_as @user, scope: :user

    visit clients_path

    # Select PP filter
    select "Natural Person", from: "client_type"

    # Should only show natural persons
    assert_text @client.name
  end

  test "user can search clients by name" do
    login_as @user, scope: :user

    visit clients_path

    fill_in "Search", with: @client.name
    click_button "Search"

    assert_text @client.name
  end

  # === Create Client - Natural Person ===

  test "user can create a natural person client" do
    login_as @user, scope: :user

    visit clients_path
    click_link "Add Client"

    assert_text "New Client"

    fill_in "Name", with: "Jean Dupont"
    select "Natural Person", from: "Client type"
    select "France", from: "Nationality"
    select "Monaco", from: "Residence country"

    click_button "Create Client"

    assert_text "Client was successfully created"
    assert_text "Jean Dupont"
  end

  test "user can create PEP client with type" do
    login_as @user, scope: :user

    visit new_client_path

    fill_in "Name", with: "PEP Client"
    select "Natural Person", from: "Client type"
    check "Politically Exposed Person"

    # PEP type field should appear
    select "Domestic", from: "PEP type"

    click_button "Create Client"

    assert_text "Client was successfully created"
    assert_text "PEP Client"
  end

  # === Create Client - Legal Entity ===

  test "user can create a legal entity client" do
    login_as @user, scope: :user

    visit new_client_path

    fill_in "Name", with: "Monaco Corp SARL"
    select "Legal Entity", from: "Client type"

    # Legal person type field should appear
    select "SARL", from: "Legal person type"

    click_button "Create Client"

    assert_text "Client was successfully created"
    assert_text "Monaco Corp SARL"
  end

  test "form shows conditional fields based on client type" do
    login_as @user, scope: :user

    visit new_client_path

    # Initially, legal_person_type should be hidden for PP
    select "Natural Person", from: "Client type"
    assert_no_selector "#client_legal_person_type:not([hidden])"

    # When PM is selected, legal_person_type should appear
    select "Legal Entity", from: "Client type"
    assert_selector "#client_legal_person_type"
  end

  # === View Client Details ===

  test "user can view client details" do
    login_as @user, scope: :user

    visit client_path(@client)

    assert_text @client.name
    assert_text "Client Details"
  end

  test "legal entity shows beneficial owners section" do
    login_as @user, scope: :user

    visit client_path(@legal_entity)

    assert_text @legal_entity.name
    assert_text "Beneficial Owners"
  end

  test "natural person does not show beneficial owners section" do
    login_as @user, scope: :user

    visit client_path(@client)

    assert_text @client.name
    assert_no_text "Beneficial Owners"
  end

  # === Edit Client ===

  test "user can edit client" do
    login_as @user, scope: :user

    visit client_path(@client)
    click_link "Edit"

    fill_in "Name", with: "Updated Client Name"
    click_button "Update Client"

    assert_text "Client was successfully updated"
    assert_text "Updated Client Name"
  end

  test "edit preserves client type" do
    login_as @user, scope: :user

    visit edit_client_path(@client)

    # Client type should be pre-selected
    assert_select "Client type", selected: "Natural Person"

    click_button "Update Client"

    @client.reload
    assert_equal "NATURAL_PERSON", @client.client_type
  end

  # === Delete Client ===

  test "user can delete client" do
    login_as @user, scope: :user

    visit client_path(@client)

    accept_confirm do
      click_button "Delete Client"
    end

    assert_text "Client was successfully deleted"
    assert_current_path clients_path
  end

  # === Beneficial Owners ===

  test "user can add beneficial owner to legal entity" do
    login_as @user, scope: :user

    visit client_path(@legal_entity)

    click_link "Add Beneficial Owner"

    fill_in "Name", with: "Owner Jean"
    fill_in "Ownership percentage", with: "25"
    select "Direct", from: "Control type"

    click_button "Add Beneficial Owner"

    assert_text "Beneficial owner was successfully added"
    assert_text "Owner Jean"
    assert_text "25%"
  end

  test "user can edit beneficial owner" do
    owner = beneficial_owners(:owner_one)
    login_as @user, scope: :user

    visit client_path(@legal_entity)

    within "#beneficial_owner_#{owner.id}" do
      click_link "Edit"
    end

    fill_in "Name", with: "Updated Owner Name"
    click_button "Update"

    assert_text "Beneficial owner was successfully updated"
    assert_text "Updated Owner Name"
  end

  test "user can remove beneficial owner" do
    owner = beneficial_owners(:owner_one)
    login_as @user, scope: :user

    visit client_path(@legal_entity)

    within "#beneficial_owner_#{owner.id}" do
      accept_confirm do
        click_button "Remove"
      end
    end

    assert_text "Beneficial owner was successfully removed"
    assert_no_text owner.name
  end

  test "PEP beneficial owner requires pep_type" do
    login_as @user, scope: :user

    visit client_path(@legal_entity)
    click_link "Add Beneficial Owner"

    fill_in "Name", with: "PEP Owner"
    check "Politically Exposed Person"

    # PEP type field should appear
    select "Foreign", from: "PEP type"

    click_button "Add Beneficial Owner"

    assert_text "Beneficial owner was successfully added"
  end

  # === Turbo Frame Navigation ===

  test "client list updates via turbo frame" do
    login_as @user, scope: :user

    visit clients_path

    # The page should have turbo frames for client list
    assert_selector "turbo-frame#clients_list"
  end

  test "new client form appears in turbo frame" do
    login_as @user, scope: :user

    visit clients_path
    click_link "Add Client"

    # Form should appear without full page reload
    assert_selector "turbo-frame#modal form"
  end

  test "client update via turbo frame" do
    login_as @user, scope: :user

    visit clients_path

    within "#client_#{@client.id}" do
      click_link "Edit"
    end

    # Edit form should appear inline
    fill_in "Name", with: "Turbo Updated"
    click_button "Update Client"

    # Should update without full page reload
    assert_text "Turbo Updated"
  end

  # === Risk Level Display ===

  test "high risk clients are visually highlighted" do
    high_risk = clients(:high_risk_client)
    login_as @user, scope: :user

    visit clients_path

    assert_selector "#client_#{high_risk.id}.high-risk"
  end

  test "PEP indicator is shown for PEP clients" do
    pep = clients(:pep_client)
    login_as @user, scope: :user

    visit clients_path

    within "#client_#{pep.id}" do
      assert_selector ".pep-badge"
    end
  end

  # === Validation Errors ===

  test "shows validation errors for invalid client" do
    login_as @user, scope: :user

    visit new_client_path

    # Submit without required fields (if JS is disabled, server validation kicks in)
    click_button "Create Client"

    # Should show validation error
    assert_text "can't be blank"
  end

  test "legal entity requires legal_person_type" do
    login_as @user, scope: :user

    visit new_client_path

    fill_in "Name", with: "Corp Without Type"
    select "Legal Entity", from: "Client type"
    # Intentionally don't select legal_person_type

    click_button "Create Client"

    assert_text "Legal person type can't be blank"
  end
end
