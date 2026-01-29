# Simplify Submission Answers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the overengineered SubmissionValue model with a simple Answer model that stores only user-provided manual answers.

**Architecture:** The Survey PORO calculates values from CRM data. The Answer model stores only manual user input. At export time, merge calculated values with manual answers. This follows Option C: fresh calculations + manual overlay.

**Tech Stack:** Rails 8, PostgreSQL, Minitest

---

## Task 1: Create Answer Model and Migration

**Files:**
- Create: `db/migrate/YYYYMMDDHHMMSS_create_answers.rb`
- Create: `app/models/answer.rb`
- Create: `test/models/answer_test.rb`
- Create: `test/fixtures/answers.yml`

**Step 1: Write the failing test**

Create `test/models/answer_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  setup do
    @submission = submissions(:draft_submission)
  end

  test "valid with required attributes" do
    answer = Answer.new(
      submission: @submission,
      xbrl_id: "a14001",
      value: "Some explanation"
    )
    assert answer.valid?
  end

  test "requires submission" do
    answer = Answer.new(xbrl_id: "a14001", value: "test")
    assert_not answer.valid?
    assert_includes answer.errors[:submission], "must exist"
  end

  test "requires xbrl_id" do
    answer = Answer.new(submission: @submission, value: "test")
    assert_not answer.valid?
    assert_includes answer.errors[:xbrl_id], "can't be blank"
  end

  test "xbrl_id must be unique per submission" do
    Answer.create!(submission: @submission, xbrl_id: "a14001", value: "first")

    duplicate = Answer.new(submission: @submission, xbrl_id: "a14001", value: "second")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:xbrl_id], "has already been taken"
  end

  test "same xbrl_id allowed for different submissions" do
    other_submission = submissions(:another_submission)
    Answer.create!(submission: @submission, xbrl_id: "a14001", value: "first")

    answer = Answer.new(submission: other_submission, xbrl_id: "a14001", value: "second")
    assert answer.valid?
  end

  test "value can be blank" do
    answer = Answer.new(submission: @submission, xbrl_id: "a14001", value: nil)
    assert answer.valid?
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/answer_test.rb`
Expected: FAIL with "uninitialized constant Answer"

**Step 3: Generate migration**

Run: `bin/rails generate migration CreateAnswers submission:references xbrl_id:string value:text`

Then edit the migration:

```ruby
# frozen_string_literal: true

class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :xbrl_id, null: false
      t.text :value

      t.timestamps
    end

    add_index :answers, [:submission_id, :xbrl_id], unique: true
  end
end
```

**Step 4: Run migration**

Run: `bin/rails db:migrate`

**Step 5: Create Answer model**

Create `app/models/answer.rb`:

```ruby
# frozen_string_literal: true

class Answer < ApplicationRecord
  belongs_to :submission

  validates :xbrl_id, presence: true
  validates :xbrl_id, uniqueness: { scope: :submission_id }
end
```

**Step 6: Create fixtures**

Create `test/fixtures/answers.yml`:

```yaml
# Manual answer for draft submission
manual_comment:
  submission: draft_submission
  xbrl_id: "a14001"
  value: "Test comment for section"

another_answer:
  submission: draft_submission
  xbrl_id: "air2392"
  value: "5"
```

**Step 7: Run tests to verify they pass**

Run: `bin/rails test test/models/answer_test.rb`
Expected: PASS (all 6 tests)

**Step 8: Commit**

```bash
git add db/migrate/*_create_answers.rb app/models/answer.rb test/models/answer_test.rb test/fixtures/answers.yml
git commit -m "$(cat <<'EOF'
feat: add simple Answer model for manual survey answers

Stores only user-provided values. Survey PORO handles calculations.
At export time, merge calculated + manual answers.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add answers association to Submission

**Files:**
- Modify: `app/models/submission.rb`
- Modify: `test/models/submission_test.rb`

**Step 1: Write the failing test**

Add to `test/models/submission_test.rb`:

```ruby
test "has many answers" do
  submission = Submission.create!(organization: @organization, year: 2040)
  assert_respond_to submission, :answers
end

test "destroys answers when destroyed" do
  submission = submissions(:draft_submission)
  Answer.create!(submission: submission, xbrl_id: "test_destroy", value: "test")
  answer_count = submission.answers.count
  assert answer_count > 0, "Test requires submission with answers"

  assert_difference "Answer.count", -answer_count do
    submission.destroy
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/submission_test.rb -n "/answers/"`
Expected: FAIL with "undefined method `answers'"

**Step 3: Add association to Submission model**

Edit `app/models/submission.rb`, add after `has_many :submission_values`:

```ruby
has_many :answers, dependent: :destroy
```

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/models/submission_test.rb -n "/answers/"`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/submission.rb test/models/submission_test.rb
git commit -m "$(cat <<'EOF'
feat: add answers association to Submission

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add to_hash method to Survey PORO

**Files:**
- Modify: `app/models/survey.rb`
- Create: `test/models/survey_to_hash_test.rb`

**Step 1: Write the failing test**

Create `test/models/survey_to_hash_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class SurveyToHashTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @survey = Survey.new(organization: @organization, year: 2024)
  end

  test "to_hash returns hash of field_id to value" do
    result = @survey.to_hash

    assert_kind_of Hash, result
    assert result.key?("a1101"), "Expected hash to include a1101 (total clients)"
  end

  test "to_hash values are strings or numbers" do
    result = @survey.to_hash

    result.each do |key, value|
      assert [String, Integer, Float, BigDecimal, NilClass].any? { |t| value.is_a?(t) },
        "Expected #{key} value to be string/number, got #{value.class}"
    end
  end

  test "to_hash includes calculated values" do
    # a1101 is total clients - should be calculated from organization.clients.count
    result = @survey.to_hash

    expected_count = @organization.clients.count
    assert_equal expected_count, result["a1101"]
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey_to_hash_test.rb`
Expected: FAIL with "undefined method `to_hash'"

**Step 3: Add to_hash method to Survey**

Edit `app/models/survey.rb`, add as public method after `errors`:

```ruby
def to_hash
  result = {}
  questionnaire.fields.each do |field|
    field_id = field.id.downcase
    method_name = field_id.to_sym
    next unless respond_to?(method_name, true)

    value = send(method_name)
    result[field_id] = value
  end
  result
end
```

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/models/survey_to_hash_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/survey.rb test/models/survey_to_hash_test.rb
git commit -m "$(cat <<'EOF'
feat: add to_hash method to Survey PORO

Returns all calculated field values as a hash for merging with manual answers.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add merged_answers method to Submission

**Files:**
- Modify: `app/models/submission.rb`
- Modify: `test/models/submission_test.rb`

**Step 1: Write the failing test**

Add to `test/models/submission_test.rb`:

```ruby
test "merged_answers combines calculated and manual values" do
  submission = Submission.create!(organization: @organization, year: 2041)

  # Add a manual answer that overrides calculated value
  Answer.create!(submission: submission, xbrl_id: "a14001", value: "manual comment")

  result = submission.merged_answers

  # Should include calculated value
  assert result.key?("a1101"), "Expected calculated a1101"

  # Should include manual override
  assert_equal "manual comment", result["a14001"]
end

test "manual answers override calculated values" do
  submission = Submission.create!(organization: @organization, year: 2042)

  # Override a calculated field
  Answer.create!(submission: submission, xbrl_id: "a1101", value: "999")

  result = submission.merged_answers

  # Manual value should win
  assert_equal "999", result["a1101"]
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/submission_test.rb -n "/merged_answers/"`
Expected: FAIL with "undefined method `merged_answers'"

**Step 3: Add merged_answers method**

Edit `app/models/submission.rb`, add as public method:

```ruby
def merged_answers
  survey = Survey.new(organization: organization, year: year)
  calculated = survey.to_hash
  manual = answers.pluck(:xbrl_id, :value).to_h
  calculated.merge(manual)
end
```

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/models/submission_test.rb -n "/merged_answers/"`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/submission.rb test/models/submission_test.rb
git commit -m "$(cat <<'EOF'
feat: add merged_answers method to Submission

Combines fresh Survey calculations with manual user answers.
Manual answers override calculated values.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Remove SubmissionValue model and cleanup

**Files:**
- Delete: `app/models/submission_value.rb`
- Delete: `test/models/submission_value_test.rb`
- Delete: `test/fixtures/submission_values.yml`
- Modify: `app/models/submission.rb` (remove association)
- Create: `db/migrate/YYYYMMDDHHMMSS_drop_submission_values.rb`

**Step 1: Remove association from Submission**

Edit `app/models/submission.rb`, remove these lines:

```ruby
has_many :submission_values, dependent: :destroy
accepts_nested_attributes_for :submission_values
```

**Step 2: Remove tests that reference submission_values**

Edit `test/models/submission_test.rb`, remove these tests:

```ruby
test "has many submission_values" do
  submission = Submission.create!(organization: @organization, year: 2025)
  assert_respond_to submission, :submission_values
end

test "destroys submission_values when destroyed" do
  submission = submissions(:draft_submission)
  submission_value_count = submission.submission_values.count
  assert submission_value_count > 0, "Test requires submission with values"

  assert_difference "SubmissionValue.count", -submission_value_count do
    submission.destroy
  end
end
```

**Step 3: Delete SubmissionValue files**

Run:
```bash
rm app/models/submission_value.rb
rm test/models/submission_value_test.rb
rm test/fixtures/submission_values.yml
```

**Step 4: Create drop table migration**

Run: `bin/rails generate migration DropSubmissionValues`

Edit the migration:

```ruby
# frozen_string_literal: true

class DropSubmissionValues < ActiveRecord::Migration[8.0]
  def up
    drop_table :submission_values
  end

  def down
    create_table :submission_values do |t|
      t.datetime :confirmed_at
      t.string :element_name, null: false
      t.jsonb :metadata, default: {}
      t.boolean :overridden, default: false
      t.text :override_reason
      t.bigint :override_user_id
      t.string :previous_year_value
      t.string :source, null: false
      t.references :submission, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end

    add_index :submission_values, [:submission_id, :element_name], unique: true
    add_index :submission_values, :metadata, using: :gin
    add_index :submission_values, :override_user_id
    add_index :submission_values, [:submission_id, :source, :confirmed_at], name: "index_submission_values_on_source_confirmation"
    add_foreign_key :submission_values, :users, column: :override_user_id, on_delete: :nullify
  end
end
```

**Step 5: Run migration**

Run: `bin/rails db:migrate`

**Step 6: Run all submission tests**

Run: `bin/rails test test/models/submission_test.rb test/models/answer_test.rb`
Expected: PASS

**Step 7: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor: remove SubmissionValue model

YAGNI - the overengineered model with override tracking, confirmation,
YoY comparison etc. is replaced by simple Answer model.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Simplify Submission model

**Files:**
- Modify: `app/models/submission.rb`
- Modify: `test/models/submission_test.rb`
- Create: `db/migrate/YYYYMMDDHHMMSS_simplify_submissions.rb`

**Step 1: Create migration to remove unused columns**

Run: `bin/rails generate migration SimplifySubmissions`

Edit the migration:

```ruby
# frozen_string_literal: true

class SimplifySubmissions < ActiveRecord::Migration[8.0]
  def change
    remove_column :submissions, :current_step, :integer, default: 1
    remove_column :submissions, :downloaded_unvalidated, :boolean, default: false
    remove_column :submissions, :generated_at, :datetime
    remove_column :submissions, :locked_at, :datetime
    remove_column :submissions, :locked_by_user_id, :bigint
    remove_column :submissions, :reopened_count, :integer, default: 0, null: false
    remove_column :submissions, :signatory_name, :string
    remove_column :submissions, :signatory_title, :string

    remove_index :submissions, name: "index_submissions_on_locked_at", if_exists: true
    remove_index :submissions, name: "index_submissions_on_lock_status", if_exists: true
    remove_index :submissions, name: "index_submissions_on_locked_by_user_id", if_exists: true
  end
end
```

**Step 2: Run migration**

Run: `bin/rails db:migrate`

**Step 3: Simplify Submission model**

Replace `app/models/submission.rb` with:

```ruby
# frozen_string_literal: true

class Submission < ApplicationRecord
  include Auditable

  belongs_to :organization
  has_many :answers, dependent: :destroy

  validates :year, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 2009, less_than_or_equal_to: 2099 }
  validates :year, uniqueness: { scope: :organization_id }
  validates :status, presence: true, inclusion: { in: %w[draft completed] }

  before_validation :set_defaults, on: :create

  scope :drafts, -> { where(status: "draft") }
  scope :completed_submissions, -> { where(status: "completed") }
  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_year, ->(year) { where(year: year) }
  scope :recent_first, -> { order(year: :desc) }

  def draft?
    status == "draft"
  end

  def completed?
    status == "completed"
  end

  def complete!
    update!(status: "completed", completed_at: Time.current)
  end

  def report_date
    Date.new(year, 12, 31)
  end

  def merged_answers
    survey = Survey.new(organization: organization, year: year)
    calculated = survey.to_hash
    manual = answers.pluck(:xbrl_id, :value).to_h
    calculated.merge(manual)
  end

  def status_badge_class
    case status
    when "draft" then "bg-gray-100 text-gray-800"
    when "completed" then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def status_label
    status.humanize
  end

  private

  def set_defaults
    self.status ||= "draft"
    self.taxonomy_version ||= "2025"
    self.started_at ||= Time.current
  end
end
```

**Step 4: Simplify Submission tests**

Replace `test/models/submission_test.rb` with simplified version (remove locking, reopen, generate, state machine tests for removed states):

```ruby
# frozen_string_literal: true

require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid submission with required attributes" do
    submission = Submission.new(organization: @organization, year: 2050)
    assert submission.valid?
  end

  test "requires year" do
    submission = Submission.new(organization: @organization)
    assert_not submission.valid?
    assert_includes submission.errors[:year], "can't be blank"
  end

  test "requires organization" do
    submission = Submission.new(year: 2050)
    assert_not submission.valid?
    assert_includes submission.errors[:organization], "must exist"
  end

  test "year must be within reasonable range" do
    submission = Submission.new(organization: @organization, year: 2008)
    assert_not submission.valid?

    submission = Submission.new(organization: @organization, year: 2100)
    assert_not submission.valid?
  end

  test "year must be unique per organization" do
    Submission.create!(organization: @organization, year: 2051)

    duplicate = Submission.new(organization: @organization, year: 2051)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:year], "has already been taken"
  end

  # === Status ===

  test "status defaults to draft" do
    submission = Submission.new(organization: @organization, year: 2052)
    assert_equal "draft", submission.status
  end

  test "draft? and completed? predicates" do
    draft = Submission.new(status: "draft")
    completed = Submission.new(status: "completed")

    assert draft.draft?
    assert_not draft.completed?
    assert completed.completed?
    assert_not completed.draft?
  end

  test "complete! transitions to completed" do
    submission = Submission.create!(organization: @organization, year: 2053)

    submission.complete!

    assert submission.completed?
    assert_not_nil submission.completed_at
  end

  # === Associations ===

  test "has many answers" do
    submission = Submission.create!(organization: @organization, year: 2054)
    assert_respond_to submission, :answers
  end

  test "destroys answers when destroyed" do
    submission = Submission.create!(organization: @organization, year: 2055)
    Answer.create!(submission: submission, xbrl_id: "test", value: "test")

    assert_difference "Answer.count", -1 do
      submission.destroy
    end
  end

  # === merged_answers ===

  test "merged_answers combines calculated and manual values" do
    submission = Submission.create!(organization: @organization, year: 2056)
    Answer.create!(submission: submission, xbrl_id: "a14001", value: "manual")

    result = submission.merged_answers

    assert result.key?("a1101")
    assert_equal "manual", result["a14001"]
  end

  test "manual answers override calculated values" do
    submission = Submission.create!(organization: @organization, year: 2057)
    Answer.create!(submission: submission, xbrl_id: "a1101", value: "999")

    result = submission.merged_answers

    assert_equal "999", result["a1101"]
  end

  # === Helpers ===

  test "report_date returns end of year" do
    submission = Submission.new(year: 2025)
    assert_equal Date.new(2025, 12, 31), submission.report_date
  end

  # === Auditable ===

  test "creates audit log on create" do
    assert_difference "AuditLog.count", 1 do
      Submission.create!(organization: @organization, year: 2058)
    end
  end
end
```

**Step 5: Update fixtures**

Edit `test/fixtures/submissions.yml` to remove references to removed columns:

```yaml
draft_submission:
  organization: one
  year: 2024
  taxonomy_version: "2025"
  status: "draft"
  started_at: <%= 1.hour.ago %>

another_submission:
  organization: one
  year: 2023
  taxonomy_version: "2025"
  status: "completed"
  started_at: <%= 1.year.ago %>
  completed_at: <%= 1.year.ago + 2.hours %>

completed_submission:
  organization: one
  year: 2020
  taxonomy_version: "2025"
  status: "completed"
  started_at: <%= 4.years.ago %>
  completed_at: <%= 4.years.ago + 2.days %>

other_org_submission:
  organization: two
  year: 2024
  taxonomy_version: "2025"
  status: "draft"
  started_at: <%= 1.day.ago %>

compliance_test_submission:
  organization: compliance_test_org
  year: <%= Date.current.year %>
  taxonomy_version: "2025"
  status: "draft"
  started_at: <%= 1.hour.ago %>
```

**Step 6: Run all tests**

Run: `bin/rails test test/models/submission_test.rb test/models/answer_test.rb`
Expected: PASS

**Step 7: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor: simplify Submission model

Remove unused columns: current_step, downloaded_unvalidated, generated_at,
locked_at, locked_by_user_id, reopened_count, signatory_name, signatory_title.

Remove unused statuses: in_review, validated.
Remove locking, reopen, generate methods.

Keep it simple: draft -> completed.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Remove AmsfConstants dependency from Submission

**Files:**
- Modify: `app/models/submission.rb`
- Check: `app/models/concerns/amsf_constants.rb` for what can be removed

**Step 1: Check AmsfConstants usage**

Run: `grep -r "AmsfConstants" app/`

**Step 2: Remove include from Submission if not needed**

Edit `app/models/submission.rb`, remove:

```ruby
include AmsfConstants
```

**Step 3: Run tests**

Run: `bin/rails test test/models/submission_test.rb`
Expected: PASS

**Step 4: Commit**

```bash
git add app/models/submission.rb
git commit -m "$(cat <<'EOF'
refactor: remove AmsfConstants from Submission

No longer needed after simplification.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Update views and controllers to use new model

**Files:**
- Modify: `app/views/submissions/show.html.erb`
- Modify: `app/controllers/survey_reviews_controller.rb`
- Modify: `app/views/survey_reviews/show.html.erb`

**Step 1: Update submissions/show.html.erb**

Remove the submission_values table section (lines 63-90). The show page should just show status, not all values.

**Step 2: Update survey_reviews_controller.rb**

Already uses Survey PORO - should work. Verify it still works.

**Step 3: Run system tests**

Run: `bin/rails test test/system/survey_review_test.rb`

Note: These tests may need updates since they reference CalculationEngine and submission_values.

**Step 4: Fix failing tests**

Delete `test/system/survey_review_test.rb` if it's testing deprecated functionality, or update to use new approach.

**Step 5: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor: update views to use simplified submission model

Remove submission_values display from show page.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Remove CalculationEngine if exists

**Files:**
- Check and delete: `app/services/calculation_engine.rb` (if exists)
- Delete related tests

**Step 1: Check if CalculationEngine exists**

Run: `find app -name "*calculation*"`

**Step 2: Delete if found**

The Survey PORO replaces CalculationEngine. Delete if it exists.

**Step 3: Remove references in tests**

Search and remove any references to CalculationEngine in tests.

**Step 4: Run full test suite**

Run: `bin/rails test`

**Step 5: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
refactor: remove CalculationEngine

Survey PORO handles all calculations now.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Delete old submission_values migrations

**Files:**
- Delete: `db/migrate/20251202220329_create_submission_values.rb`
- Delete: `db/migrate/20251204133814_add_override_tracking_to_submission_values.rb`
- Delete: `db/migrate/20251204155027_add_source_confirmed_index_to_submission_values.rb`
- Delete: `db/migrate/20251205231728_add_metadata_to_submission_values.rb`
- Delete: `db/migrate/20251207195332_add_gin_index_to_submission_values_metadata.rb`

**Step 1: Delete old migrations**

```bash
rm db/migrate/20251202220329_create_submission_values.rb
rm db/migrate/20251204133814_add_override_tracking_to_submission_values.rb
rm db/migrate/20251204155027_add_source_confirmed_index_to_submission_values.rb
rm db/migrate/20251205231728_add_metadata_to_submission_values.rb
rm db/migrate/20251207195332_add_gin_index_to_submission_values_metadata.rb
```

**Step 2: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: delete old submission_values migrations

Table has been dropped, migrations no longer needed.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Final cleanup and verification

**Step 1: Run full test suite**

Run: `bin/rails test`

**Step 2: Run rubocop**

Run: `bin/rubocop -a`

**Step 3: Verify database schema**

Run: `bin/rails db:schema:dump`

Verify `db/schema.rb` has:
- `answers` table with submission_id, xbrl_id, value
- `submissions` table without the removed columns
- No `submission_values` table

**Step 4: Final commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: final cleanup after submission simplification

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```
