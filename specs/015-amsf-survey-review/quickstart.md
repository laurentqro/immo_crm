# Quickstart: AMSF Survey Review Page

**Branch**: `015-amsf-survey-review` | **Date**: 2025-12-05

## Prerequisites

- Ruby 3.2+
- Rails 8.0
- PostgreSQL running
- AMSF taxonomy files present in `docs/taxonomy/`

## Setup

```bash
# 1. Switch to feature branch
git checkout 015-amsf-survey-review

# 2. Install dependencies
bundle install

# 3. Setup database
bin/rails db:prepare

# 4. Verify taxonomy is loaded
bin/rails runner "puts Xbrl::Taxonomy.instance.elements.count"
# Expected: 323
```

## Development Server

```bash
# Start all services (Rails, Tailwind, etc.)
bin/dev

# Access the application
open http://localhost:3000
```

## Testing

### Run All Tests

```bash
# Full test suite
bin/rails test

# Model tests only
bin/rails test test/models/

# Controller tests only
bin/rails test test/controllers/

# System tests
bin/rails test:system
```

### Feature-Specific Tests

```bash
# Survey module tests
bin/rails test test/models/xbrl/survey_test.rb

# Controller tests
bin/rails test test/controllers/survey_reviews_controller_test.rb

# SubmissionValue needs_review tests
bin/rails test test/models/submission_value_test.rb

# ElementManifest needs_review tests
bin/rails test test/models/xbrl/element_manifest_test.rb

# System tests for end-to-end flow
bin/rails test test/system/survey_review_test.rb
```

### Watch Mode

```bash
# Run tests on file changes (requires guard gem)
bundle exec guard
```

## Code Quality

```bash
# Run RuboCop
bin/rubocop

# Auto-fix issues
bin/rubocop -a
```

## Manual Testing

### 1. Access Survey Review Page

```bash
# Create a test submission if needed
bin/rails runner "
  account = Account.first
  submission = Submission.create!(account: account, period: '2024', status: 'draft')
  puts 'Created submission: ' + submission.id.to_s
"

# Navigate to review page
open http://localhost:3000/submissions/<submission_id>/review
```

### 2. Test Search Functionality

1. Type in the search box
2. Verify elements filter as you type
3. Verify element count updates
4. Verify sections with no matching elements are hidden

### 3. Test "Needs Review" Filter

1. Toggle the "Needs review only" filter
2. Verify only flagged elements are visible
3. Verify sections with no flagged elements are hidden

### 4. Test Completion Flow

1. Scroll to bottom of review page
2. Click "Complete Submission" button
3. Confirm the action in the dialog
4. Verify redirect to submission detail page
5. Verify submission status is "completed"

## Console Commands

```ruby
# Load taxonomy
Xbrl::Taxonomy.instance

# List all sections
Xbrl::Survey.sections.each { |s| puts "#{s[:id]}: #{s[:title]}" }

# Validate survey against taxonomy
Xbrl::Survey.validate!

# Build element manifest for a submission
submission = Submission.first
manifest = Xbrl::ElementManifest.new(submission)
manifest.elements.first

# Check needs_review flag
sv = SubmissionValue.first
sv.needs_review?

# Flag a value for review
sv.update!(metadata: { flagged_for_review: true })
```

## Troubleshooting

### "Taxonomy not found" error

Ensure taxonomy files exist:
```bash
ls docs/taxonomy/strix_Real_Estate_AML_CFT_survey_2025.xsd
```

### "Invalid Survey elements" error at boot

Survey references element names not in taxonomy. Check:
```ruby
# In console
Xbrl::Survey.validate!
```

### Filtering not working

Check Stimulus controller is loaded:
1. Open browser DevTools
2. Look for `survey-filter` controller in Elements panel
3. Check Console for JavaScript errors

### Elements not displaying

Verify ElementManifest returns data:
```ruby
manifest = Xbrl::ElementManifest.new(Submission.first)
manifest.elements.count
```

## Key Files

| File | Purpose |
|------|---------|
| `app/models/xbrl/survey.rb` | Section/element mapping |
| `app/controllers/survey_reviews_controller.rb` | Page controller |
| `app/views/survey_reviews/show.html.erb` | Main review page |
| `app/javascript/controllers/survey_filter_controller.js` | Client-side filtering |
| `test/models/xbrl/survey_test.rb` | Survey module tests |
| `test/system/survey_review_test.rb` | End-to-end tests |
