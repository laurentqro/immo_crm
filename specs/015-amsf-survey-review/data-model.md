# Data Model: AMSF Survey Review Page

**Branch**: `015-amsf-survey-review` | **Date**: 2025-12-05

## Overview

This feature adds a new `Xbrl::Survey` module and extends existing models. No database migrations required - uses existing `SubmissionValue.metadata` JSONB field.

## New Components

### Xbrl::Survey Module

**Purpose**: Defines the AMSF questionnaire structure (sections and element assignments) that is not present in the XBRL taxonomy files.

```ruby
# app/models/xbrl/survey.rb
module Xbrl
  module Survey
    # Section structure matching official AMSF questionnaire
    # Format: { section_id: { title:, elements: [] } }
    SECTIONS = {
      "1.1" => {
        title: "Identification de l'assujetti",
        elements: %w[a1000 a1001 a1002 ...] # Element names from taxonomy
      },
      "1.2" => {
        title: "Période de référence",
        elements: %w[a1010 a1011 ...]
      },
      # ... ~25 sections total
    }.freeze

    class << self
      # Returns all sections in display order
      # @return [Array<Hash>] Array of { id:, title:, elements: }
      def sections
        SECTIONS.map { |id, data| { id: id, title: data[:title], elements: data[:elements] } }
      end

      # Returns elements for a specific section
      # @param section_id [String] Section identifier (e.g., "1.1")
      # @return [Array<String>] Element names
      def elements_for(section_id)
        SECTIONS.dig(section_id, :elements) || []
      end

      # Validates all element names exist in taxonomy
      # Called at boot time via initializer
      # @raise [RuntimeError] If any element name is invalid
      def validate!
        all_elements = SECTIONS.values.flat_map { |s| s[:elements] }
        valid_names = Xbrl::Taxonomy.instance.elements.map(&:name).to_set

        invalid = all_elements.reject { |name| valid_names.include?(name) }
        if invalid.any?
          raise "Xbrl::Survey references invalid elements: #{invalid.join(', ')}"
        end
      end
    end
  end
end
```

**Validation**: Boot-time validation in initializer ensures Survey references only valid taxonomy elements:

```ruby
# config/initializers/xbrl_taxonomy.rb (modification)
Rails.application.config.after_initialize do
  Xbrl::Taxonomy.instance # Load taxonomy
  Xbrl::Survey.validate!  # Validate survey structure
end
```

### ElementValue Enhancement

**Purpose**: Add `needs_review` flag to the existing `ElementValue` struct.

```ruby
# app/models/xbrl/element_manifest.rb (modification)
class ElementValue
  attr_reader :element, :value, :source, :overridden, :needs_review

  def initialize(element:, value:, source:, overridden:, needs_review: false)
    @element = element
    @value = value
    @source = source
    @overridden = overridden
    @needs_review = needs_review
  end
end
```

## Modified Components

### SubmissionValue

**Purpose**: Add method to check if value is flagged for review.

```ruby
# app/models/submission_value.rb (modification)
class SubmissionValue < ApplicationRecord
  # ... existing code ...

  # Checks if this value is flagged for review
  # @return [Boolean]
  def needs_review?
    metadata&.dig("flagged_for_review") == true
  end
end
```

**Storage**: Uses existing `metadata` JSONB column. No migration needed.

### ElementManifest

**Purpose**: Populate `needs_review` when building `ElementValue` objects.

```ruby
# app/models/xbrl/element_manifest.rb (modification)
def build_element_value(element, submission_value)
  ElementValue.new(
    element: element,
    value: submission_value&.display_value,
    source: submission_value&.source || "calculated",
    overridden: submission_value&.overridden?,
    needs_review: submission_value&.needs_review? || false
  )
end
```

## Entity Relationships

```
┌─────────────────────┐     ┌──────────────────────┐
│   Xbrl::Survey      │     │   Xbrl::Taxonomy     │
│                     │     │                      │
│ SECTIONS constant   │────▶│ elements collection  │
│ (section→elements)  │     │ (TaxonomyElement[])  │
└─────────────────────┘     └──────────────────────┘
                                      │
                                      ▼
┌─────────────────────┐     ┌──────────────────────┐
│ Xbrl::ElementManifest│────▶│ Xbrl::ElementValue   │
│                     │     │                      │
│ submission          │     │ element              │
│ elements[]          │     │ value                │
└─────────────────────┘     │ source               │
          │                 │ overridden           │
          │                 │ needs_review ◀──NEW  │
          ▼                 └──────────────────────┘
┌─────────────────────┐
│   SubmissionValue   │
│                     │
│ metadata JSONB      │
│ ├─ flagged_for_     │
│ │  review: boolean  │
│ └─ ...              │
└─────────────────────┘
```

## Data Flow

1. **Page Load**:
   - Controller loads `Submission` with `SubmissionValue` records
   - Builds `ElementManifest` for submission
   - Groups elements by `Xbrl::Survey.sections`
   - Passes grouped data to view

2. **Filtering** (client-side):
   - Stimulus controller reads filter inputs
   - Toggles visibility of element rows via CSS classes
   - Updates element count display

3. **Completion**:
   - Controller updates `Submission.status` to "completed"
   - Redirects to submission detail page

## Test Data

Fixtures should include:

```yaml
# test/fixtures/submission_values.yml
value_with_review_flag:
  submission: draft_submission
  element_name: "a1000"
  value: "Test Value"
  metadata:
    flagged_for_review: true

value_without_review_flag:
  submission: draft_submission
  element_name: "a1001"
  value: "Another Value"
  metadata: {}
```
