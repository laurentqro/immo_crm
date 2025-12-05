# frozen_string_literal: true

# Load XBRL taxonomy at boot time.
# This ensures taxonomy is always available and fails fast if files are missing.
#
# The taxonomy is loaded from docs/taxonomy/ and includes:
# - Element definitions from XSD
# - Labels from label linkbase
# - Presentation order from presentation linkbase
# - Short labels from config/xbrl_short_labels.yml
#
Rails.application.config.after_initialize do
  Xbrl::Taxonomy.load!
rescue Xbrl::TaxonomyLoadError => e
  Rails.logger.error "Failed to load XBRL taxonomy: #{e.message}"
  raise if Rails.env.production?
end
