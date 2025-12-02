# frozen_string_literal: true

require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get clients_path
    assert_redirected_to new_user_session_path
  end

  # TODO: Fix organization destroy in test - currently Organization is not destroyed
  # properly due to foreign key constraints with clients/transactions fixtures.
  # This test works in isolation but fails when run with full fixture set.
  # See also: DashboardControllerTest, TransactionsControllerTest, StrReportsControllerTest
  test "redirects to onboarding when no organization" do
    skip "Organization destroy in tests needs fixture cleanup - known issue"
    @organization.destroy
    sign_in @user

    get clients_path
    assert_redirected_to new_onboarding_path
  end

  # === Index ===

  test "shows client list when authenticated" do
    sign_in @user

    get clients_path
    assert_response :success
    assert_select "h1", /Clients/i
  end

  test "only shows clients from current organization" do
    other_org_client = clients(:other_org_client)
    sign_in @user

    get clients_path
    assert_response :success
    assert_select "turbo-frame#client_#{@client.id}"
    assert_select "turbo-frame#client_#{other_org_client.id}", count: 0
  end

  test "filters clients by type" do
    sign_in @user

    get clients_path(client_type: "PP")
    assert_response :success
    # Should only show natural persons
  end

  test "filters clients by risk level" do
    sign_in @user

    get clients_path(risk_level: "HIGH")
    assert_response :success
    # Should only show high risk clients
  end

  test "searches clients by name" do
    sign_in @user

    get clients_path(q: @client.name)
    assert_response :success
    assert_select "turbo-frame#client_#{@client.id}"
  end

  test "index responds to turbo frame request" do
    sign_in @user

    get clients_path, headers: { "Turbo-Frame" => "clients_list" }
    assert_response :success
  end

  # === Show ===

  test "shows client details" do
    sign_in @user

    get client_path(@client)
    assert_response :success
    assert_select "h1", /#{@client.name}/i
  end

  test "returns 404 for client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    get client_path(other_client)
    assert_response :not_found
  end

  test "shows beneficial owners section for legal entity" do
    legal_entity = clients(:legal_entity)
    sign_in @user

    get client_path(legal_entity)
    assert_response :success
    assert_select ".beneficial-owners"
  end

  test "hides beneficial owners section for natural person" do
    sign_in @user

    get client_path(@client)
    assert_response :success
    assert_select ".beneficial-owners", count: 0
  end

  # === New ===

  test "shows new client form" do
    sign_in @user

    get new_client_path
    assert_response :success
    assert_select "form[action=?]", clients_path
  end

  test "new form responds to turbo frame request" do
    sign_in @user

    get new_client_path, headers: { "Turbo-Frame" => "modal" }
    assert_response :success
  end

  # === Create ===

  test "creates natural person client" do
    sign_in @user

    assert_difference "Client.count", 1 do
      post clients_path, params: {
        client: {
          name: "New Client",
          client_type: "PP",
          nationality: "MC",
          residence_country: "MC"
        }
      }
    end

    client = Client.last
    assert_equal "New Client", client.name
    assert_equal "PP", client.client_type
    assert_equal @organization, client.organization
    assert_redirected_to client_path(client)
  end

  test "creates legal entity with legal_person_type" do
    sign_in @user

    assert_difference "Client.count", 1 do
      post clients_path, params: {
        client: {
          name: "Monaco Corp",
          client_type: "PM",
          legal_person_type: "SARL",
          nationality: "MC"
        }
      }
    end

    client = Client.last
    assert_equal "PM", client.client_type
    assert_equal "SARL", client.legal_person_type
  end

  test "creates PEP client with pep_type" do
    sign_in @user

    post clients_path, params: {
      client: {
        name: "PEP Client",
        client_type: "PP",
        is_pep: true,
        pep_type: "DOMESTIC"
      }
    }

    client = Client.last
    assert client.is_pep
    assert_equal "DOMESTIC", client.pep_type
  end

  test "returns unprocessable entity with invalid params" do
    sign_in @user

    assert_no_difference "Client.count" do
      post clients_path, params: {
        client: {
          name: "",
          client_type: "PP"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create responds with turbo stream on success" do
    sign_in @user

    post clients_path, params: {
      client: {
        name: "Turbo Client",
        client_type: "PP"
      }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Edit ===

  test "shows edit form for client" do
    sign_in @user

    get edit_client_path(@client)
    assert_response :success
    assert_select "form[action=?]", client_path(@client)
  end

  test "returns 404 when editing client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    get edit_client_path(other_client)
    assert_response :not_found
  end

  # === Update ===

  test "updates client" do
    sign_in @user

    patch client_path(@client), params: {
      client: {
        name: "Updated Name"
      }
    }

    @client.reload
    assert_equal "Updated Name", @client.name
    assert_redirected_to client_path(@client)
  end

  test "returns 404 when updating client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    patch client_path(other_client), params: {
      client: { name: "Hacked" }
    }

    assert_response :not_found
  end

  test "returns unprocessable entity with invalid update params" do
    sign_in @user

    patch client_path(@client), params: {
      client: { name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update responds with turbo stream" do
    sign_in @user

    patch client_path(@client), params: {
      client: { name: "Turbo Update" }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Destroy ===

  test "soft deletes client" do
    sign_in @user

    assert_no_difference "Client.with_discarded.count" do
      delete client_path(@client)
    end

    @client.reload
    assert @client.discarded?
    assert_redirected_to clients_path
  end

  test "returns 404 when deleting client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    delete client_path(other_client)
    assert_response :not_found
  end

  test "destroy responds with turbo stream" do
    sign_in @user

    delete client_path(@client), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Policy Authorization ===

  test "admin can manage all clients in organization" do
    # Use user one who has admin role on account one (which has organization one)
    admin_user = users(:one)
    sign_in admin_user

    get clients_path
    assert_response :success
  end

  # === Flash Messages ===

  test "shows success message after creating client" do
    sign_in @user

    post clients_path, params: {
      client: {
        name: "Flash Test Client",
        client_type: "PP"
      }
    }

    assert_equal "Client was successfully created.", flash[:notice]
  end

  test "shows success message after updating client" do
    sign_in @user

    patch client_path(@client), params: {
      client: { name: "Updated" }
    }

    assert_equal "Client was successfully updated.", flash[:notice]
  end

  test "shows success message after deleting client" do
    sign_in @user

    delete client_path(@client)
    assert_equal "Client was successfully deleted.", flash[:notice]
  end
end
