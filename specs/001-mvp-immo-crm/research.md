# Research: Immo CRM MVP

**Date**: 2025-11-30
**Status**: Complete

## Executive Summary

This document captures technology decisions and research findings for the Immo CRM MVP. All "NEEDS CLARIFICATION" items from the Technical Context have been resolved.

---

## 1. XBRL Generation in Ruby

### Decision
Use **Nokogiri** for XBRL XML generation in Ruby.

### Rationale
- Nokogiri is the de facto standard for XML manipulation in Ruby
- Already included in Rails dependencies (via Action View)
- Full control over XML structure, namespaces, and attributes
- No XBRL-specific Ruby gem exists with adequate maintenance
- XBRL is fundamentally XML with specific schemas - Nokogiri handles this well

### Alternatives Considered
| Option | Reason Rejected |
|--------|-----------------|
| `xbrl` gem | Abandoned (last update 2015), no XULE support |
| `ox` gem | Faster but less namespace support; Nokogiri adequate for our scale |
| Generate via Python | Adds complexity; Ruby sufficient for generation |

### Implementation Notes
```ruby
# XBRL generation pattern
Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
  xml.xbrl(NAMESPACES) do
    xml['xbrli'].context(id: 'ctx_entity') { ... }
    xml['strix'].send(element_name, value, contextRef: 'ctx_entity')
  end
end.to_xml
```

---

## 2. XULE Validation Strategy

### Decision
Deploy **Python sidecar service** (FastAPI + Arelle + XULE plugin) for validation.

### Rationale
- XULE rules are the official AMSF validation standard (275 rules)
- Arelle is the only mature XULE processor; Python-only
- FastAPI provides simple HTTP interface for Ruby integration
- Sidecar deployment via Kamal keeps services co-located
- Validation is synchronous (user waits for results) but infrequent

### Alternatives Considered
| Option | Reason Rejected |
|--------|-----------------|
| Port XULE to Ruby | Massive effort; XULE spec complex |
| Skip XULE validation | Compliance risk; Strix portal will reject invalid files |
| External validation API | None exist; build vs. buy not applicable |
| Client-side WASM | Arelle too large for browser; poor UX |

### Implementation Notes
- Service runs on same host as Rails app (localhost:8000)
- HTTP timeout: 60 seconds (validation can be slow)
- Fallback: Allow unvalidated download with warning if service unavailable
- Health check endpoint for monitoring

---

## 3. Multi-Tenancy Architecture

### Decision
Use **Jumpstart Pro Account-based tenancy** with Organization model extension.

### Rationale
- Jumpstart Pro already provides Account → User → Team structure
- Organization extends Account with AMSF-specific fields (RCI number, etc.)
- Row-level security via Pundit policies (not database-level isolation)
- Simpler than schema-per-tenant; adequate for MVP scale

### Alternatives Considered
| Option | Reason Rejected |
|--------|-----------------|
| Schema-per-tenant (apartment gem) | Overkill for 10-50 orgs; operational complexity |
| Database-per-tenant | Extreme isolation unnecessary; backup complexity |
| ActsAsTenant gem | Redundant with Jumpstart Pro patterns |

### Implementation Notes
```ruby
# Organization extends Account
class Organization < ApplicationRecord
  belongs_to :account
  has_many :clients
  has_many :transactions
  has_many :submissions
end

# Controller pattern
def current_organization
  @current_organization ||= current_account.organization
end
```

---

## 4. Soft Delete Strategy

### Decision
Use **Discard gem** for soft deletes with `deleted_at` timestamp.

### Rationale
- 5-year retention requirement prohibits immediate hard deletes
- Discard is lightweight, well-maintained, Rails convention-friendly
- Supports scopes: `kept`, `discarded`, `with_discarded`
- Plays well with associations and Pundit policies

### Alternatives Considered
| Option | Reason Rejected |
|--------|-----------------|
| Paranoia gem | Deprecated in favor of Discard |
| acts_as_paranoid | Less maintained than Discard |
| Custom implementation | Reinventing the wheel |
| Archive tables | Complex; Discard simpler |

### Implementation Notes
```ruby
# Gemfile
gem 'discard', '~> 1.3'

# Model
class Client < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }  # Only non-deleted by default
end

# Background job for hard delete after retention
class PurgeExpiredRecordsJob < ApplicationJob
  def perform
    Client.discarded
          .where('deleted_at < ?', 5.years.ago)
          .find_each(&:destroy)  # Hard delete
  end
end
```

---

## 5. Audit Logging

### Decision
Use **custom AuditLog model** with polymorphic associations.

### Rationale
- Full control over logged events and retention
- Compliance requires specific audit trail (auth + CRUD on sensitive data)
- Paper Trail gem is overkill (full versioning not needed)
- Custom model allows organization scoping for multi-tenancy

### Alternatives Considered
| Option | Reason Rejected |
|--------|-----------------|
| PaperTrail gem | Too heavy; stores full object versions |
| Audited gem | Good but adds dependency for simple needs |
| Database triggers | Harder to maintain; less portable |
| External logging service | Adds dependency; compliance data should stay local |

### Implementation Notes
```ruby
# app/models/audit_log.rb
class AuditLog < ApplicationRecord
  belongs_to :organization
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  # Columns: action, auditable_type, auditable_id, metadata (jsonb), created_at
end

# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create { log_audit('create') }
    after_update { log_audit('update') }
    after_discard { log_audit('delete') }
  end
end
```

---

## 6. Settings Storage Pattern

### Decision
Use **dedicated Settings model** with key-value pairs and type casting.

### Rationale
- Settings map directly to XBRL elements (stable year-over-year)
- Key-value allows flexible schema without migrations for new settings
- Type metadata enables proper casting (boolean, integer, date, enum)
- Category grouping supports UI organization

### Alternatives Considered
| Option | Reason Rejected |
|--------|-----------------|
| Rails credentials | Not user-editable; wrong use case |
| JSON column on Organization | Less queryable; harder to validate |
| Separate models per category | Over-engineering for ~30 settings |
| Redis/Valkey | Overkill; PostgreSQL adequate |

### Implementation Notes
```ruby
class Setting < ApplicationRecord
  belongs_to :organization

  TYPES = %w[boolean integer decimal string date enum].freeze

  def typed_value
    case value_type
    when 'boolean' then value == 'true'
    when 'integer' then value.to_i
    when 'decimal' then value.to_d
    when 'date' then Date.parse(value)
    else value
    end
  end
end
```

---

## 7. Calculation Engine Design

### Decision
**Service object pattern** with memoization and explicit dependency ordering.

### Rationale
- Complex aggregation logic should not live in models
- Service object allows easy testing with mocked data
- Memoization prevents redundant queries
- Element mapping via YAML config keeps business logic readable

### Implementation Notes
```ruby
class CalculationEngine
  def initialize(submission)
    @submission = submission
    @org = submission.organization
  end

  def calculate_all
    {}.tap do |results|
      results.merge!(client_statistics)
      results.merge!(transaction_statistics)
      results.merge!(pep_statistics)
      # ... ordered by dependency
    end
  end

  private

  def client_statistics
    @client_stats ||= begin
      clients = @org.clients.where(became_client_at: ..@submission.year_end)
      {
        'a1101' => clients.count,
        'a1102' => clients.where(client_type: 'PP').count,
        # ...
      }
    end
  end
end
```

---

## 8. Hotwire Patterns for CRM UI

### Decision
**Turbo Frames for CRUD**, **Turbo Streams for notifications**, **Stimulus for forms**.

### Rationale
- Turbo Frames enable inline editing without full page reloads
- Turbo Streams provide real-time feedback (validation results, save confirmations)
- Stimulus controllers handle conditional form fields (payment method → cash amount)
- No need for React/Vue; Hotwire sufficient for CRM complexity

### Patterns to Apply
| UI Pattern | Hotwire Solution |
|------------|------------------|
| Inline edit client | Turbo Frame: `client_#{id}` |
| Add transaction modal | Turbo Frame: `new_transaction` |
| Client search/select | Stimulus: `client-search` controller |
| Conditional form fields | Stimulus: `conditional-fields` controller |
| Save confirmation | Turbo Stream: flash message |
| Validation progress | Turbo Stream: progress updates |

---

## 9. Deployment Architecture

### Decision
**Kamal deployment** to Hetzner CPX21 with PostgreSQL and validation sidecar.

### Rationale
- Kamal is Rails 8 default deployment tool
- Hetzner CPX21 (€8/month) adequate for MVP scale
- Co-located services minimize latency
- Traefik handles SSL termination and routing

### Infrastructure Components
| Component | Solution |
|-----------|----------|
| Rails app | Docker container via Kamal |
| PostgreSQL | Docker container (accessory) |
| Validation service | Docker container (accessory) |
| SSL | Let's Encrypt via Traefik |
| Backups | pg_dump to B2/S3 daily |

---

## 10. Testing Strategy

### Decision
**Minitest with fixtures**, system tests for critical journeys.

### Rationale
- Minitest is Rails default; fast and sufficient
- Fixtures provide predictable test data
- System tests cover submission wizard (critical path)
- Service objects unit-tested in isolation

### Test Coverage Targets
| Layer | Approach |
|-------|----------|
| Models | Unit tests for validations, scopes, associations |
| Services | Unit tests with mocked dependencies |
| Controllers | Integration tests for auth, params, responses |
| System | End-to-end for submission wizard, client CRUD |

---

## Summary of Decisions

| Area | Decision | Key Dependency |
|------|----------|----------------|
| XBRL Generation | Nokogiri | None (built-in) |
| XULE Validation | Python sidecar (Arelle) | FastAPI, Docker |
| Multi-tenancy | Jumpstart Pro + Organization | None |
| Soft Deletes | Discard gem | `discard` gem |
| Audit Logging | Custom AuditLog model | None |
| Settings Storage | Key-value Setting model | None |
| Calculation Engine | Service object pattern | None |
| UI Interactivity | Hotwire (Turbo + Stimulus) | Built into Rails 8 |
| Deployment | Kamal to Hetzner | Docker, Traefik |
| Testing | Minitest + fixtures | Built into Rails |

**All NEEDS CLARIFICATION items resolved. Ready for Phase 1 design.**
