# frozen_string_literal: true

require "test_helper"

class TurboHelperTest < ActionView::TestCase
  include TurboHelper

  test "new_frame_id generates correct ID for model class" do
    assert_equal "new_organization", new_frame_id(Organization)
    assert_equal "new_audit_log", new_frame_id(AuditLog)
  end

  test "edit_frame_id generates correct ID for record" do
    organization = organizations(:one)
    expected = "edit_organization_#{organization.id}"
    assert_equal expected, edit_frame_id(organization)
  end

  test "list_frame_id generates correct ID for model class" do
    assert_equal "organizations_list", list_frame_id(Organization)
    assert_equal "audit_logs_list", list_frame_id(AuditLog)
  end

  test "section_frame_id generates correct ID for record and section" do
    organization = organizations(:one)
    expected = "organization_#{organization.id}_settings"
    assert_equal expected, section_frame_id(organization, :settings)
  end

  test "modal_frame_id generates correct ID for modal name" do
    assert_equal "modal_confirm_delete", modal_frame_id(:confirm_delete)
    assert_equal "modal_add_client", modal_frame_id(:add_client)
  end

  test "wizard_step_frame_id generates correct ID for wizard and step" do
    assert_equal "submission_step_1", wizard_step_frame_id(:submission, 1)
    assert_equal "onboarding_step_3", wizard_step_frame_id(:onboarding, 3)
  end

  test "frame IDs are safe for HTML attributes" do
    # Verify IDs don't contain spaces or special characters
    assert_match(/\A[a-z0-9_]+\z/, new_frame_id(Organization))
    assert_match(/\A[a-z0-9_]+\z/, list_frame_id(Organization))
    assert_match(/\A[a-z0-9_]+\z/, modal_frame_id(:test))
    assert_match(/\A[a-z0-9_]+\z/, wizard_step_frame_id(:test, 1))
  end
end
