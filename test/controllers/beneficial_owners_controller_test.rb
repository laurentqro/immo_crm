# frozen_string_literal: true

require "test_helper"

class BeneficialOwnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @legal_entity = clients(:legal_entity)
    @beneficial_owner = beneficial_owners(:owner_one)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get client_beneficial_owners_path(@legal_entity)
    assert_redirected_to new_user_session_path
  end

  test "redirects to onboarding when no organization" do
    @organization.destroy
    sign_in @user

    get client_beneficial_owners_path(@legal_entity)
    assert_redirected_to new_onboarding_path
  end

  # === Index ===

  test "shows beneficial owners for client" do
    sign_in @user

    get client_beneficial_owners_path(@legal_entity)
    assert_response :success
  end

  test "returns 404 for client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    get client_beneficial_owners_path(other_client)
    assert_response :not_found
  end

  test "returns 404 for natural person client" do
    pp_client = clients(:natural_person)
    sign_in @user

    get client_beneficial_owners_path(pp_client)
    assert_response :not_found
  end

  test "index responds to turbo frame request" do
    sign_in @user

    get client_beneficial_owners_path(@legal_entity),
        headers: { "Turbo-Frame" => "beneficial_owners" }
    assert_response :success
  end

  # === New ===

  test "shows new beneficial owner form" do
    sign_in @user

    get new_client_beneficial_owner_path(@legal_entity)
    assert_response :success
    assert_select "form[action=?]", client_beneficial_owners_path(@legal_entity)
  end

  test "new responds to turbo frame for inline form" do
    sign_in @user

    get new_client_beneficial_owner_path(@legal_entity),
        headers: { "Turbo-Frame" => "new_beneficial_owner" }
    assert_response :success
  end

  # === Create ===

  test "creates beneficial owner" do
    sign_in @user

    assert_difference "BeneficialOwner.count", 1 do
      post client_beneficial_owners_path(@legal_entity), params: {
        beneficial_owner: {
          name: "Jean Dupont",
          nationality: "FR",
          residence_country: "MC",
          ownership_pct: 25.0,
          control_type: "DIRECT"
        }
      }
    end

    owner = BeneficialOwner.last
    assert_equal "Jean Dupont", owner.name
    assert_equal @legal_entity, owner.client
    assert_redirected_to client_path(@legal_entity)
  end

  test "creates PEP beneficial owner" do
    sign_in @user

    post client_beneficial_owners_path(@legal_entity), params: {
      beneficial_owner: {
        name: "PEP Owner",
        is_pep: true,
        pep_type: "FOREIGN"
      }
    }

    owner = BeneficialOwner.last
    assert owner.is_pep
    assert_equal "FOREIGN", owner.pep_type
  end

  test "returns unprocessable entity with invalid params" do
    sign_in @user

    assert_no_difference "BeneficialOwner.count" do
      post client_beneficial_owners_path(@legal_entity), params: {
        beneficial_owner: {
          name: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "returns 404 when creating for client from different organization" do
    other_client = clients(:other_org_legal_entity)
    sign_in @user

    post client_beneficial_owners_path(other_client), params: {
      beneficial_owner: { name: "Hacker" }
    }

    assert_response :not_found
  end

  test "create responds with turbo stream" do
    sign_in @user

    post client_beneficial_owners_path(@legal_entity), params: {
      beneficial_owner: {
        name: "Turbo Owner"
      }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Edit ===

  test "shows edit form" do
    sign_in @user

    get edit_beneficial_owner_path(@beneficial_owner)
    assert_response :success
    # With shallow routes, form posts to /beneficial_owners/:id
    assert_select "form[action=?]", beneficial_owner_path(@beneficial_owner)
  end

  test "returns 404 when editing owner from different organization" do
    other_owner = beneficial_owners(:other_org_owner)
    sign_in @user

    get edit_beneficial_owner_path(other_owner)
    assert_response :not_found
  end

  # === Update ===

  test "updates beneficial owner" do
    sign_in @user

    patch beneficial_owner_path(@beneficial_owner), params: {
      beneficial_owner: {
        name: "Updated Name",
        ownership_pct: 50.0
      }
    }

    @beneficial_owner.reload
    assert_equal "Updated Name", @beneficial_owner.name
    assert_equal 50.0, @beneficial_owner.ownership_pct
    assert_redirected_to client_path(@legal_entity)
  end

  test "returns 404 when updating owner from different organization" do
    other_owner = beneficial_owners(:other_org_owner)
    sign_in @user

    patch beneficial_owner_path(other_owner), params: {
      beneficial_owner: { name: "Hacked" }
    }

    assert_response :not_found
  end

  test "returns unprocessable entity with invalid update params" do
    sign_in @user

    patch beneficial_owner_path(@beneficial_owner), params: {
      beneficial_owner: { name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update responds with turbo stream" do
    sign_in @user

    patch beneficial_owner_path(@beneficial_owner), params: {
      beneficial_owner: { name: "Turbo Update" }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Destroy ===

  test "destroys beneficial owner" do
    sign_in @user

    assert_difference "BeneficialOwner.count", -1 do
      delete beneficial_owner_path(@beneficial_owner)
    end

    assert_redirected_to client_path(@legal_entity)
  end

  test "returns 404 when deleting owner from different organization" do
    other_owner = beneficial_owners(:other_org_owner)
    sign_in @user

    delete beneficial_owner_path(other_owner)
    assert_response :not_found
  end

  test "destroy responds with turbo stream" do
    sign_in @user

    delete beneficial_owner_path(@beneficial_owner),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Flash Messages ===

  test "shows success message after creating owner" do
    sign_in @user

    post client_beneficial_owners_path(@legal_entity), params: {
      beneficial_owner: { name: "Flash Test" }
    }

    assert_equal "Beneficial owner was successfully added.", flash[:notice]
  end

  test "shows success message after updating owner" do
    sign_in @user

    patch beneficial_owner_path(@beneficial_owner), params: {
      beneficial_owner: { name: "Updated" }
    }

    assert_equal "Beneficial owner was successfully updated.", flash[:notice]
  end

  test "shows success message after deleting owner" do
    sign_in @user

    delete beneficial_owner_path(@beneficial_owner)
    assert_equal "Beneficial owner was successfully removed.", flash[:notice]
  end
end
