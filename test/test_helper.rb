ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "webmock/minitest"

# Uncomment to view full stack trace in tests
# Rails.backtrace_cleaner.remove_silencers!

if defined?(Sidekiq)
  require "sidekiq/testing"
  Sidekiq.logger.level = Logger::WARN
end

if defined?(SolidQueue)
  SolidQueue.logger.level = Logger::WARN
end

# Generate a random password so Chrome doesn't warn about passwords in data breaches
UNIQUE_PASSWORD = Devise.friendly_token

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def json_response
      JSON.decode(response.body)
    end
  end
end

# Organization-scoped test helpers for CRM multi-tenancy testing.
# These helpers ensure tests properly scope data to organizations.
#
# DESIGN DECISION: Global inclusion in ActiveSupport::TestCase
# - Included globally because multi-tenancy affects nearly all tests
# - Current context (Current.user, Current.ip_address) must be set for:
#   * Model tests using Auditable concern
#   * Policy tests requiring user context
#   * Integration tests verifying tenant isolation
# - teardown automatically clears context to prevent state leakage
# - Minor memory overhead is acceptable for test simplicity
module OrganizationTestHelper
  # Set up Current context for organization-scoped operations.
  # Use in model/service tests that depend on Current.user.
  #
  # Usage:
  #   setup do
  #     @organization = organizations(:one)
  #     @user = users(:one)
  #     set_current_context(user: @user, organization: @organization)
  #   end
  def set_current_context(user: nil, organization: nil, ip_address: "127.0.0.1", user_agent: "TestAgent/1.0")
    Current.user = user
    Current.ip_address = ip_address
    Current.user_agent = user_agent
    @_current_organization = organization
  end

  # Clear Current context after tests to prevent state leakage.
  # Automatically called by teardown if using OrganizationTestHelper.
  def clear_current_context
    Current.reset
    @_current_organization = nil
  end

  # Get the current organization set by set_current_context.
  def current_organization
    @_current_organization
  end

  # Assert a record belongs to the expected organization.
  # Useful for verifying tenant isolation.
  #
  # Usage:
  #   assert_organization_scoped(@client, @organization)
  def assert_organization_scoped(record, organization, message = nil)
    assert_equal organization, record.organization,
      message || "Expected #{record.class.name} to belong to #{organization.name}"
  end

  # Assert a collection only contains records from the expected organization.
  #
  # Usage:
  #   assert_all_organization_scoped(Client.all, @organization)
  def assert_all_organization_scoped(collection, organization, message = nil)
    collection.each do |record|
      assert_equal organization, record.organization,
        message || "Expected all records to belong to #{organization.name}, but found one belonging to #{record.organization&.name}"
    end
  end

  # Assert a record does NOT belong to a given organization.
  # Useful for cross-tenant isolation tests.
  def assert_not_organization_scoped(record, organization, message = nil)
    assert_not_equal organization, record.organization,
      message || "Expected #{record.class.name} to NOT belong to #{organization.name}"
  end
end

# Include organization helpers in all test cases
module ActiveSupport
  class TestCase
    include OrganizationTestHelper

    teardown do
      clear_current_context if respond_to?(:clear_current_context)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

    def switch_account(account)
      patch "/accounts/#{account.id}/switch"
    end
  end
end

WebMock.disable_net_connect!({
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",
    "rails-app",
    "selenium"
  ]
})
