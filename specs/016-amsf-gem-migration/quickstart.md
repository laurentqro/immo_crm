# Quickstart: AMSF Survey Gem Integration

**Feature**: 016-amsf-gem-migration
**Date**: 2026-01-22

## Prerequisites

- Ruby 3.4.7
- Rails 8.1
- Access to amsf_survey gem (local path or published)

## Step 1: Add Gems

```ruby
# Gemfile
gem 'amsf_survey', path: '../amsf_survey/amsf_survey'
gem 'amsf_survey-real_estate', path: '../amsf_survey/amsf_survey-real_estate'
```

```bash
bundle install
```

## Step 2: Create Initializer

```ruby
# config/initializers/amsf_survey.rb
require 'amsf_survey/real_estate'

Rails.application.config.after_initialize do
  q = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
  Rails.logger.info "AMSF Survey loaded: #{q.field_count} fields"
rescue AmsfSurvey::TaxonomyLoadError => e
  Rails.logger.error "Failed to load AMSF Survey: #{e.message}"
  raise if Rails.env.production?
end
```

## Step 3: Verify Installation

```bash
rails console
```

```ruby
# In console
q = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
q.field_count  # => ~600
q.field(:a1101)  # => Field object
```

## Step 4: Basic Usage

### Load Questionnaire

```ruby
questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)

# Access fields
field = questionnaire.field(:a1101)
field.label  # => "Nombre total de clients"
field.type   # => :integer

# Iterate sections
questionnaire.sections.each do |section|
  puts "#{section.name}: #{section.fields.count} fields"
end
```

### Create Submission

```ruby
submission = AmsfSurvey.build_submission(
  industry: :real_estate,
  year: 2025,
  entity_id: "RCI12345",
  period: Date.new(2025, 12, 31)
)

# Set values (auto-cast)
submission[:a1101] = 150
submission[:a2202] = "Oui"

# Check completion
submission.complete?       # => false
submission.missing_fields  # => [:a1102, :a1401, ...]
```

### Validate Submission

```ruby
result = AmsfSurvey.validate(submission)

if result.valid?
  puts "Validation passed"
else
  result.errors.each do |error|
    puts "#{error.field}: #{error.message}"
  end
end
```

### Generate XBRL

```ruby
xml = AmsfSurvey.to_xbrl(submission, pretty: true)
File.write("submission.xml", xml)
```

## Step 5: Integration with CRM

### SubmissionBuilder Pattern

```ruby
class SubmissionBuilder
  def initialize(organization, year: Date.current.year)
    @organization = organization
    @year = year
  end

  def build
    @submission = find_or_create_submission
    populate_values
    @gem_submission = create_gem_submission
    Result.success(@submission)
  rescue => e
    Result.failure([e.message])
  end

  def gem_submission
    raise NotBuiltError unless @gem_submission
    @gem_submission
  end

  def validate
    AmsfSurvey.validate(gem_submission)
  end

  def generate_xbrl
    AmsfSurvey.to_xbrl(gem_submission, pretty: true)
  end

  private

  def create_gem_submission
    sub = AmsfSurvey.build_submission(
      industry: :real_estate,
      year: @year,
      entity_id: @organization.rci_number,
      period: Date.new(@year, 12, 31)
    )

    @submission.submission_values.each do |sv|
      begin
        sub[sv.element_name.to_sym] = sv.value
      rescue AmsfSurvey::UnknownFieldError
        Rails.logger.warn "Unknown field: #{sv.element_name}"
      end
    end

    sub
  end
end
```

## Common Tasks

### Check Field Visibility

```ruby
field = questionnaire.field(:a1103)
data = { tGATE: "Oui" }
field.visible?(data)  # => true or false
```

### Get Field Value Source

```ruby
submission_value = submission.submission_values.find_by(element_name: "a1101")
submission_value.source  # => "calculated" | "from_settings" | "manual"
```

### Iterate All Fields with Values

```ruby
questionnaire.fields.each do |field|
  value = submission[field.id]
  puts "#{field.id}: #{field.label} = #{value}"
end
```

## Troubleshooting

### "Industry not registered" Error

```ruby
# Check registered industries
AmsfSurvey.registered_industries  # => [:real_estate]

# Ensure gem is required
require 'amsf_survey/real_estate'
```

### "Year not supported" Error

```ruby
# Check supported years
AmsfSurvey.supported_years(:real_estate)  # => [2025]
```

### Type Casting Issues

```ruby
# Boolean values must be "Oui" or "Non"
submission[:a2202] = "Oui"   # Correct
submission[:a2202] = true    # Will be cast to "Oui"

# Integer values
submission[:a1101] = "150"   # Will be cast to 150
submission[:a1101] = 150     # Already correct type

# Monetary values
submission[:a2109B] = "5000.50"  # Will be cast to BigDecimal
```

## Testing

### Unit Test Example

```ruby
class SubmissionBuilderTest < ActiveSupport::TestCase
  test "build creates gem submission" do
    builder = SubmissionBuilder.new(organizations(:one), year: 2025)
    result = builder.build

    assert result.success?
    assert_kind_of AmsfSurvey::Submission, builder.gem_submission
  end

  test "validate returns validation result" do
    builder = SubmissionBuilder.new(organizations(:one), year: 2025)
    builder.build

    result = builder.validate

    assert_respond_to result, :valid?
    assert_respond_to result, :errors
  end
end
```

### Integration Test Example

```ruby
class AmsfGemMigrationTest < ActiveSupport::TestCase
  test "xbrl output is valid" do
    builder = SubmissionBuilder.new(organizations(:one), year: 2025)
    builder.build

    xbrl = builder.generate_xbrl

    assert_includes xbrl, 'xmlns:xbrli'
    assert_includes xbrl, 'context'
  end
end
```
