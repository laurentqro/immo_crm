# Quickstart: Immo CRM MVP

**Date**: 2025-11-30
**Time to setup**: ~15 minutes

## Prerequisites

- Ruby 3.2+ (recommend using rbenv or asdf)
- PostgreSQL 15+
- Docker (for validation service)
- Git

## Initial Setup

### 1. Clone and Install Dependencies

```bash
# Clone repository
git clone https://github.com/your-org/immo_crm.git
cd immo_crm

# Install Ruby dependencies
bundle install

# Install JavaScript dependencies (if any)
# Note: Jumpstart Pro uses Import Maps, minimal JS setup
```

### 2. Database Setup

```bash
# Copy database config
cp config/database.yml.example config/database.yml

# Edit config/database.yml with your PostgreSQL credentials
# Default assumes: postgres user, no password, localhost

# Create and setup database
bin/rails db:prepare
```

### 3. Environment Variables

```bash
# Copy environment template
cp .env.example .env

# Edit .env with required values:
# - VALIDATOR_URL=http://localhost:8000 (Python sidecar)
# - STRIPE_* keys (if testing billing)
```

### 4. Start Validation Service (Docker)

```bash
# Build and run Python validation service
cd validation_service
docker build -t immo-validator .
docker run -d -p 8000:8000 --name immo-validator immo-validator

# Verify it's running
curl http://localhost:8000/health
# Should return: {"status": "ok"}
```

### 5. Start Development Server

```bash
# Back to project root
cd ..

# Start all services with Overmind
bin/dev

# Or just Rails server
bin/rails server
```

### 6. Access the Application

Open http://localhost:3000 in your browser.

**Default development credentials** (if seeded):
- Email: `admin@example.com`
- Password: `password`

---

## Key Development Commands

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/client_test.rb

# Run system tests (requires Chrome/ChromeDriver)
bin/rails test:system

# Run tests in parallel
bin/rails test PARALLEL_WORKERS=4
```

### Code Quality

```bash
# Run RuboCop
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Run security scanner
bundle exec brakeman
```

### Database Tasks

```bash
# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (drop, create, migrate, seed)
bin/rails db:reset

# Generate new migration
bin/rails generate migration CreateClients name:string client_type:string
```

### Console & Debugging

```bash
# Rails console
bin/rails console

# Rails console in sandbox (rollback on exit)
bin/rails console --sandbox

# View routes
bin/rails routes | grep clients
```

---

## Project Structure Overview

```
immo_crm/
├── app/
│   ├── controllers/       # Rails controllers
│   ├── models/            # ActiveRecord models
│   ├── services/          # Business logic (CalculationEngine, XbrlGenerator)
│   ├── policies/          # Pundit authorization policies
│   ├── views/             # ERB templates
│   └── javascript/        # Stimulus controllers
│
├── config/
│   ├── routes.rb          # Main routes file
│   ├── routes/            # Modular route files
│   └── amsf_element_mapping.yml  # XBRL element mappings
│
├── db/
│   ├── migrate/           # Database migrations
│   ├── schema.rb          # Current schema
│   └── seeds.rb           # Seed data
│
├── test/
│   ├── models/            # Model unit tests
│   ├── controllers/       # Controller tests
│   ├── services/          # Service object tests
│   ├── system/            # End-to-end system tests
│   └── fixtures/          # Test fixtures
│
├── validation_service/    # Python sidecar
│   ├── main.py           # FastAPI application
│   ├── Dockerfile        # Container definition
│   └── taxonomies/       # XBRL/XULE rulesets
│
└── specs/                 # Feature specifications
    └── 001-mvp-immo-crm/
        ├── spec.md
        ├── plan.md
        ├── research.md
        ├── data-model.md
        └── contracts/
```

---

## Common Development Tasks

### Adding a New Model

```bash
# Generate model with migration
bin/rails generate model Property \
  organization:references \
  address:string \
  city:string \
  value:decimal

# Edit migration if needed
# Run migration
bin/rails db:migrate

# Add to organization association
# app/models/organization.rb
has_many :properties
```

### Adding a New Controller

```bash
# Generate controller
bin/rails generate controller Properties index show new create edit update destroy

# Add routes (config/routes.rb or config/routes/crm.rb)
resources :properties

# Create Pundit policy
# app/policies/property_policy.rb
```

### Adding a Stimulus Controller

```bash
# Create controller file
# app/javascript/controllers/property_form_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["price", "commission"]

  connect() {
    // Initialize
  }

  calculateCommission() {
    // Handle change
  }
}

# Use in view
<div data-controller="property-form">
  <input data-property-form-target="price"
         data-action="change->property-form#calculateCommission">
</div>
```

### Working with Turbo Frames

```erb
<%# Wrap content in a frame %>
<%= turbo_frame_tag dom_id(@client) do %>
  <%= render @client %>
<% end %>

<%# Link that targets the frame %>
<%= link_to "Edit", edit_client_path(@client),
    data: { turbo_frame: dom_id(@client) } %>
```

---

## Validation Service Development

### Running Locally (without Docker)

```bash
cd validation_service

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run FastAPI server
uvicorn main:app --reload --port 8000
```

### Testing Validation

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test validation (with sample XBRL)
curl -X POST http://localhost:8000/validate \
  -H "Content-Type: application/json" \
  -d '{"xbrl_content": "<xbrl>...</xbrl>"}'
```

---

## Deployment

### Kamal Deployment

```bash
# Setup Kamal (first time)
kamal setup

# Deploy
kamal deploy

# View logs
kamal app logs

# Run console on server
kamal app exec --interactive bin/rails console
```

### Environment Variables (Production)

Required in production:
- `RAILS_MASTER_KEY`
- `DATABASE_URL`
- `SECRET_KEY_BASE`
- `VALIDATOR_URL`
- `STRIPE_PUBLIC_KEY`
- `STRIPE_PRIVATE_KEY`
- `STRIPE_WEBHOOK_SECRET`

---

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Check connection
psql -h localhost -U postgres -d immo_crm_development
```

### Validation Service Not Responding

```bash
# Check container status
docker ps

# View logs
docker logs immo-validator

# Restart container
docker restart immo-validator
```

### Asset Issues

```bash
# Precompile assets
bin/rails assets:precompile

# Clear cache
bin/rails tmp:clear
bin/rails assets:clobber
```

### Test Failures

```bash
# Reset test database
RAILS_ENV=test bin/rails db:reset

# Run with verbose output
bin/rails test --verbose
```

---

## Getting Help

- **Jumpstart Pro Docs**: https://jumpstartrails.com/docs
- **Rails Guides**: https://guides.rubyonrails.org
- **Hotwire Handbook**: https://turbo.hotwired.dev/handbook
- **Stimulus Reference**: https://stimulus.hotwired.dev/reference
