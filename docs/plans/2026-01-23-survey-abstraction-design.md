# Survey Abstraction Design

## Goal

Hide XBRL completely from the application. If AMSF switches to another format tomorrow, no application code changes.

## Design Principle

The `amsf_survey` gem is the **single coupling point**. The application knows nothing about XBRL codes—only semantic field names.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     immo_crm Application                     │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    Survey Model                      │    │
│  │                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │ CustomerRisk│  │ ProductsRisk│  │Distribution │  │    │
│  │  └─────────────┘  └─────────────┘  │    Risk     │  │    │
│  │                                    └─────────────┘  │    │
│  │  ┌─────────────┐  ┌─────────────┐                   │    │
│  │  │  Controls   │  │ Signatories │                   │    │
│  │  └─────────────┘  └─────────────┘                   │    │
│  │                                                      │    │
│  │  Methods: #total_clients, #high_risk_clients, etc.  │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            │ semantic names only             │
│                            ▼                                 │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ AmsfSurvey API
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      amsf_survey gem                         │
│                                                              │
│  semantic_mappings.yml: total_clients → a1101               │
│  Handles: XBRL codes, XML generation, validation            │
└─────────────────────────────────────────────────────────────┘
```

## Survey PORO Responsibility

**Survey is a read-only value calculator.** Given an organization and year, it produces pre-filled values for all questionnaire fields:

| Field Type | Survey Method | Returns |
|------------|---------------|---------|
| Calculated | `total_clients` | Computed from CRM data |
| From settings | `entity_name` | Value from organization |
| Entry-only | (no method) | `nil` — user fills via form |

**Survey does NOT:**
- Read from database (no stored values)
- Know about drafts, submissions, or persistence
- Handle user edits or overrides

The form/persistence layer (separate concern) displays Survey values, accepts user input, and saves elsewhere.

## File Structure

```
app/models/
  survey.rb                       # Main Survey PORO
  survey/
    fields/
      customer_risk.rb            # Tab 1: Customer Risk Assessment
      products_services_risk.rb   # Tab 2: Products/Services Risk
      distribution_risk.rb        # Tab 3: Distribution Channel Risk
      controls.rb                 # Tab 4: Internal Controls
      signatories.rb              # Tab 5: Signatories
```

The `Fields` namespace signals these modules contain only field methods. The 5 modules mirror AMSF's questionnaire tabs exactly.

## Survey Class

```ruby
# app/models/survey.rb
class Survey
  include Survey::Fields::CustomerRisk
  include Survey::Fields::ProductsServicesRisk
  include Survey::Fields::DistributionRisk
  include Survey::Fields::Controls
  include Survey::Fields::Signatories

  attr_reader :organization, :year

  def initialize(organization:, year:)
    @organization = organization
    @year = year
  end

  def valid?
    validation_result.valid?
  end

  def errors
    validation_result.errors
  end

  def to_xbrl
    AmsfSurvey.to_xbrl(submission, pretty: true)
  end

  private

  def questionnaire
    @questionnaire ||= AmsfSurvey.questionnaire(industry: :real_estate, year: year)
  end

  def submission
    @submission ||= build_submission
  end

  def validation_result
    @validation_result ||= AmsfSurvey.validate(submission)
  end

  def build_submission
    sub = AmsfSurvey.build_submission(
      industry: :real_estate,
      year: year,
      entity_id: organization.rci_number,
      period: Date.new(year, 12, 31)
    )

    questionnaire.fields.each do |field|
      value = send(field.name) if respond_to?(field.name, true)
      sub[field.name] = value if value.present?
    end

    sub
  end
end
```

## Field Module Example

```ruby
# app/models/survey/fields/customer_risk.rb
module Survey::Fields::CustomerRisk
  extend ActiveSupport::Concern

  private

  # Calculated from CRM data
  def total_clients
    organization.clients.count
  end

  def high_risk_clients
    organization.clients.high_risk.count
  end

  def clients_by_country
    organization.clients.group(:country_code).count
  end

  # From organization settings
  def entity_name
    organization.name
  end

  # Entry-only fields have NO method here.
  # Survey returns nil → form shows empty field for user input.

  # ... more methods for Tab 1 fields
end
```

## Key Behaviors

1. **Dynamic field population**: `questionnaire.fields.each { |f| send(f.name) }`
2. **Semantic method names**: Methods named after gem's semantic mappings (`:total_clients`, not `:a1101`)
3. **Private methods**: Field methods are private—Survey iterates them internally
4. **Entry-only = no method**: Fields requiring user input have no method; `respond_to?` returns false, value stays nil
5. **Read-only**: Survey calculates values but never persists or reads stored data

## What Gets Removed

After implementation, delete:

- `app/services/submission_builder.rb`
- `app/services/submission_renderer.rb`
- `app/services/calculation_engine.rb`
- `app/models/xbrl/element_manifest.rb`
- `app/models/xbrl/taxonomy.rb`
- `app/models/xbrl/taxonomy_element.rb`
- `app/models/xbrl/survey.rb`
- `app/views/submissions/show.xml.erb`
- `config/initializers/xbrl_taxonomy.rb`
- `config/xbrl_short_labels.yml`
- `docs/taxonomy/` directory

## Form & Persistence (Separate Concern)

Survey provides pre-filled values. A separate layer handles:

1. **Display**: Render form with Survey values as defaults
2. **User input**: Accept edits for all fields (including overrides of calculated values)
3. **Persistence**: Save to AR model (design TBD)
4. **Submission**: Merge user edits with Survey values, generate XBRL

This separation keeps Survey pure (read-only calculator) and persistence flexible.

## Semantic Field Mapping

The gem's `semantic_mappings.yml` (323 fields) provides the canonical field names. Example mappings:

| Semantic Name | XBRL Code | Source |
|--------------|-----------|--------|
| total_clients | a1101 | calculated |
| high_risk_clients | a1102 | calculated |
| entity_name | a0101 | from_settings |
| rci_number | a0102 | from_settings |

The application only knows semantic names. XBRL codes are an implementation detail of the gem.

## Handling Taxonomy Updates

When AMSF updates the questionnaire (new gem version):

| Change Type | App Impact | Detection |
|-------------|------------|-----------|
| Modified questions | None (semantic name unchanged) | Automatic |
| Deleted questions | Dead methods (harmless) | Periodic cleanup |
| New questions | Missing implementation | CI test fails |

### Completeness Test

A single test ensures all questionnaire fields have implementations:

```ruby
# test/models/survey_completeness_test.rb
class SurveyCompletenessTest < ActiveSupport::TestCase
  test "Survey implements all questionnaire fields" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
    survey = Survey.new(organization: organizations(:one), year: 2025)

    missing = questionnaire.fields.map(&:name).reject do |name|
      survey.respond_to?(name, true)
    end

    assert missing.empty?, "Survey missing implementations for: #{missing.join(', ')}"
  end
end
```

This test fails CI before deploy if any new field lacks an implementation.
