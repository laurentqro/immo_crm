# CLAUDE.md

## Overview

AML/KYC compliance CRM for Monaco real estate professionals, built on Jumpstart Pro Rails 8. Manages client onboarding, beneficial owner tracking, transaction monitoring, and annual AMSF regulatory survey submissions.

## Undiscoverable Design Decisions

### Multi-tenancy
Account-based: all CRM data is scoped by current_account via Pundit policies.

### Client types: only two
- `NATURAL_PERSON` and `LEGAL_ENTITY` — there is NO separate `TRUST` client type
- Trusts are legal entities with `legal_entity_type: "TRUST"`
- `trust?` helper = `legal_entity? && legal_entity_type == "TRUST"`
- Trustees: separate `Trustee` model (belongs_to :client), not columns on Client

### AMSF Survey boundary
The app knows nothing about XBRL. Survey (`app/models/survey.rb`) is a read-only PORO that calculates field values using semantic IDs (e.g., `a1101` for total clients). The `amsf_survey` + `amsf_survey-real_estate` gems handle all XBRL/XML generation.

Survey field methods are named after AMSF field IDs directly — `grep a1101` finds both the gem field and the implementation. This is intentional.

`test/models/survey_completeness_test.rb` ensures every gem questionnaire field has an implementation. When AMSF updates the questionnaire, CI fails on missing fields.
