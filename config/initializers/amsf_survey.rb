# frozen_string_literal: true

# Load the AMSF Survey gem and register the real estate industry.
#
# This initializer:
# 1. Requires the real estate plugin (auto-registers :real_estate industry)
# 2. Verifies the gem loaded correctly
# 3. Logs available questionnaire information
# 4. Configures Arelle validation toggle
#
# The gem provides:
# - Questionnaire metadata (fields, sections, labels)
# - Submission value objects for building XBRL
# - Validation rules (presence, enum, range)
# - XBRL generation
#
# Configuration:
# - ARELLE_VALIDATION_ENABLED: Enable external Arelle validation (default: false in dev/test, true in production)
#
require "amsf_survey/real_estate"

# Arelle validation configuration
# When enabled, submissions are validated against both gem rules AND external Arelle service
# This provides schema-level XSD validation beyond the gem's business rule validation
module AmsfValidationConfig
  class << self
    def arelle_enabled?
      # Default to enabled in production for schema-level validation
      # Disabled in development/test to avoid external service dependency
      default = Rails.env.production?
      ActiveModel::Type::Boolean.new.cast(
        ENV.fetch("ARELLE_VALIDATION_ENABLED", default)
      )
    end
  end
end

Rails.application.config.after_initialize do
  # Verify the gem is properly configured
  unless AmsfSurvey.registered?(:real_estate)
    raise "AMSF Survey real_estate plugin failed to register"
  end

  years = AmsfSurvey.supported_years(:real_estate)
  if years.empty?
    Rails.logger.warn "AMSF Survey: No taxonomy years found for real_estate"
  else
    Rails.logger.info "AMSF Survey loaded: real_estate industry with years #{years.join(", ")}"

    # Verify the default year questionnaire loads correctly
    default_year = years.max
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: default_year)
    Rails.logger.info "AMSF Survey #{default_year}: #{questionnaire.question_count} questions, #{questionnaire.sections.size} sections"
  end
rescue AmsfSurvey::TaxonomyLoadError => e
  Rails.logger.error "Failed to load AMSF Survey: #{e.message}"
  raise if Rails.env.production?
end
