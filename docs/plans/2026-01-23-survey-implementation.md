# Survey PORO Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a Survey PORO that calculates field values from CRM data and generates XBRL via the amsf_survey gem, hiding all XBRL knowledge from the application.

**Architecture:** Survey is a read-only value calculator. It iterates the gem's questionnaire fields, calls semantic methods (e.g., `total_clients`), and populates a gem submission. The gem handles XBRL codes and XML generation. Field methods are organized into 5 concern modules matching AMSF's questionnaire tabs.

**Tech Stack:** Ruby 3.2+, Rails 8, amsf_survey gem, amsf_survey-real_estate gem, Minitest

---

## Task 1: Create Survey PORO Skeleton

**Files:**
- Create: `app/models/survey.rb`
- Test: `test/models/survey_test.rb`

**Step 1: Write the failing test**

```ruby
# test/models/survey_test.rb
require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @survey = Survey.new(organization: @organization, year: 2025)
  end

  test "initializes with organization and year" do
    assert_equal @organization, @survey.organization
    assert_equal 2025, @survey.year
  end

  test "questionnaire returns gem questionnaire for year" do
    questionnaire = @survey.send(:questionnaire)

    assert_instance_of AmsfSurvey::Questionnaire, questionnaire
    assert_equal 2025, questionnaire.year
    assert_equal :real_estate, questionnaire.industry
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: FAIL with "uninitialized constant Survey"

**Step 3: Write minimal implementation**

```ruby
# app/models/survey.rb
# frozen_string_literal: true

# Survey is a read-only value calculator for AMSF submissions.
# Given an organization and year, it produces values for all questionnaire fields
# by calling semantic methods (e.g., total_clients, high_risk_clients).
#
# The amsf_survey gem handles XBRL codes and XML generation.
# This class knows nothing about XBRL - only semantic field names.
#
# Usage:
#   survey = Survey.new(organization: org, year: 2025)
#   survey.to_xbrl  # => XML string
#   survey.valid?   # => true/false
#
class Survey
  attr_reader :organization, :year

  def initialize(organization:, year:)
    @organization = organization
    @year = year
  end

  private

  def questionnaire
    @questionnaire ||= AmsfSurvey.questionnaire(industry: :real_estate, year: year)
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/survey.rb test/models/survey_test.rb
git commit -m "feat: add Survey PORO skeleton with questionnaire access"
```

---

## Task 2: Add build_submission Method

**Files:**
- Modify: `app/models/survey.rb`
- Modify: `test/models/survey_test.rb`

**Step 1: Write the failing test**

```ruby
# Add to test/models/survey_test.rb

test "build_submission creates gem submission with entity info" do
  submission = @survey.send(:build_submission)

  assert_instance_of AmsfSurvey::Submission, submission
  assert_equal @organization.rci_number, submission.entity_id
  assert_equal Date.new(2025, 12, 31), submission.period
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: FAIL with "undefined method `build_submission'"

**Step 3: Write minimal implementation**

```ruby
# Add to app/models/survey.rb, inside class Survey, private section

def submission
  @submission ||= build_submission
end

def build_submission
  sub = AmsfSurvey.build_submission(
    industry: :real_estate,
    year: year,
    entity_id: organization.rci_number,
    period: Date.new(year, 12, 31)
  )

  populate_fields(sub)
  sub
end

def populate_fields(sub)
  questionnaire.fields.each do |field|
    next unless respond_to?(field.name, true)

    value = send(field.name)
    sub[field.name] = value if value.present?
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/survey.rb test/models/survey_test.rb
git commit -m "feat: add build_submission with field population loop"
```

---

## Task 3: Add to_xbrl Method

**Files:**
- Modify: `app/models/survey.rb`
- Modify: `test/models/survey_test.rb`

**Step 1: Write the failing test**

```ruby
# Add to test/models/survey_test.rb

test "to_xbrl generates valid XML" do
  xbrl = @survey.to_xbrl

  assert_includes xbrl, '<?xml version="1.0"'
  assert_includes xbrl, "xbrli:xbrl"
  assert_includes xbrl, @organization.rci_number
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: FAIL with "undefined method `to_xbrl'"

**Step 3: Write minimal implementation**

```ruby
# Add to app/models/survey.rb, public section (before private)

def to_xbrl
  AmsfSurvey.to_xbrl(submission, pretty: true)
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/survey.rb test/models/survey_test.rb
git commit -m "feat: add to_xbrl method for XBRL generation"
```

---

## Task 4: Add valid? and errors Methods

**Files:**
- Modify: `app/models/survey.rb`
- Modify: `test/models/survey_test.rb`

**Step 1: Write the failing test**

```ruby
# Add to test/models/survey_test.rb

test "valid? returns validation status" do
  # With no field implementations, submission has missing required fields
  assert_respond_to @survey, :valid?
  assert_equal false, @survey.valid?  # Expected to fail initially
end

test "errors returns validation errors" do
  errors = @survey.errors

  assert_respond_to errors, :each
  assert errors.any?, "Expected validation errors for empty submission"
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: FAIL with "undefined method `valid?'"

**Step 3: Write minimal implementation**

```ruby
# Add to app/models/survey.rb, public section

def valid?
  validation_result.valid?
end

def errors
  validation_result.errors
end

# Add to private section

def validation_result
  @validation_result ||= AmsfSurvey.validate(submission)
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/survey.rb test/models/survey_test.rb
git commit -m "feat: add valid? and errors methods for validation"
```

---

## Task 5: Create Fields Module Structure

**Files:**
- Create: `app/models/survey/fields/customer_risk.rb`
- Create: `app/models/survey/fields/products_services_risk.rb`
- Create: `app/models/survey/fields/distribution_risk.rb`
- Create: `app/models/survey/fields/controls.rb`
- Create: `app/models/survey/fields/signatories.rb`
- Modify: `app/models/survey.rb`

**Step 1: Create directory structure**

Run: `mkdir -p app/models/survey/fields`

**Step 2: Create empty concern modules**

```ruby
# app/models/survey/fields/customer_risk.rb
# frozen_string_literal: true

module Survey
  module Fields
    # Customer Risk Assessment fields (Tab 1)
    # Contains methods for client statistics, risk categorization, etc.
    module CustomerRisk
      extend ActiveSupport::Concern

      private

      # Field methods will be added here
    end
  end
end
```

```ruby
# app/models/survey/fields/products_services_risk.rb
# frozen_string_literal: true

module Survey
  module Fields
    # Products/Services Risk fields (Tab 2)
    # Contains methods for transaction statistics, product types, etc.
    module ProductsServicesRisk
      extend ActiveSupport::Concern

      private

      # Field methods will be added here
    end
  end
end
```

```ruby
# app/models/survey/fields/distribution_risk.rb
# frozen_string_literal: true

module Survey
  module Fields
    # Distribution Channel Risk fields (Tab 3)
    # Contains methods for distribution channels, geographic risk, etc.
    module DistributionRisk
      extend ActiveSupport::Concern

      private

      # Field methods will be added here
    end
  end
end
```

```ruby
# app/models/survey/fields/controls.rb
# frozen_string_literal: true

module Survey
  module Fields
    # Internal Controls fields (Tab 4)
    # Contains methods for AML policies, training, STR reports, etc.
    module Controls
      extend ActiveSupport::Concern

      private

      # Field methods will be added here
    end
  end
end
```

```ruby
# app/models/survey/fields/signatories.rb
# frozen_string_literal: true

module Survey
  module Fields
    # Signatories fields (Tab 5)
    # Contains methods for entity info, signatory details, etc.
    module Signatories
      extend ActiveSupport::Concern

      private

      # Field methods will be added here
    end
  end
end
```

**Step 3: Update Survey to include modules**

```ruby
# app/models/survey.rb - update class definition
class Survey
  include Survey::Fields::CustomerRisk
  include Survey::Fields::ProductsServicesRisk
  include Survey::Fields::DistributionRisk
  include Survey::Fields::Controls
  include Survey::Fields::Signatories

  attr_reader :organization, :year
  # ... rest of class
end
```

**Step 4: Run tests to verify nothing broke**

Run: `bin/rails test test/models/survey_test.rb -v`
Expected: PASS (all existing tests still pass)

**Step 5: Commit**

```bash
git add app/models/survey.rb app/models/survey/fields/
git commit -m "feat: add Survey::Fields module structure for 5 tabs"
```

---

## Task 6: Add First Field Method (total_clients)

**Files:**
- Modify: `app/models/survey/fields/customer_risk.rb`
- Create: `test/models/survey/fields/customer_risk_test.rb`

**Step 1: Write the failing test**

```ruby
# test/models/survey/fields/customer_risk_test.rb
require "test_helper"

class Survey::Fields::CustomerRiskTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @survey = Survey.new(organization: @organization, year: 2025)
  end

  test "total_clients returns count of organization clients" do
    # Create some test clients
    3.times { @organization.clients.create!(name: "Test Client #{_1}", client_type: "PP") }

    result = @survey.send(:total_clients)

    assert_equal 3, result
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey/fields/customer_risk_test.rb -v`
Expected: FAIL with "undefined method `total_clients'"

**Step 3: Write minimal implementation**

```ruby
# app/models/survey/fields/customer_risk.rb
module Survey
  module Fields
    module CustomerRisk
      extend ActiveSupport::Concern

      private

      def total_clients
        organization.clients.count
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/survey/fields/customer_risk_test.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/survey/fields/customer_risk.rb test/models/survey/fields/customer_risk_test.rb
git commit -m "feat: add total_clients field method"
```

---

## Task 7: Add Completeness Test

**Files:**
- Create: `test/models/survey_completeness_test.rb`

**Step 1: Write the test**

```ruby
# test/models/survey_completeness_test.rb
require "test_helper"

class SurveyCompletenessTest < ActiveSupport::TestCase
  test "Survey implements all prefillable/computed questionnaire fields" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
    survey = Survey.new(organization: organizations(:one), year: 2025)

    # Only check prefillable and computed fields - entry_only fields have no method
    calculable_fields = questionnaire.prefillable_fields + questionnaire.computed_fields

    missing = calculable_fields.map(&:name).reject do |name|
      survey.respond_to?(name, true)
    end

    assert missing.empty?, "Survey missing implementations for: #{missing.join(', ')}"
  end

  test "Survey has no orphan field methods" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
    gem_fields = questionnaire.fields.map(&:name).to_set

    field_modules = [
      Survey::Fields::CustomerRisk,
      Survey::Fields::ProductsServicesRisk,
      Survey::Fields::DistributionRisk,
      Survey::Fields::Controls,
      Survey::Fields::Signatories
    ]

    survey_methods = field_modules.flat_map { |m| m.private_instance_methods(false) }.to_set

    orphans = survey_methods - gem_fields

    assert orphans.empty?, "Survey has orphan methods: #{orphans.to_a.join(', ')}"
  end
end
```

**Step 2: Run test**

Run: `bin/rails test test/models/survey_completeness_test.rb -v`
Expected: First test may fail (listing missing fields), second test should pass

**Step 3: Commit**

```bash
git add test/models/survey_completeness_test.rb
git commit -m "test: add Survey completeness and orphan detection tests"
```

---

## Task 8: Migrate Calculations from CalculationEngine

**Files:**
- Modify: `app/models/survey/fields/customer_risk.rb`
- Modify: `app/models/survey/fields/products_services_risk.rb`
- Modify: `app/models/survey/fields/controls.rb`
- Reference: `app/services/calculation_engine.rb` (for logic, don't modify)

**Step 1: Identify fields to migrate from CalculationEngine**

Review `app/services/calculation_engine.rb` and map XBRL codes to semantic names using `semantic_mappings.yml`:

| XBRL Code | Semantic Name | Module |
|-----------|---------------|--------|
| a1101 | total_clients | CustomerRisk |
| a1102 | clients_nationals | CustomerRisk |
| a1401 | (check mapping) | CustomerRisk |
| a2102B | (check mapping) | ProductsServicesRisk |
| a3102 | (check mapping) | Controls |

**Step 2: Add field methods one by one**

For each field, follow the TDD cycle:
1. Write failing test
2. Add method
3. Verify pass
4. Commit

Example for `clients_nationals`:

```ruby
# test/models/survey/fields/customer_risk_test.rb
test "clients_nationals returns count of natural person clients" do
  @organization.clients.create!(name: "Natural", client_type: "PP")
  @organization.clients.create!(name: "Legal", client_type: "PM")

  result = @survey.send(:clients_nationals)

  assert_equal 1, result
end
```

```ruby
# app/models/survey/fields/customer_risk.rb
def clients_nationals
  organization.clients.natural_persons.count
end
```

**Step 3: Repeat for all calculated fields**

Continue until the completeness test passes for all prefillable/computed fields.

**Step 4: Final commit**

```bash
git add app/models/survey/fields/ test/models/survey/fields/
git commit -m "feat: migrate all calculated fields from CalculationEngine"
```

---

## Task 9: Integration Test - Full XBRL Generation

**Files:**
- Create: `test/integration/survey_xbrl_generation_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/survey_xbrl_generation_test.rb
require "test_helper"

class SurveyXbrlGenerationTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
    # Create test data
    3.times { @organization.clients.create!(name: "Client #{_1}", client_type: "PP") }
  end

  test "generates valid XBRL with populated fields" do
    survey = Survey.new(organization: @organization, year: 2025)

    xbrl = survey.to_xbrl

    # Verify structure
    assert_includes xbrl, '<?xml version="1.0"'
    assert_includes xbrl, "xbrli:xbrl"

    # Verify entity
    assert_includes xbrl, @organization.rci_number

    # Verify calculated values appear
    assert_includes xbrl, ">3<"  # total_clients = 3
  end

  test "validation returns meaningful errors for incomplete submission" do
    survey = Survey.new(organization: @organization, year: 2025)

    refute survey.valid?
    assert survey.errors.any?
  end
end
```

**Step 2: Run integration test**

Run: `bin/rails test test/integration/survey_xbrl_generation_test.rb -v`
Expected: PASS

**Step 3: Commit**

```bash
git add test/integration/survey_xbrl_generation_test.rb
git commit -m "test: add integration test for Survey XBRL generation"
```

---

## Task 10: Update Design Doc and Clean Up

**Files:**
- Modify: `docs/plans/2026-01-23-survey-abstraction-design.md`

**Step 1: Update design doc with implementation notes**

Add a "## Implementation Status" section documenting what was built.

**Step 2: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass

**Step 3: Run RuboCop**

Run: `bin/rubocop app/models/survey.rb app/models/survey/ test/models/survey*`
Expected: No violations (fix any that appear)

**Step 4: Final commit**

```bash
git add docs/plans/2026-01-23-survey-abstraction-design.md
git commit -m "docs: update design doc with implementation status"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Survey PORO skeleton | `survey.rb`, `survey_test.rb` |
| 2 | build_submission method | `survey.rb` |
| 3 | to_xbrl method | `survey.rb` |
| 4 | valid? and errors methods | `survey.rb` |
| 5 | Fields module structure | 5 concern files |
| 6 | First field method | `customer_risk.rb` |
| 7 | Completeness test | `survey_completeness_test.rb` |
| 8 | Migrate all calculations | All field modules |
| 9 | Integration test | `survey_xbrl_generation_test.rb` |
| 10 | Clean up | Design doc, RuboCop |

**Note:** Task 8 is the largest - it involves migrating ~30 calculated fields from CalculationEngine. Each field follows the same TDD pattern: write test, implement, verify, commit.
