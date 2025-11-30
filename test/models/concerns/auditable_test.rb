# frozen_string_literal: true

require "test_helper"

class AuditableTest < ActiveSupport::TestCase
  # Test that Auditable concern works correctly and documents the Discard inclusion order

  test "includes after_create and after_update callbacks" do
    # Create a test model class that uses Auditable
    test_class = Class.new(ApplicationRecord) do
      self.table_name = "organizations"  # Borrow the organizations table for testing

      include Auditable

      def self.name
        "TestAuditableModel"
      end

      # Override to avoid actual organization lookup
      def organization
        nil
      end

      def organization_id
        nil
      end
    end

    # Check that callbacks are registered
    create_callbacks = test_class._create_callbacks.map(&:filter)
    update_callbacks = test_class._update_callbacks.map(&:filter)

    assert_includes create_callbacks, :log_audit_create
    assert_includes update_callbacks, :log_audit_update
  end

  test "does not include after_discard when Discard is not included first" do
    # When Discard is NOT included before Auditable, after_discard should NOT be registered
    test_class = Class.new(ApplicationRecord) do
      self.table_name = "organizations"
      include Auditable  # No Discard::Model included

      def self.name
        "TestNoDiscardModel"
      end
    end

    # Verify after_discard is NOT in callbacks (because Discard wasn't included first)
    # Note: We can't check _discard_callbacks because the model doesn't have Discard
    assert_not test_class.respond_to?(:_discard_callbacks)
  end

  test "includes after_discard when Discard::Model is included BEFORE Auditable" do
    # When Discard IS included before Auditable, after_discard SHOULD be registered
    test_class = Class.new(ApplicationRecord) do
      self.table_name = "organizations"
      include Discard::Model  # Include BEFORE Auditable
      include Auditable

      def self.name
        "TestWithDiscardModel"
      end
    end

    # Verify the discard callbacks are registered
    assert test_class.respond_to?(:_discard_callbacks)
    discard_callbacks = test_class._discard_callbacks.map(&:filter)
    assert_includes discard_callbacks, :log_audit_delete
  end

  test "after_discard NOT registered when Discard::Model is included AFTER Auditable" do
    # This test documents the WRONG order and why it fails
    test_class = Class.new(ApplicationRecord) do
      self.table_name = "organizations"
      include Auditable
      include Discard::Model  # Include AFTER Auditable - WRONG ORDER

      def self.name
        "TestWrongOrderModel"
      end
    end

    # Discard callbacks exist, but log_audit_delete is NOT registered
    # because Auditable's included block already ran before Discard was included
    assert test_class.respond_to?(:_discard_callbacks)
    discard_callbacks = test_class._discard_callbacks.map(&:filter)
    assert_not_includes discard_callbacks, :log_audit_delete,
      "log_audit_delete should NOT be registered when Discard is included AFTER Auditable"
  end

  test "log_audit handles missing organization gracefully" do
    # Set up Current context
    Current.user = users(:one)
    Current.ip_address = "127.0.0.1"

    # Use audit_logs table since it has organization_id and allows nil
    test_class = Class.new(ApplicationRecord) do
      self.table_name = "audit_logs"
      include Auditable

      def self.name
        "TestNoOrgModel"
      end

      # Override to return nil org
      def organization
        nil
      end

      def organization_id
        nil
      end
    end

    record = test_class.new(action: "login")

    # Should not raise error even with nil organization
    # The audit logging will fail gracefully due to the rescue
    assert_nothing_raised { record.save! }
  ensure
    Current.reset
  end
end
