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

## File Structure

```
app/models/
  survey.rb                     # Main Survey PORO
  survey/
    customer_risk.rb            # Tab 1: Customer Risk Assessment
    products_services_risk.rb   # Tab 2: Products/Services Risk
    distribution_risk.rb        # Tab 3: Distribution Channel Risk
    controls.rb                 # Tab 4: Internal Controls
    signatories.rb              # Tab 5: Signatories
```

The 5 modules mirror AMSF's questionnaire tabs exactly.

## Survey Class

```ruby
# app/models/survey.rb
class Survey
  include Survey::CustomerRisk
  include Survey::ProductsServicesRisk
  include Survey::DistributionRisk
  include Survey::Controls
  include Survey::Signatories

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

## Concern Module Example

```ruby
# app/models/survey/customer_risk.rb
module Survey::CustomerRisk
  extend ActiveSupport::Concern

  private

  def total_clients
    organization.clients.count
  end

  def high_risk_clients
    organization.clients.high_risk.count
  end

  def clients_by_country
    organization.clients.group(:country_code).count
  end

  # ... ~60 more methods for Tab 1 fields
end
```

## Key Behaviors

1. **Dynamic field population**: `questionnaire.fields.each { |f| send(f.name) }`
2. **Semantic method names**: Methods named after gem's semantic mappings (`:total_clients`, not `:a1101`)
3. **Private methods**: Field methods are private—only the gem iterates them
4. **Graceful nil handling**: Missing methods or nil values are skipped

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

## Migration Notes

- This is greenfield design—no backward compatibility needed
- The `Submission` AR model may still be used to store survey state/status
- Field values can be cached in `SubmissionValue` if needed for persistence/editing

## Semantic Field Mapping

The gem's `semantic_mappings.yml` (323 fields) provides the canonical field names. Example mappings:

| Semantic Name | XBRL Code | Source |
|--------------|-----------|--------|
| total_clients | a1101 | calculated |
| high_risk_clients | a1102 | calculated |
| entity_name | a0101 | from_settings |
| rci_number | a0102 | from_settings |

The application only knows semantic names. XBRL codes are an implementation detail of the gem.
