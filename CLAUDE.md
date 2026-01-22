# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Jumpstart Pro Rails is a commercial multi-tenant SaaS starter application built with Rails 8. It provides subscription billing, team management, authentication, and modern Rails patterns for building subscription-based web applications.

## Development Commands

```bash
# Initial setup
bin/setup                    # Install dependencies and setup database

# Development server
bin/dev                      # Start development server with Overmind (includes Rails server, asset watching)
bin/rails server            # Standard Rails server only

# Database
bin/rails db:prepare         # Setup database (creates, migrates, seeds)
bin/rails db:migrate         # Run migrations
bin/rails db:seed           # Seed database

# Testing
bin/rails test              # Run test suite (Minitest)
bin/rails test:system       # Run system tests (Capybara + Selenium)

# Code quality
bin/rubocop                 # Run RuboCop linter (configured in .rubocop.yml)
bin/rubocop -a              # Auto-fix RuboCop issues

# Background jobs
bin/jobs                    # Start SolidQueue worker (if using SolidQueue)
bundle exec sidekiq         # Start Sidekiq worker (if using Sidekiq)
```

## Architecture

### Multi-tenancy System
- **Account-based tenancy**: Users belong to Accounts (personal or team)
- **AccountUser model**: Join table managing user-account relationships with roles
- **Current account switching**: Users can switch between accounts via `switch_account(account)`
- **Authorization**: Pundit policies scope data by current account

### Modular Models
Models use Ruby modules for organization:
```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Accounts, Agreements, Authenticatable, Mentions, Notifiable, Searchable, Theme
end

# app/models/account.rb  
class Account < ApplicationRecord
  include Billing, Domains, Transfer, Types
end
```

### Jumpstart Configuration System
- **Dynamic configuration**: `config/jumpstart.yml` controls enabled features
- **Runtime gem loading**: `Gemfile.jumpstart` loads gems based on configuration
- **Feature toggles**: Payment processors, integrations, background jobs, etc.
- Access via `Jumpstart.config.payment_processors`, `Jumpstart.config.stripe?`, etc.

### Payment Architecture
- **Pay gem (~11.0)**: Unified interface for multiple payment processors
- **Processor-agnostic**: Stripe, Paddle, Braintree, PayPal, Lemon Squeezy support
- **Per-seat billing**: Team accounts with usage-based pricing
- **Subscription management**: In `app/models/account/billing.rb`
- **Email delivery**: Mailgun, Mailpace, Postmark, and Resend use API gems instead of SMTP
- **API client errors**: Raise `UnprocessableContent` for 422 responses (rfc9110)

## Technology Stack

- **Rails 8** with Hotwire (Turbo + Stimulus) and Hotwire Native
- **PostgreSQL** (primary), **SolidQueue** (jobs), **SolidCache** (cache), **SolidCable** (websockets)
- **Import Maps** for JavaScript (no Node.js dependency)
- **TailwindCSS v4** via tailwindcss-rails gem
- **Devise** for authentication with custom extensions
- **Pundit** for authorization
- **Minitest** for testing with parallel execution

## Testing

- **Minitest** with fixtures in `test/fixtures/`
- **System tests** use Capybara with Selenium WebDriver
- **Test parallelization** enabled via `parallelize(workers: :number_of_processors)`
- **WebMock** configured to disable external HTTP requests
- **Test database** reset between runs

## Routes Organization

Routes are modularized in `config/routes/`:
- `accounts.rb` - Account management, switching, invitations
- `billing.rb` - Subscription, payment, receipt routes
- `users.rb` - User profile, settings, authentication
- `api.rb` - API v1 endpoints with JWT authentication

## Key Directories

- `app/controllers/accounts/` - Account-scoped controllers
- `app/models/concerns/` - Shared model modules
- `app/policies/` - Pundit authorization policies
- `lib/jumpstart/` - Core Jumpstart engine and configuration
- `config/routes/` - Modular route definitions
- `app/components/` - View components for reusable UI

## Development Notes

- **Current account** available via `current_account` helper in controllers/views
- **Account switching** via `switch_account(account)` in tests
- **Billing features** conditionally loaded based on `Jumpstart.config.payments_enabled?`
- **Background jobs** configurable between SolidQueue and Sidekiq
- **Multi-database** setup with separate databases for cache, jobs, and cable

## Active Technologies
- Ruby 3.2+ / Rails 8.0 + Jumpstart Pro, Devise, Pundit, Hotwire (Turbo/Stimulus), Nokogiri, Pay gem (001-mvp-immo-crm)
- PostgreSQL 15+ (primary), SolidQueue (jobs), SolidCache (cache), SolidCable (websockets) (001-mvp-immo-crm)
- Ruby 3.2+ / Rails 8.0 + Minitest, Nokogiri (XSD/XML parsing), SubmissionRenderer and CalculationEngine services (011-xbrl-compliance-tests)
- PostgreSQL (test database with fixtures) (011-xbrl-compliance-tests)
- Ruby 3.2+ / Rails 8.0 + Nokogiri (XML parsing), Minitest (testing), Jumpstart Pro (application framework) (012-amsf-taxonomy-compliance)
- PostgreSQL (primary), existing SubmissionValue model (012-amsf-taxonomy-compliance)
- Ruby 3.2+ / Rails 8.0 + Jumpstart Pro, Hotwire (Turbo/Stimulus), Nokogiri (XML/XBRL), Pay gem (013-amsf-data-capture)
- PostgreSQL (primary), existing schema with clients, transactions, submissions tables (013-amsf-data-capture)
- Ruby 3.4.7 / Rails 8.1 + `amsf_survey`, `amsf_survey-real_estate`, Nokogiri, Turbo/Stimulus (016-amsf-gem-migration)
- PostgreSQL (existing schema - Submission, SubmissionValue models) (016-amsf-gem-migration)

## AMSF Survey Gem Integration

The application uses the `amsf_survey` and `amsf_survey-real_estate` gems for XBRL generation and validation:

### Key Components
- **SubmissionBuilder** (`app/services/submission_builder.rb`): Orchestrates submission workflow, creates gem submissions, validates, generates XBRL
- **SubmissionRenderer** (`app/services/submission_renderer.rb`): Renders XBRL via gem for supported years
- **ElementManifest** (`app/models/xbrl/element_manifest.rb`): Provides gem questionnaire access for field metadata
- **Initializer** (`config/initializers/amsf_survey.rb`): Loads gem and configures Arelle validation toggle

### Validation Layers
1. **Gem validation**: Business rules via `AmsfSurvey.validate(submission)` - always runs
2. **Arelle validation**: Schema validation via external service - optional, controlled by `ARELLE_VALIDATION_ENABLED`

### Environment Variables
- `ARELLE_VALIDATION_ENABLED`: Enable external Arelle validation (default: false in dev/test, true in production)
- `XBRL_VALIDATOR_URL`: Arelle validator service URL (default: http://localhost:8000)

### Usage
```ruby
builder = SubmissionBuilder.new(organization, year: 2025)
result = builder.build
validation = builder.validate        # Gem validation
xbrl = builder.generate_xbrl         # XBRL via gem
arelle = builder.validate_with_arelle  # External Arelle validation
```

## Recent Changes
- 001-mvp-immo-crm: Added Ruby 3.2+ / Rails 8.0 + Jumpstart Pro, Devise, Pundit, Hotwire (Turbo/Stimulus), Nokogiri, Pay gem
- 016-amsf-gem-migration: Integrated amsf_survey gem for XBRL generation, validation, and questionnaire metadata
