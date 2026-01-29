# API Contract: Gem Integration

**Feature**: 016-amsf-gem-migration
**Date**: 2026-01-22

## Overview

This document defines the contract between immo_crm and the amsf_survey gem. No REST API changes are required - this migration affects internal service interfaces.

## Service Contracts

### SubmissionBuilder

**Interface** (refactored):

```ruby
class SubmissionBuilder
  # Initialize with organization and year
  def initialize(organization, year: Date.current.year)

  # Build submission and populate values
  # Returns: SubmissionBuilder::Result
  def build

  # Get the gem submission (for validation/generation)
  # Returns: AmsfSurvey::Submission
  # Raises: NotBuiltError if build not called
  def gem_submission

  # Generate XBRL XML
  # Returns: String (XML)
  # Raises: NotBuiltError if build not called
  def generate_xbrl

  # Validate submission
  # Returns: AmsfSurvey::ValidationResult
  # Raises: NotBuiltError if build not called
  def validate
end
```

**Result object**:
```ruby
SubmissionBuilder::Result = Struct.new(:success, :submission, :errors) do
  def success?
    success
  end
end
```

### SubmissionRenderer

**Interface** (refactored):

```ruby
class SubmissionRenderer
  # Initialize with AR submission
  def initialize(submission)

  # Render XBRL XML (via gem)
  # Returns: String (XML)
  def to_xbrl

  # Render HTML review (unchanged)
  # Returns: String (HTML)
  def to_html

  # Render Markdown export (unchanged)
  # Returns: String (Markdown)
  def to_markdown
end
```

### ValidationService

**Interface** (enhanced):

```ruby
class ValidationService
  # Initialize with AR submission or XBRL content
  def initialize(submission_or_content)

  # Validate submission
  # Returns: ValidationService::Result
  def validate

  # Check if external validator is healthy
  # Returns: Boolean
  def self.healthy?
end
```

**Result object** (unified):
```ruby
ValidationService::Result = Struct.new(:valid, :errors, :warnings, keyword_init: true) do
  def valid?
    valid
  end
end
```

**Error format** (unchanged):
```ruby
{
  code: "PRESENCE_ERROR",      # or "RANGE_ERROR", "ENUM_ERROR", "SERVICE_ERROR"
  message: "Field required",   # Localized message
  element: "a1101"             # Field ID (optional)
}
```

### ElementManifest

**Interface** (refactored):

```ruby
module Xbrl
  class ElementManifest
    # Initialize with AR submission
    def initialize(submission)

    # Get field by ID
    # Returns: AmsfSurvey::Field or nil
    def field(id)

    # Get all fields
    # Returns: Array<AmsfSurvey::Field>
    def all_fields

    # Get fields grouped by section
    # Returns: Hash{String => Array<AmsfSurvey::Field>}
    def fields_by_section

    # Get value for a field
    # Returns: String or nil
    def value_for(field_id)

    # Get elements with values for iteration
    # Returns: Array<ElementValue> (presenter objects)
    def elements_by_section
  end
end
```

## Gem API Contract

### AmsfSurvey Module

| Method | Input | Output | Notes |
|--------|-------|--------|-------|
| `questionnaire(industry:, year:)` | `:real_estate`, `2025` | `Questionnaire` | Cached |
| `build_submission(industry:, year:, entity_id:, period:)` | Symbol, Integer, String, Date | `Submission` | Value object |
| `validate(submission)` | `Submission` | `ValidationResult` | French locale default |
| `to_xbrl(submission, **opts)` | `Submission`, options | `String` (XML) | `pretty:`, `include_empty:` |

### Questionnaire Methods

| Method | Returns | Notes |
|--------|---------|-------|
| `fields` | `Array<Field>` | All fields in order |
| `sections` | `Array<Section>` | Logical groupings |
| `field(id)` | `Field` or `nil` | By XBRL code or semantic name |
| `field_count` | `Integer` | ~600 for real_estate |
| `taxonomy_namespace` | `String` | For XBRL generation |

### Field Methods

| Method | Returns | Notes |
|--------|---------|-------|
| `id` | `Symbol` | XBRL code as symbol |
| `label` | `String` | French label |
| `type` | `Symbol` | `:boolean`, `:integer`, `:string`, `:monetary`, `:enum`, `:percentage` |
| `gate?` | `Boolean` | Controls visibility of other fields |
| `visible?(data)` | `Boolean` | Check gate dependencies |
| `required?` | `Boolean` | True if not computed |
| `cast(value)` | `Object` | Type-cast value |

### Submission Methods

| Method | Returns | Notes |
|--------|---------|-------|
| `[field_id]` | `Object` | Get value |
| `[field_id]=value` | `Object` | Set value (auto-cast) |
| `data` | `Hash` | Frozen copy of values |
| `complete?` | `Boolean` | All required visible fields filled |
| `missing_fields` | `Array<Symbol>` | IDs of missing fields |

### ValidationResult Methods

| Method | Returns | Notes |
|--------|---------|-------|
| `valid?` | `Boolean` | No errors |
| `errors` | `Array<ValidationError>` | Error-level issues |
| `warnings` | `Array<ValidationError>` | Warning-level issues |

### ValidationError Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `field` | `Symbol` | Field ID |
| `rule` | `Symbol` | `:presence`, `:enum`, `:range` |
| `message` | `String` | Localized message |
| `severity` | `Symbol` | `:error` or `:warning` |
| `context` | `Hash` | Additional info |

## Error Handling

### Gem Errors

| Error Class | When Raised | Handling |
|-------------|-------------|----------|
| `TaxonomyLoadError` | Industry not registered, year not supported | Log and show user error |
| `UnknownFieldError` | Field ID not in questionnaire | Log and skip field |
| `GeneratorError` | Invalid submission data | Log and show user error |

### Expected Error Scenarios

1. **Gem fails to load at boot**: Application fails to start. Fix gem installation.
2. **Unknown field in SubmissionValue**: Log warning, skip field during conversion.
3. **Validation fails**: Return structured errors to user.
4. **XBRL generation fails**: Log error, show user message.
5. **External Arelle unavailable**: Return gem validation result, warn in logs.
