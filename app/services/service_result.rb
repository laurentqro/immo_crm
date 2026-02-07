# frozen_string_literal: true

# Lightweight result object for service operations.
# Avoids exceptions for expected failure paths (validation errors, business rule violations).
#
# Usage:
#   result = ServiceResult.success(client)
#   result.success?  # => true
#   result.record     # => #<Client ...>
#
#   result = ServiceResult.failure(errors: ["Name can't be blank"])
#   result.failure?  # => true
#   result.errors    # => ["Name can't be blank"]
#
class ServiceResult
  attr_reader :record, :errors

  def initialize(success:, record: nil, errors: [])
    @success = success
    @record = record
    @errors = Array(errors)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(record = nil)
    new(success: true, record: record)
  end

  def self.failure(record: nil, errors: [])
    new(success: false, record: record, errors: Array(errors))
  end

  # Build a failure result from an ActiveRecord model's errors
  def self.from_record(record)
    if record.errors.any?
      failure(record: record, errors: record.errors.full_messages)
    else
      success(record)
    end
  end
end
