# ImmoCRM AMSF Survey — Ralph Loop Agent Instructions

## What is this?

ImmoCRM is a compliance SaaS for Monaco real estate agencies. The AMSF (Autorité Monégasque de Sécurité Financière) requires agencies to complete an annual AML/CFT survey of 323 questions (including attestation), submitted as XBRL.

## Experiment: Clean Rebuild

You are on a **fresh branch** (`ralph-amsf-experiment`). The field modules in `app/models/survey/fields/` have been emptied — only the module structure and `include` statements remain. Your job is to **rebuild every field method from scratch** using the XBRL taxonomy as the spec.

You have access to the full ImmoCRM data layer (Client, Transaction, Organization, Setting models) but NO legacy field implementations. Build each method correctly from the start.

### Before starting
Verify you're on the right branch:
```bash
git branch --show-current  # should be ralph-amsf-experiment
```
## Development Process — TDD Required (No Exceptions)

Follow the TDD skill at `skills/tdd/SKILL.md`:

1. **RED**: Write ONE failing test for the next behavior
2. **GREEN**: Write minimal code to make it pass  
3. **REFACTOR**: Clean up only when green

Vertical slices only. Never write implementation without a failing test first.
Never write multiple tests before implementing. One test → one impl → repeat.

If you catch yourself writing code without a red test, STOP and write the test first.

## Key files

- `amsf_questions.csv` — All 322 questions with section, number, text, instructions
- `app/models/survey/fields/customer_risk.rb` — Sections 1.1–1.15
- `app/models/survey/fields/distribution_risk.rb` — Section 2.x
- `app/models/survey/fields/products_services_risk.rb` — Section 2.x (products)
- `app/models/survey/fields/controls.rb` — Section 3.x
- `app/models/survey/fields/signatories.rb` — Attestation + signatories
- `app/models/survey/fields/helpers.rb` — Shared helper methods (private)
- `progress.txt` — Task tracker (update after each section)

## XBRL Taxonomy Reference (in repo root)

- `questionnaire_structure.yml` — Maps question numbers to field_ids and XBRL elements. **This is the source of truth for field names and types.**
- `taxonomy.yml` — Dimensional config (country breakdowns, abstract patterns)
- `strix_Real_Estate_AML_CFT_survey_2025.xsd` — XBRL schema (field types, enums, restrictions)
- `strix_Real_Estate_AML_CFT_survey_2025_lab.xml` — XBRL labels (human-readable field names in FR/EN)
- `strix_Real_Estate_AML_CFT_survey_2025_def.xml` — XBRL dimensional definitions
- `strix_Real_Estate_AML_CFT_survey_2025_pre.xml` — XBRL presentation linkbase
- `strix_Real_Estate_AML_CFT_survey_2025.xule` — XBRL validation rules
- `survey_instructions_EN.pdf` — Official AMSF survey instructions (English)
- `survey_instructions_FR.pdf` — Official AMSF survey instructions (French)

Use the XSD to check expected types (xbrli:integerItemType, xbrli:decimalItemType, xbrli:booleanItemType, etc.) and enum restrictions. Use the labels file to understand what each field means. Use the XULE rules to understand validation constraints.

## The amsf_survey gem (symlinked at ../amsf_survey)

- Defines the questionnaire structure: `amsf_survey-real_estate/taxonomies/2025/questionnaire_structure.yml`
- Maps field_ids to XBRL taxonomy elements
- Handles XBRL generation from the field values ImmoCRM provides
- **DO NOT modify the gem** — only modify ImmoCRM's field implementations

## What "done" means for each field

1. **Implemented from scratch** — The method computes real data from the ImmoCRM models (Client, Transaction, Organization, Setting)
2. **Correct return type** — Matches the XSD type: xbrli:integerItemType, xbrli:decimalItemType, xbrli:booleanItemType, enum, or string
3. **Correct scope** — Uses the right data filters (year, transaction type, client type, nationality, etc.) as described in the question instructions
4. **Tested** — Each field has a test verifying it returns the correct value for known test data
5. **XBRL validated** — If Arelle is available, the generated XBRL passes validation

## How to determine the right implementation

Each question falls into one of these categories. Read the question text and instructions in `amsf_questions.csv` to determine which:

### 1. Computed fields — query real data
Questions asking "how many", "what total", "provide the breakdown". These query Client, Transaction, or related models.
```ruby
def a1101
  clients_kept.for_year(year).purchase_sale.count
end
```

### 2. Settings-based fields — admin configurable
Questions asking "does your entity have...", "do you use...". These are policy/process questions the agency admin answers via the Settings UI.
```ruby
def ac1201
  setting_value_for("ac1201") || "Non"
end
```

### 3. Conditional fields — depend on another answer
Questions that only apply if a parent question is answered a certain way.
```ruby
def ac1208
  return nil unless ac1201 == "Oui"
  setting_value_for("ac1208") || "Par l'entité"
end
```

### 4. Country breakdown fields (dimensional)
Questions asking for breakdown by nationality/country. These return a hash that the gem converts to dimensional XBRL.
```ruby
def a1802btola
  clients_kept.for_year(year)
    .where.not(legal_entity_type: nil)
    .group(:incorporation_country)
    .count
end
```

### How to tell which category
- Question mentions "number of", "total value", "breakdown by" → **computed**
- Question mentions "does your entity", "do you have", "is there a" → **settings**
- Question says "if yes to Qxx" or "specify" → **conditional**
- Question mentions "by nationality", "by country of residence" → **country breakdown**

### Key helpers available (from helpers.rb)
- `clients_kept` — active clients in the organization
- `year_transactions` — transactions for the reporting year
- `five_year_transactions` — 5-year lookback
- `setting_value_for(key)` — read from organization settings
- `year` — the survey reporting year
- `organization` — the agency/tenant

## XBRL Validation via Arelle API

The project has a custom Arelle API server at `../arelle-api` (https://github.com/laurentqro/arelle-api). It validates XBRL instance documents against the AMSF/Strix taxonomy.

### Starting the server
```bash
cd ../arelle-api
docker build -t arelle-api .
docker run -d -p 8000:8000 arelle-api
```
The Docker image includes the taxonomy cache — no additional setup needed.

### Validation in the loop
After fixing a field, generate XBRL and validate:

```bash
# Generate XBRL for a test survey, then validate:
curl -X POST http://localhost:8000/validate \
  -H "Content-Type: application/xml" \
  --data-binary @tmp/survey_output.xml
```

Response format:
```json
{
  "valid": false,
  "summary": { "errors": 2, "warnings": 1, "info": 3 },
  "messages": [
    { "severity": "error", "code": "...", "message": "..." }
  ]
}
```

### Ruby integration (already exists in the codebase)
```ruby
class XbrlValidator
  API_URL = ENV.fetch("ARELLE_API_URL", "http://localhost:8000")

  def self.validate(xml_string)
    response = Net::HTTP.post(
      URI("#{API_URL}/validate"),
      xml_string,
      "Content-Type" => "application/xml"
    )
    JSON.parse(response.body)
  end
end

result = XbrlValidator.validate(survey.to_xbrl)
```

If Arelle is not running, skip validation but note it in the commit message: `[AMSF Qnum] ... (Arelle validation pending)`.

## Rules

1. Read `progress.txt` to find the next incomplete task
2. Find the question in `amsf_questions.csv` — read the question text AND instructions carefully
3. Look up the field_id in `questionnaire_structure.yml` — note the expected type from the XSD
4. Determine the category (computed, settings, conditional, or country breakdown)
5. Explore the ImmoCRM models to understand available data (Client, Transaction, Organization scopes)
6. Implement the method in the correct field module
7. Write a test for this field
8. Run tests: `bin/rails test`
9. If Arelle is running, generate XBRL and validate
10. Commit: `[AMSF Qnum] Short description`
11. Update `progress.txt`
12. **ONE QUESTION PER ITERATION**

## Do NOT

- Modify the amsf_survey gem
- Skip tests
- Copy from the old implementation (you don't have access to it — build fresh)
- Change method signatures (the gem expects specific method names matching field_ids)
- Implement multiple questions in one iteration
- Guess at model scopes — explore the actual models first (Client, Transaction, etc.)
