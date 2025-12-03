# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# ValidationService sends XBRL content to an external validator service
# and returns validation results.
#
# The validator service is expected to be a separate microservice
# running at VALIDATOR_URL.
#
class ValidationService
  # Result object for validation responses
  # Provides method access to validation data (valid?, errors, warnings)
  Result = Struct.new(:valid, :errors, :warnings, keyword_init: true) do
    def valid?
      valid
    end
  end
  # Base URL for the validator service
  VALIDATOR_URL = ENV.fetch("XBRL_VALIDATOR_URL", "http://localhost:8000")

  # Timeout settings (seconds) - configurable via ENV for production tuning
  OPEN_TIMEOUT = ENV.fetch("XBRL_VALIDATOR_OPEN_TIMEOUT", 5).to_i
  READ_TIMEOUT = ENV.fetch("XBRL_VALIDATOR_READ_TIMEOUT", 30).to_i

  attr_reader :xbrl_content

  def initialize(xbrl_content)
    @xbrl_content = xbrl_content
  end

  # Validate the XBRL content against the external validator
  #
  # @param retries [Integer] Maximum number of retry attempts (default: 2 means up to 3 total attempts)
  # @return [Result] Validation result with valid?, errors, warnings
  def validate(retries: 2)
    attempts = 0

    begin
      attempts += 1
      perform_validation_request
    rescue ServiceUnavailableError => e
      if attempts <= retries
        sleep(0.1 * attempts) # Exponential backoff
        retry
      end
      error_result("Validation service unavailable: #{e.message}")
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
      if attempts <= retries
        sleep(0.1 * attempts)
        retry
      end
      error_result("Connection error: #{e.message}")
    rescue JSON::ParserError => e
      error_result("Invalid response from validator: #{e.message}")
    rescue StandardError => e
      error_result("Validation error: #{e.message}")
    end
  end

  # Check if the validation service is healthy
  #
  # @return [Boolean] true if service is responsive
  def self.healthy?
    uri = URI.parse("#{VALIDATOR_URL}/health")
    http = build_http(uri)

    response = http.get(uri.path)
    response.is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
  end

  private

  def perform_validation_request
    uri = URI.parse("#{VALIDATOR_URL}/validate")
    http = self.class.build_http(uri)

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = { xbrl_content: xbrl_content }.to_json

    response = http.request(request)

    handle_response(response)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      parse_success_response(response)
    when Net::HTTPUnprocessableEntity
      # RFC9110: 422 indicates the server understands the content but cannot process it
      # This is a validation failure, not a service error - return structured errors
      parse_unprocessable_response(response)
    when Net::HTTPServiceUnavailable
      raise ServiceUnavailableError, "Service returned 503"
    else
      error_result("Validator returned status #{response.code}")
    end
  end

  def parse_unprocessable_response(response)
    data = JSON.parse(response.body, symbolize_names: true)

    Result.new(
      valid: false,
      errors: normalize_errors(data[:errors] || [{ message: "Validation failed" }]),
      warnings: normalize_errors(data[:warnings] || [])
    )
  rescue JSON::ParserError
    error_result("Invalid XBRL content (422)")
  end

  def parse_success_response(response)
    data = JSON.parse(response.body, symbolize_names: true)

    Result.new(
      valid: data[:valid],
      errors: normalize_errors(data[:errors] || []),
      warnings: normalize_errors(data[:warnings] || [])
    )
  end

  def normalize_errors(errors)
    errors.map do |error|
      # Ensure consistent key format (symbols)
      {
        code: error[:code] || error["code"],
        message: error[:message] || error["message"],
        element: error[:element] || error["element"]
      }
    end
  end

  def error_result(message)
    Result.new(
      valid: false,
      errors: [{ code: "SERVICE_ERROR", message: message, element: nil }],
      warnings: []
    )
  end

  def self.build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http
  end

  # Custom error for service unavailability (enables retry logic)
  class ServiceUnavailableError < StandardError; end
end
