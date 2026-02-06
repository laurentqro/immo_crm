# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Immo CRM is an AML/KYC compliance CRM for Luxembourg real estate professionals, built on Jumpstart Pro Rails 8. It manages client onboarding, beneficial owner tracking, transaction monitoring, managed properties, staff training records, and annual AMSF regulatory survey submissions (XBRL via `amsf_survey` gem).

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
- `crm.rb` - CRM resources: clients, beneficial owners, transactions, submissions, settings, etc.
- `accounts.rb` - Account management, switching, invitations
- `billing.rb` - Subscription, payment, receipt routes
- `users.rb` - User profile, settings, authentication
- `api.rb` - API v1 endpoints with JWT authentication

## Key Directories

- `app/models/survey/fields/` - AMSF survey field implementations (5 modules + helpers)
- `app/controllers/` - CRM controllers (clients, beneficial_owners, transactions, submissions, etc.)
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
- Ruby 3.4+ / Rails 8.1 + Jumpstart Pro, Devise, Pundit, Hotwire (Turbo/Stimulus), Pay gem
- PostgreSQL 15+ (primary), SolidQueue (jobs), SolidCache (cache), SolidCable (websockets)
- `amsf_survey` + `amsf_survey-real_estate` gems for regulatory survey submission

## AMSF Survey Integration

The application uses the `amsf_survey` and `amsf_survey-real_estate` gems for regulatory survey submission. **The app knows nothing about XBRL** - only semantic field names like `total_clients`, `high_risk_clients`.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    immo_crm Application                   │
│                                                           │
│  Survey PORO ───────────────────────────────────────────  │
│    │ CustomerRisk   │ ProductsServicesRisk │ Controls   │ │
│    │ DistributionRisk │ Signatories                     │ │
│                                                           │
│  Methods: #total_clients, #high_risk_clients, etc.       │
└───────────────────────────────────────────────────────────┘
                              │ semantic names only
                              ▼
┌───────────────────────────────────────────────────────────┐
│                     amsf_survey gem                        │
│  Handles: XBRL codes, XML generation, validation          │
└───────────────────────────────────────────────────────────┘
```

### Key Components
- **Survey** (`app/models/survey.rb`): Read-only PORO that calculates all 323 questionnaire field values
- **Survey::Fields::*** (`app/models/survey/fields/`): 5 modules mirroring AMSF questionnaire tabs
- **Initializer** (`config/initializers/amsf_survey.rb`): Loads gem and registers real_estate industry

### Usage
```ruby
survey = Survey.new(organization: org, year: 2025)
survey.valid?    # => true/false (gem validation)
survey.errors    # => validation errors
survey.to_xbrl   # => XML string via gem
```

### Field Modules
| Module | Purpose | Example Methods |
|--------|---------|-----------------|
| `CustomerRisk` | Client/risk statistics | `a1101` (total clients), `a1102` (nationals), `a11301` (PEP clients) |
| `ProductsServicesRisk` | Payment/transaction metrics | `a2108b` (cash transactions), `a2105b` (transfers) |
| `DistributionRisk` | CDD and channel risks | `a3209` (non-face-to-face), `a3201` (introducers) |
| `Controls` | Compliance/audit controls | `ac1201` (AML policy), `ab3206` (staff trained) |
| `Signatories` | Entity/business info | `ac1701` (legal form), `ac1801` (annual revenue) |

Methods use field IDs directly (e.g., `a1101`) rather than semantic names. This eliminates indirection - `grep a1101` finds both the gem field and the implementation.

### CI Safety Net
`test/models/survey_completeness_test.rb` ensures all gem questionnaire fields have implementations. When AMSF updates the questionnaire (new gem version), CI fails if any new field lacks a method.

## Recent Changes
- 001-mvp-immo-crm: Added Ruby 3.2+ / Rails 8.0 + Jumpstart Pro, Devise, Pundit, Hotwire (Turbo/Stimulus), Nokogiri, Pay gem
- 016-amsf-gem-migration: Complete XBRL abstraction via amsf_survey gem. Deleted ~10,500 lines of legacy code. App now uses semantic field names only; gem handles all XBRL details.
