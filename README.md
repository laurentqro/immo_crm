# Immo CRM

AML/KYC compliance CRM for Luxembourg real estate professionals. Manages client onboarding, transaction monitoring, beneficial owner tracking, and annual AMSF regulatory survey submissions.

Built on Jumpstart Pro Rails 8 with Hotwire.

## Requirements

* Ruby 3.4+
* PostgreSQL 15+
* Libvips or Imagemagick

## Setup

```bash
bin/setup    # Install dependencies and setup database
bin/dev      # Start development server (Overmind)
```

## Testing

```bash
bin/rails test          # Run test suite
bin/rails test:system   # Run system tests
bin/rubocop             # Run linter
```

## Merging Jumpstart Pro Updates

```bash
git fetch jumpstart-pro
git merge jumpstart-pro/main
```
