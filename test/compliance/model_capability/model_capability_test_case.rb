# frozen_string_literal: true

require "test_helper"

# Base class for model capability tests.
# These tests verify that our CRM models have the fields/methods
# needed to answer each AMSF taxonomy question.
#
# Unlike XBRL output tests, these test MODEL CAPABILITY, not XML generation.
#
# Run all capability tests:
#   bin/rails test test/compliance/model_capability/
#
class ModelCapabilityTestCase < ActiveSupport::TestCase
  # Helper to check if a model has a column
  def assert_model_has_column(model_class, column_name, message = nil)
    message ||= "#{model_class.name} should have column '#{column_name}'"
    assert model_class.column_names.include?(column_name.to_s), message
  end

  # Helper to check if a model responds to a method
  def assert_model_responds_to(model_class, method_name, message = nil)
    message ||= "#{model_class.name} should respond to '#{method_name}'"
    assert model_class.new.respond_to?(method_name), message
  end

  # Helper to check if a model has a scope
  def assert_model_has_scope(model_class, scope_name, message = nil)
    message ||= "#{model_class.name} should have scope '#{scope_name}'"
    assert model_class.respond_to?(scope_name), message
  end

  # Helper to check if a model has an association
  def assert_model_has_association(model_class, association_name, message = nil)
    message ||= "#{model_class.name} should have association '#{association_name}'"
    reflection = model_class.reflect_on_association(association_name)
    assert reflection.present?, message
  end

  # Helper for taxonomy element requirements
  # Returns a hash describing what's needed for an element
  def element_requirement(element_code, description, requirements)
    {
      element: element_code,
      description: description,
      requirements: requirements
    }
  end

  # Check if we can compute a value for an element
  # This is used for capability assertions
  def assert_can_compute(element_code, &block)
    result = yield
    assert_not_nil result, "Should be able to compute value for #{element_code}"
  rescue NoMethodError, NameError => e
    flunk "Cannot compute #{element_code}: #{e.message}"
  end
end
