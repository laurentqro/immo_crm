# frozen_string_literal: true

# Load XBRL taxonomy at boot time and after each reload in development.
# This ensures taxonomy is always available and fails fast if files are missing.
#
# The taxonomy is loaded from docs/taxonomy/ and includes:
# - Element definitions from XSD
# - Labels from label linkbase
# - Presentation order from presentation linkbase
# - Short labels from config/xbrl_short_labels.yml
#
# Uses to_prepare to handle class reloading in development - runs after each
# reload but only once in production.
#
Rails.application.config.to_prepare do
  Xbrl::Taxonomy.load!

  # Validate Survey element references against taxonomy
  Xbrl::Survey.validate!
rescue Xbrl::TaxonomyLoadError => e
  Rails.logger.error "Failed to load XBRL taxonomy: #{e.message}"
  raise if Rails.env.production?
end
