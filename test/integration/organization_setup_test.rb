# frozen_string_literal: true

require "test_helper"

class OrganizationSetupTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
  end

  test "onboarding creates organization linked to current account" do
    # Remove existing organization
    organizations(:one).destroy

    sign_in @user

    # POST to create organization via onboarding
    post onboarding_index_path, params: {
      organization: {
        name: "Integration Test Agency",
        rci_number: "INTTEST123",
        country: "MC"
      },
      settings: {
        total_employees: "4",
        compliance_officers: "1"
      }
    }

    # Should create organization
    organization = @account.reload.organization
    assert_not_nil organization
    assert_equal "Integration Test Agency", organization.name
    assert_equal "INTTEST123", organization.rci_number
    assert_equal "MC", organization.country
  end

  test "onboarding entity_info step validates required fields" do
    organizations(:one).destroy

    sign_in @user

    # POST without required fields
    post entity_info_onboarding_index_path, params: {
      organization: {
        name: "",
        rci_number: ""
      }
    }

    assert_response :unprocessable_entity
  end

  test "onboarding entity_info step saves and advances to policies" do
    organizations(:one).destroy

    sign_in @user

    post entity_info_onboarding_index_path, params: {
      organization: {
        name: "Step Test Agency",
        rci_number: "STEP123",
        country: "MC"
      },
      settings: {
        total_employees: "3",
        compliance_officers: "1"
      }
    }

    # Should redirect to policies step
    assert_redirected_to policies_onboarding_index_path
  end

  test "onboarding policies step completes setup via two step flow" do
    organizations(:one).destroy

    sign_in @user

    # Complete entity_info step - stores data in session, redirects to policies
    post entity_info_onboarding_index_path, params: {
      organization: {
        name: "Complete Test Agency",
        rci_number: "COMPLETE123",
        country: "MC"
      },
      settings: {
        total_employees: "5",
        compliance_officers: "1"
      }
    }

    assert_redirected_to policies_onboarding_index_path

    # Complete policies step - creates organization from session
    post policies_onboarding_index_path, params: {
      settings: {
        edd_for_peps: "true",
        edd_for_high_risk_countries: "true",
        written_aml_policy: "true"
      }
    }

    # Should redirect to dashboard
    assert_redirected_to dashboard_path

    # Verify organization was created
    organization = @account.reload.organization
    assert_not_nil organization
    assert_equal "Complete Test Agency", organization.name
  end

  test "onboarding redirects to dashboard if organization exists" do
    # Keep existing organization
    assert @account.organization.present?

    sign_in @user

    get new_onboarding_path
    assert_redirected_to dashboard_path
  end

  test "organization is scoped to account" do
    # Remove existing organization
    organizations(:one).destroy

    sign_in @user

    # Create organization via onboarding
    post onboarding_index_path, params: {
      organization: {
        name: "Scoped Test Agency",
        rci_number: "SCOPED123",
        country: "MC"
      },
      settings: {
        total_employees: "2",
        compliance_officers: "1"
      }
    }

    organization = Organization.find_by(rci_number: "SCOPED123")
    assert_equal @account.id, organization.account_id
  end

  test "audit log records organization creation" do
    organizations(:one).destroy
    # Note: Current.user is set automatically by SetCurrentRequestDetails
    # during the HTTP request - no need for set_current_context in integration tests
    sign_in @user

    assert_difference "AuditLog.count" do
      post onboarding_index_path, params: {
        organization: {
          name: "Audit Test Agency",
          rci_number: "AUDIT123",
          country: "MC"
        },
        settings: {
          total_employees: "3",
          compliance_officers: "1"
        }
      }
    end

    audit_log = AuditLog.last
    assert_equal "create", audit_log.action
    assert_equal "Organization", audit_log.auditable_type
  end
end
