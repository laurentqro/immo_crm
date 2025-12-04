# frozen_string_literal: true

require "test_helper"

class ManagedPropertiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @managed_property = managed_properties(:active_residential)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get managed_properties_path
    assert_redirected_to new_user_session_path
  end

  # === Index ===

  test "shows managed properties list when authenticated" do
    sign_in @user

    get managed_properties_path
    assert_response :success
    assert_select "h1", /Managed Properties|Properties/i
  end

  test "only shows managed properties from current organization" do
    other_org_property = managed_properties(:other_org_property)
    sign_in @user

    get managed_properties_path
    assert_response :success
    # Should show org one property
    assert_match @managed_property.property_address, response.body
    # Should not show other org property
    assert_no_match(/#{other_org_property.property_address}/, response.body)
  end

  test "filters managed properties by property_type" do
    sign_in @user

    get managed_properties_path(property_type: "COMMERCIAL")
    assert_response :success
  end

  test "filters managed properties by active status" do
    sign_in @user

    get managed_properties_path(status: "active")
    assert_response :success
  end

  # === Show ===

  test "shows managed property details" do
    sign_in @user

    get managed_property_path(@managed_property)
    assert_response :success
    assert_match @managed_property.property_address, response.body
  end

  test "returns 404 for managed property from different organization" do
    other_property = managed_properties(:other_org_property)
    sign_in @user

    get managed_property_path(other_property)
    assert_response :not_found
  end

  # === New ===

  test "shows new managed property form" do
    sign_in @user

    get new_managed_property_path
    assert_response :success
    assert_select "form[action=?]", managed_properties_path
  end

  # === Create ===

  test "creates managed property with valid params" do
    sign_in @user

    assert_difference "ManagedProperty.count", 1 do
      post managed_properties_path, params: {
        managed_property: {
          client_id: @client.id,
          property_address: "New Property Address, Monaco",
          property_type: "RESIDENTIAL",
          management_start_date: Date.current,
          monthly_rent: 5000,
          management_fee_percent: 8.0,
          tenant_name: "New Tenant",
          tenant_type: "NATURAL_PERSON",
          tenant_country: "MC"
        }
      }
    end

    property = ManagedProperty.last
    assert_equal "New Property Address, Monaco", property.property_address
    assert_equal @organization, property.organization
    assert_redirected_to managed_property_path(property)
  end

  test "creates managed property with fixed fee" do
    sign_in @user

    post managed_properties_path, params: {
      managed_property: {
        client_id: @client.id,
        property_address: "Fixed Fee Property, Monaco",
        property_type: "COMMERCIAL",
        management_start_date: Date.current,
        monthly_rent: 10000,
        management_fee_fixed: 800,
        tenant_name: "Business Tenant",
        tenant_type: "LEGAL_ENTITY"
      }
    }

    property = ManagedProperty.last
    assert_equal 800, property.management_fee_fixed
  end

  test "returns unprocessable entity with invalid params" do
    sign_in @user

    assert_no_difference "ManagedProperty.count" do
      post managed_properties_path, params: {
        managed_property: {
          client_id: @client.id,
          property_address: "",  # required
          management_start_date: Date.current
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "requires fee structure" do
    sign_in @user

    assert_no_difference "ManagedProperty.count" do
      post managed_properties_path, params: {
        managed_property: {
          client_id: @client.id,
          property_address: "No Fee Property",
          management_start_date: Date.current
          # No fee specified
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Edit ===

  test "shows edit form for managed property" do
    sign_in @user

    get edit_managed_property_path(@managed_property)
    assert_response :success
    assert_select "form[action=?]", managed_property_path(@managed_property)
  end

  test "returns 404 when editing managed property from different organization" do
    other_property = managed_properties(:other_org_property)
    sign_in @user

    get edit_managed_property_path(other_property)
    assert_response :not_found
  end

  # === Update ===

  test "updates managed property" do
    sign_in @user

    patch managed_property_path(@managed_property), params: {
      managed_property: {
        monthly_rent: 6000
      }
    }

    @managed_property.reload
    assert_equal 6000, @managed_property.monthly_rent
    assert_redirected_to managed_property_path(@managed_property)
  end

  test "returns 404 when updating managed property from different organization" do
    other_property = managed_properties(:other_org_property)
    sign_in @user

    patch managed_property_path(other_property), params: {
      managed_property: {monthly_rent: 9999}
    }

    assert_response :not_found
  end

  # === Destroy ===

  test "destroys managed property" do
    sign_in @user

    assert_difference "ManagedProperty.count", -1 do
      delete managed_property_path(@managed_property)
    end

    assert_redirected_to managed_properties_path
  end

  test "returns 404 when deleting managed property from different organization" do
    other_property = managed_properties(:other_org_property)
    sign_in @user

    delete managed_property_path(other_property)
    assert_response :not_found
  end

  # === Flash Messages ===

  test "shows success message after creating managed property" do
    sign_in @user

    post managed_properties_path, params: {
      managed_property: {
        client_id: @client.id,
        property_address: "Flash Test Property",
        management_start_date: Date.current,
        management_fee_percent: 8.0
      }
    }

    assert_equal "Managed property was successfully created.", flash[:notice]
  end

  test "shows success message after updating managed property" do
    sign_in @user

    patch managed_property_path(@managed_property), params: {
      managed_property: {monthly_rent: 5500}
    }

    assert_equal "Managed property was successfully updated.", flash[:notice]
  end

  test "shows success message after deleting managed property" do
    sign_in @user

    delete managed_property_path(@managed_property)
    assert_equal "Managed property was successfully deleted.", flash[:notice]
  end
end
