# AMSF Survey Review Redesign

> **For Claude:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current 7-step submission wizard with a single-page survey review that displays all elements with search/filter capabilities.

**Architecture:** Single scrollable page organized by AMSF questionnaire sections. Elements are defined in `Xbrl::Survey` module. Client-side filtering via Stimulus controller.

**Tech Stack:** Rails 8, Hotwire (Turbo/Stimulus), TailwindCSS, existing Xbrl::Taxonomy and ElementManifest

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Structure module | `Xbrl::Survey` (not tabs) | Single page doesn't need tab navigation |
| Element data | Delegate to `ElementManifest` | Reuse existing abstraction, DRY |
| Filtering | Stimulus (client-side) | 300 elements already on page, instant UX |
| Collapse behavior | None - all expanded | Critical survey, users review everything |
| Editing | Read-only for MVP | Simplify, add later if needed |
| Lock/unlock | Removed for MVP | Small team, conflicts rare |
| CalculationEngine | Keep for now | Lambda refactor is separate effort |

---

## Phase 1: Data Structure

### Task 1: Create Survey Module

**Files:**
- Create: `app/models/xbrl/survey.rb`
- Create: `test/models/xbrl/survey_test.rb`

**Step 1: Write the failing test**

```ruby
# test/models/xbrl/survey_test.rb
# frozen_string_literal: true

require "test_helper"

class Xbrl::SurveyTest < ActiveSupport::TestCase
  test "SECTIONS returns all AMSF sections in order" do
    sections = Xbrl::Survey::SECTIONS

    assert sections.length.positive?
    assert_equal "1.1", sections.first[:id]
  end

  test "section returns section definition by id" do
    section = Xbrl::Survey.section("1.1")

    assert_equal "Active in Reporting Cycle", section[:name]
    assert_kind_of Array, section[:elements]
    assert section[:elements].any?
  end

  test "section returns nil for unknown section" do
    assert_nil Xbrl::Survey.section("99.99")
  end

  test "elements_for_section returns element names" do
    elements = Xbrl::Survey.elements_for_section("1.1")

    assert_kind_of Array, elements
    assert elements.include?("a1001")
  end

  test "all_element_names returns flat array of all elements" do
    names = Xbrl::Survey.all_element_names

    assert_kind_of Array, names
    assert names.include?("a1101")
  end

  test "section_for_element returns correct section" do
    section = Xbrl::Survey.section_for_element("a1101")

    assert section.present?
    assert_equal "1.2", section[:id]
  end

  test "section_for_element returns nil for unknown element" do
    assert_nil Xbrl::Survey.section_for_element("unknown_element")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/xbrl/survey_test.rb -v`
Expected: FAIL with "uninitialized constant Xbrl::Survey"

**Step 3: Write minimal implementation**

```ruby
# app/models/xbrl/survey.rb
# frozen_string_literal: true

module Xbrl
  # Survey defines the AMSF questionnaire structure for UI organization.
  # Maps XBRL elements to their questionnaire sections.
  #
  # This is separate from the Taxonomy presentation linkbase because
  # the AMSF questionnaire structure is not encoded in the XBRL files.
  #
  # Usage:
  #   Xbrl::Survey.sections                    # => All sections
  #   Xbrl::Survey.section("1.2")              # => Section definition
  #   Xbrl::Survey.elements_for_section("1.2") # => ["a1101", "a1102", ...]
  #   Xbrl::Survey.section_for_element("a1101") # => Section containing element
  #
  module Survey
    # TODO: Populate with actual AMSF questionnaire structure
    # These section IDs and element assignments should match the official
    # AMSF questionnaire PDF structure.
    SECTIONS = [
      { id: "1.1", name: "Active in Reporting Cycle", elements: %w[a1001] },
      { id: "1.2", name: "Client Summary", elements: %w[a1101 a1102 a11502B a11802B] },
      { id: "1.3", name: "Client Nationality", elements: %w[a1103] },
      { id: "1.4", name: "Beneficial Owners", elements: %w[a1204O a1501 a1502B] },
      { id: "1.5", name: "PEP Clients", elements: %w[a12002B a12102B a12202B] },
      { id: "1.6", name: "High Risk Clients", elements: %w[a1401] },
      { id: "1.7", name: "Due Diligence Levels", elements: %w[a1203 a1203D] },
      { id: "1.8", name: "Source of Funds", elements: %w[a1204S a14001] },
      { id: "1.9", name: "Professional Categories", elements: %w[a11301 a11302] },
      { id: "1.10", name: "Managed Properties", elements: %w[aACTIVEPS a1802TOLA a1802TOLA_NP a1802TOLA_LE a1802PEP] },
      { id: "2.1", name: "Transaction Activity", elements: %w[a2101B] },
      { id: "2.2", name: "Purchase Transactions", elements: %w[a2102B a2102BB] },
      { id: "2.3", name: "Sale Transactions", elements: %w[a2104B a2105B a2105BB] },
      { id: "2.4", name: "Rental Transactions", elements: %w[a2107B a2108B a2109B] },
      { id: "2.5", name: "Cash Payments", elements: %w[a2202 a2203] },
      { id: "2.6", name: "Cryptocurrency", elements: %w[a2501A] },
      { id: "2.7", name: "Revenue", elements: %w[a381 a3802 a3803 a3804] },
      { id: "3.1", name: "STR Activity", elements: %w[a3101 a3102] },
      { id: "3.2", name: "Training", elements: %w[a3201 a3202 a3203 a3303] },
      { id: "4.1", name: "AML/CFT Policies", elements: %w[aC1101Z aC1102 aC1103 aC1104 aC1105] },
      { id: "4.2", name: "Governance", elements: %w[aC1201 aC1202 aC1203 aC1204 aC1205] },
      { id: "4.3", name: "Customer Due Diligence", elements: %w[aC1301 aC1302 aC1303 aC1304 aC1305] },
      { id: "4.4", name: "Enhanced Due Diligence", elements: %w[aC1401 aC1402 aC1403 aC1404 aC1405] },
      { id: "4.5", name: "Risk Assessment", elements: %w[aC1501 aC1502 aC1503 aC1504 aC1505] },
      { id: "5.1", name: "Declaration", elements: %w[aS1 aS2] }
    ].freeze

    class << self
      def sections
        SECTIONS
      end

      def section(id)
        SECTIONS.find { |s| s[:id] == id }
      end

      def elements_for_section(id)
        section(id)&.dig(:elements) || []
      end

      def all_element_names
        SECTIONS.flat_map { |s| s[:elements] }
      end

      def section_for_element(element_name)
        SECTIONS.find { |s| s[:elements].include?(element_name) }
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/xbrl/survey_test.rb -v`
Expected: PASS

---

### Task 2: Add Boot-time Validation

**Files:**
- Modify: `config/initializers/xbrl_taxonomy.rb`

**Step 1: Add validation after taxonomy loads**

```ruby
# Add to config/initializers/xbrl_taxonomy.rb after Xbrl::Taxonomy.load!

# Validate Survey references match Taxonomy
Rails.application.config.after_initialize do
  next unless Xbrl::Taxonomy.loaded?

  taxonomy_elements = Xbrl::Taxonomy.elements.map(&:name)
  survey_elements = Xbrl::Survey.all_element_names
  missing = survey_elements - taxonomy_elements

  if missing.any?
    raise "Xbrl::Survey references elements not in Taxonomy: #{missing.join(', ')}"
  end

  Rails.logger.info "[XBRL] Survey structure validated: #{survey_elements.count} elements across #{Xbrl::Survey.sections.count} sections"
end
```

**Step 2: Verify app boots without error**

Run: `bin/rails runner "puts 'Boot OK'"`
Expected: "Boot OK" (no exception)

---

## Phase 2: Model Updates

### Task 3: Add needs_review? to SubmissionValue

**Files:**
- Modify: `app/models/submission_value.rb`
- Add tests to: `test/models/submission_value_test.rb`

**Step 1: Write the failing test**

```ruby
# Add to test/models/submission_value_test.rb

test "needs_review? returns true when flagged_for_review is set" do
  sv = submission_values(:acme_2024_a1101)
  sv.update!(metadata: { "flagged_for_review" => true })

  assert sv.needs_review?
end

test "needs_review? returns false for normal values" do
  sv = submission_values(:acme_2024_a1101)
  sv.update!(metadata: {})

  assert_not sv.needs_review?
end

test "needs_review? returns false when metadata is nil" do
  sv = submission_values(:acme_2024_a1101)
  sv.update!(metadata: nil)

  assert_not sv.needs_review?
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/submission_value_test.rb -v -n /needs_review/`
Expected: FAIL

**Step 3: Write minimal implementation**

```ruby
# Add to app/models/submission_value.rb

def needs_review?
  metadata&.dig("flagged_for_review") || false
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/submission_value_test.rb -v -n /needs_review/`
Expected: PASS

---

### Task 4: Add needs_review to ElementValue

**Files:**
- Modify: `app/models/xbrl/element_manifest.rb`
- Add tests to: `test/models/xbrl/element_manifest_test.rb`

**Step 1: Write the failing test**

```ruby
# Add to test/models/xbrl/element_manifest_test.rb

test "element_with_value includes needs_review status" do
  submission = submissions(:acme_2024)
  sv = submission.submission_values.find_by(element_name: "a1101")
  sv.update!(metadata: { "flagged_for_review" => true })

  manifest = Xbrl::ElementManifest.new(submission)
  element_value = manifest.element_with_value("a1101")

  assert element_value.needs_review?
end

test "element_with_value returns false for needs_review when not flagged" do
  submission = submissions(:acme_2024)

  manifest = Xbrl::ElementManifest.new(submission)
  element_value = manifest.element_with_value("a1101")

  assert_not element_value.needs_review?
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/xbrl/element_manifest_test.rb -v -n /needs_review/`
Expected: FAIL

**Step 3: Update ElementValue class**

```ruby
# In app/models/xbrl/element_manifest.rb

class ElementValue
  attr_reader :element, :value, :source, :overridden, :confirmed, :needs_review

  def initialize(element:, value:, source:, overridden:, confirmed:, needs_review:)
    @element = element
    @value = value
    @source = source
    @overridden = overridden
    @confirmed = confirmed
    @needs_review = needs_review
  end

  def needs_review?
    !!@needs_review
  end

  # ... rest of existing methods
end
```

**Step 4: Update element_with_value to pass needs_review**

```ruby
# In app/models/xbrl/element_manifest.rb

def element_with_value(element_name)
  element = Taxonomy.element(element_name)
  return nil unless element

  sv = @stored_values[element_name]

  ElementValue.new(
    element: element,
    value: sv&.value,
    source: sv&.source,
    overridden: sv&.overridden?,
    confirmed: sv&.confirmed?,
    needs_review: sv&.needs_review?
  )
end
```

**Step 5: Run test to verify it passes**

Run: `bin/rails test test/models/xbrl/element_manifest_test.rb -v -n /needs_review/`
Expected: PASS

---

## Phase 3: Controller

### Task 5: Create Survey Review Controller

**Files:**
- Create: `app/controllers/survey_reviews_controller.rb`
- Create: `test/controllers/survey_reviews_controller_test.rb`
- Modify: `config/routes.rb`

**Step 1: Write the failing test**

```ruby
# test/controllers/survey_reviews_controller_test.rb
# frozen_string_literal: true

require "test_helper"

class SurveyReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @submission = submissions(:acme_2024)
    @user = users(:acme_admin)
    sign_in @user
  end

  test "show displays survey review page" do
    get submission_review_path(@submission)

    assert_response :success
    assert_select "h1", /Survey Review/
  end

  test "show populates submission values if empty" do
    @submission.submission_values.destroy_all

    get submission_review_path(@submission)

    assert_response :success
    assert @submission.submission_values.reload.any?
  end

  test "show requires authentication" do
    sign_out @user

    get submission_review_path(@submission)

    assert_response :redirect
  end

  test "complete marks submission as completed" do
    post complete_submission_review_path(@submission)

    assert_response :redirect
    assert @submission.reload.completed?
  end
end
```

**Step 2: Add route**

```ruby
# In config/routes.rb, inside resources :submissions block

resources :submissions do
  resource :review, only: [:show], controller: "survey_reviews" do
    post :complete
  end
end
```

**Step 3: Write controller**

```ruby
# app/controllers/survey_reviews_controller.rb
# frozen_string_literal: true

class SurveyReviewsController < ApplicationController
  include OrganizationScoped

  before_action :set_submission

  def show
    authorize @submission, :show?

    populate_values_if_needed

    @manifest = Xbrl::ElementManifest.new(@submission)
    @sections = build_sections
  end

  def complete
    authorize @submission, :complete?

    if @submission.may_complete?
      @submission.complete!
      redirect_to @submission, notice: "Submission completed successfully.", status: :see_other
    else
      redirect_to submission_review_path(@submission),
        alert: "Cannot complete submission in current state.", status: :see_other
    end
  end

  private

  def set_submission
    @submission = policy_scope(Submission).find_by(id: params[:submission_id])
    render_not_found unless @submission
  end

  def populate_values_if_needed
    return if @submission.submission_values.any?

    CalculationEngine.new(@submission).populate_submission_values!
  end

  def build_sections
    Xbrl::Survey.sections.map do |section|
      elements = section[:elements].filter_map do |name|
        @manifest.element_with_value(name)
      end

      section.merge(
        elements: elements,
        has_issues: elements.any?(&:needs_review?)
      )
    end
  end
end
```

**Step 4: Run tests**

Run: `bin/rails test test/controllers/survey_reviews_controller_test.rb -v`
Expected: PASS

---

## Phase 4: Views

### Task 6: Create Survey Review View

**Files:**
- Create: `app/views/survey_reviews/show.html.erb`

```erb
<%# app/views/survey_reviews/show.html.erb %>

<%= content_for :title, "Survey Review - #{@submission.year}" %>

<div class="container mx-auto px-4 py-8" data-controller="survey-filter">
  <div class="max-w-4xl mx-auto">
    <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
      AMSF Survey Review
    </h1>
    <p class="text-gray-600 dark:text-gray-300 mb-6">
      Review all calculated values for <%= @submission.year %> before completing the submission.
    </p>

    <%# Filter bar %>
    <div class="sticky top-0 z-10 bg-white dark:bg-gray-900 py-4 mb-6 border-b border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
        <div class="flex-1 w-full sm:w-auto">
          <input type="search"
                 placeholder="Search elements..."
                 class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-800"
                 data-survey-filter-target="search"
                 data-action="input->survey-filter#filter">
        </div>

        <label class="flex items-center gap-2 text-sm">
          <input type="checkbox"
                 class="rounded border-gray-300"
                 data-survey-filter-target="needsReview"
                 data-action="change->survey-filter#filter">
          <span class="text-gray-700 dark:text-gray-300">Needs review only</span>
        </label>

        <span class="text-sm text-gray-500" data-survey-filter-target="count">
          <%= @sections.sum { |s| s[:elements].count } %> elements
        </span>
      </div>
    </div>

    <%# Sections %>
    <div class="space-y-8">
      <% @sections.each do |section| %>
        <% next if section[:elements].empty? %>

        <div data-survey-filter-target="section">
          <h2 class="text-lg font-semibold mb-4 flex items-center gap-2
                     <%= section[:has_issues] ? 'text-amber-600 dark:text-amber-400' : 'text-gray-900 dark:text-white' %>">
            <span><%= section[:id] %> - <%= section[:name] %></span>
            <% if section[:has_issues] %>
              <span class="text-xs bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300 px-2 py-1 rounded">
                Review
              </span>
            <% end %>
          </h2>

          <div class="space-y-2">
            <% section[:elements].each do |element| %>
              <%= render "survey_reviews/element_row", element: element %>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>

    <%# Complete button %>
    <div class="mt-12 pt-6 border-t border-gray-200 dark:border-gray-700">
      <% if @submission.may_complete? %>
        <%= button_to "Complete Submission",
              complete_submission_review_path(@submission),
              method: :post,
              class: "w-full sm:w-auto px-6 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700",
              data: { confirm: "Are you sure you want to complete this submission? This action cannot be undone." } %>
      <% else %>
        <p class="text-gray-500">
          Submission is <%= @submission.status %> and cannot be completed.
        </p>
      <% end %>
    </div>
  </div>
</div>
```

---

### Task 7: Create Element Row Partial

**Files:**
- Create: `app/views/survey_reviews/_element_row.html.erb`

```erb
<%# app/views/survey_reviews/_element_row.html.erb %>

<div data-element-row
     data-searchable-text="<%= element.name %> <%= element.short_label %> <%= element.label_text %>"
     data-needs-review="<%= element.needs_review? %>"
     class="flex items-center justify-between p-3 rounded-lg
            <%= element.needs_review? ? 'bg-amber-50 dark:bg-amber-900/10 ring-1 ring-amber-200 dark:ring-amber-800' : 'bg-gray-50 dark:bg-gray-800/50' %>">

  <div class="flex-1 min-w-0 mr-4">
    <div class="font-medium text-gray-900 dark:text-white">
      <%= element.short_label %>
    </div>
    <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
      <span class="font-mono"><%= element.name %></span>
      <% if element.needs_review? %>
        <span class="ml-2 text-amber-600 dark:text-amber-400">Needs review</span>
      <% end %>
    </div>
  </div>

  <div class="text-right flex-shrink-0">
    <div class="font-medium text-gray-900 dark:text-white">
      <% if element.value.present? %>
        <%= format_html_value(element.value, element.element) %>
      <% else %>
        <span class="text-gray-400">—</span>
      <% end %>
    </div>
    <% if element.source.present? %>
      <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
        <%= element.source.humanize %>
        <%= "• Overridden" if element.overridden? %>
      </div>
    <% end %>
  </div>
</div>
```

---

## Phase 5: Stimulus Controller

### Task 8: Create Survey Filter Controller

**Files:**
- Create: `app/javascript/controllers/survey_filter_controller.js`

```javascript
// app/javascript/controllers/survey_filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "needsReview", "section", "count"]

  filter() {
    const query = this.searchTarget.value.toLowerCase().trim()
    const needsReviewOnly = this.needsReviewTarget.checked
    let visibleCount = 0

    this.sectionTargets.forEach(section => {
      const rows = section.querySelectorAll("[data-element-row]")
      let sectionHasVisible = false

      rows.forEach(row => {
        const text = row.dataset.searchableText.toLowerCase()
        const needsReview = row.dataset.needsReview === "true"

        const matchesSearch = !query || text.includes(query)
        const matchesFilter = !needsReviewOnly || needsReview

        const visible = matchesSearch && matchesFilter
        row.hidden = !visible

        if (visible) {
          sectionHasVisible = true
          visibleCount++
        }
      })

      // Hide entire section if no visible elements
      section.hidden = !sectionHasVisible
    })

    this.updateCount(visibleCount)
  }

  updateCount(count) {
    const text = count === 1 ? "1 element" : `${count} elements`
    this.countTarget.textContent = text
  }
}
```

**Step 2: Register controller**

Ensure the controller is auto-loaded via esbuild/importmap conventions.

---

## Phase 6: Cleanup

### Task 9: Update Navigation Links

Update any links pointing to old wizard steps to use the new review path:

```ruby
# Old
submission_submission_step_path(submission, step: 1)

# New
submission_review_path(submission)
```

### Task 10: Deprecate Old Wizard (Optional)

After verifying the new review page works:

1. Add deprecation warning to `SubmissionStepsController`
2. Redirect old step URLs to new review page
3. Eventually remove old controller and views

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Navigation | 7 sequential steps | Single scrollable page |
| Structure | Custom groupings | AMSF questionnaire sections |
| Finding elements | Click through steps | Search + filter |
| Editing | Inline in wizard | Read-only (MVP) |
| Locking | Lock/unlock system | None (MVP) |
| URL | `/submissions/:id/steps/:step` | `/submissions/:id/review` |

**Key files:**
- `app/models/xbrl/survey.rb` - Section structure definition
- `app/controllers/survey_reviews_controller.rb` - Review page controller
- `app/views/survey_reviews/show.html.erb` - Review page view
- `app/javascript/controllers/survey_filter_controller.js` - Client-side filtering

**Future work (not in MVP):**
- Inline editing with override tracking
- Lock/unlock for concurrent editing
- Year-over-year comparison highlighting
- CalculationEngine → per-element lambda refactor
