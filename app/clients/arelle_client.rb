# frozen_string_literal: true

# HTTP client for the Arelle XBRL validation API.
#
# Validates XBRL documents against the taxonomy schema and XULE rules.
# Returns structured validation results with errors, warnings, and info messages.
#
# Usage:
#   client = ArelleClient.new
#   result = client.validate(xml_content)
#   result.valid?        # => true/false
#   result.errors        # => [{severity: "error", message: "..."}]
#   result.error_messages # => ["error message 1", "error message 2"]
#
class ArelleClient < ApplicationClient
  BASE_URI = ENV.fetch("ARELLE_API_URL", "http://localhost:8000")

  ValidationResult = Data.define(:valid, :summary, :messages) do
    def valid?
      valid
    end

    def errors
      messages.select { |m| m[:severity] == "error" }
    end

    def warnings
      messages.select { |m| m[:severity] == "warning" }
    end

    def error_messages
      errors.map { |m| m[:message] }
    end
  end

  class ConnectionError < Error; end

  # Connection errors to rescue for this client.
  # Includes Errno::ECONNREFUSED which is not in ApplicationClient::NET_HTTP_ERRORS.
  CONNECTION_ERRORS = NET_HTTP_ERRORS + [Errno::ECONNREFUSED]

  def content_type = "application/xml"

  def authorization_header = {}

  # Validate XBRL content against Arelle.
  #
  # @param xml_content [String] the XBRL XML to validate
  # @return [ValidationResult] structured validation result
  # @raise [ConnectionError] if cannot connect to Arelle API
  def validate(xml_content)
    response = post("/validate", body: xml_content)
    parse_validation_response(response)
  rescue *CONNECTION_ERRORS => e
    raise ConnectionError, "Cannot connect to Arelle API at #{base_uri}: #{e.message}"
  end

  # Check if Arelle API is available.
  #
  # @return [Boolean] true if API responds
  def available?
    get("/docs")
    true
  rescue *CONNECTION_ERRORS => e
    Rails.logger.debug("Arelle API unavailable (connection): #{e.class}: #{e.message}")
    false
  rescue ApplicationClient::Error => e
    Rails.logger.warn("Arelle API health check failed: #{e.class}: #{e.message}")
    false
  end

  private

  def parse_validation_response(response)
    data = JSON.parse(response.body, symbolize_names: true)

    unless data.is_a?(Hash) && data.key?(:valid) && data.key?(:messages)
      raise Error, "Unexpected response format from Arelle API"
    end

    ValidationResult.new(
      valid: data[:valid],
      summary: data[:summary] || {},
      messages: data[:messages] || []
    )
  rescue JSON::ParserError => e
    Rails.logger.error("Arelle API returned invalid JSON: #{e.message}")
    raise Error, "Arelle API returned invalid response"
  end
end
