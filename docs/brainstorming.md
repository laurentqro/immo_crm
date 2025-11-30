# ImmoCRM Brainstorming Summary

**Date:** November 29-30, 2025
**Participants:** Laurent + Claude

---

## Project Overview

**ImmoCRM** (codename) is a mini-CRM for Monaco real estate agents that makes annual AMSF AML/CFT compliance effortless.

**Core value proposition:**
- **Year-round:** Track clients, transactions, and beneficial owners in a simple CRM
- **Set once:** Configure compliance policies in settings (stable year-over-year)
- **At submission time:** Review auto-calculated aggregates, confirm policies, download XBRL

**Philosophy:** The web app is a useful CRM first, compliance tool second. Users get value all year from tracking their business. The annual AMSF submission becomes a 15-minute review, not a 2-week project.

**Target:** 2 weeks of manual work → 15 minutes with ImmoCRM

---

## Problem Statement

Monaco real estate agents must submit annual AMSF AML/CFT reports via the FT Solutions Strix portal. Currently:

- **180+ questions** to answer manually
- **2 weeks** of full-time work per submission
- **High error rate** from manual calculations
- **No tools exist** to simplify this process

---

## Key Decisions Made

### Q1: Data Entry Method
**Decision:** Transaction logger available in both web app AND Excel (hybrid)
- Web app is primary
- Excel import deferred to post-MVP

### Q2: Transaction Logger Scope
**Decision:** Full transaction logger (not just import-only)
- Users can add/edit transactions in the web app
- Year-round value, not just at submission time

### Q3: Usage Patterns
**Decision:** Support both year-round AND crunch-time usage
- Organized users log throughout the year
- Others can bulk-enter near deadline
- Both workflows should work

### Q4: Returning Users
**Decision:** Pre-fill & confirm approach
- Show previous year's answers
- User confirms unchanged or edits
- Minimal friction for stable answers

### Q5: Tech Stack
**Decision:** Rails + Hotwire + Postgres
- Laurent is a Ruby on Rails engineer
- Port XBRL generation from Python to Ruby
- Keep Python microservice for XULE validation (275 rules via Arelle)

### Q6: Deployment
**Decision:** Single VPS + Kamal
- Hetzner CPX21 (~€8/month)
- PostgreSQL on same VPS with backups
- Simple, cost-effective for MVP

### Q7: Starter App
**Decision:** Jumpstart Pro
- Teams, accounts, billing ready out of the box
- Multi-tenancy built in (Account-based)

### Q8: Validation Strategy
**Decision:** Full XULE validation before download
- 275 business rules via Arelle
- Python FastAPI microservice
- Validate before user downloads XBRL

### Q9: CRM-First Architecture (Major Pivot)
**Decision:** Web app is a CRM first, compliance tool second

**Before (Questionnaire-First):**
- 9-step submission wizard
- Excel import as P0
- Data entry at submission time

**After (CRM-First):**
- 4-step streamlined submission
- Excel import deferred to post-MVP
- Data lives in CRM, entered year-round
- Settings store stable policy answers

---

## Architecture: Three-Layer Model

```
┌─────────────────────────────────────────────────────┐
│                    Mini-CRM                         │
│  (Year-round value - this is the product)          │
├─────────────────────────────────────────────────────┤
│  • Clients (with beneficial owners)                 │
│  • Transactions (linked to clients)                 │
│  • STR Reports                                      │
└─────────────────────────────────────────────────────┘
                        │
┌─────────────────────────────────────────────────────┐
│            Settings / Policies                      │
│  (Stable year-over-year, rarely changes)           │
├─────────────────────────────────────────────────────┤
│  • Entity info (name, RCI, employee count)          │
│  • KYC procedures (EDD triggers, SDD policy)        │
│  • Compliance policies (training, updates)          │
└─────────────────────────────────────────────────────┘
                        │
                        ▼ (Annual event)
┌─────────────────────────────────────────────────────┐
│           Annual Submission                         │
│  (Lightweight - most work already done)            │
├─────────────────────────────────────────────────────┤
│  1. Review calculated aggregates (from CRM)         │
│  2. Confirm policies (from Settings)                │
│  3. Answer fresh questions (only what's needed)     │
│  4. Validate & download XBRL                        │
└─────────────────────────────────────────────────────┘
```

---

## Data Model Summary

### CRM Data (Year-Round)
- **Organization** - extends Jumpstart Account, has RCI number
- **Client** - natural persons (PP), legal entities (PM), trusts
- **BeneficialOwner** - for legal entities, ≥25% ownership
- **Transaction** - purchases, sales, rentals linked to clients
- **STRReport** - suspicious transaction reports

### Settings (Set Once)
- Key-value store with categories
- Maps directly to XBRL elements
- Categories: entity_info, kyc, compliance, training

### Submissions (Annual)
- **Submission** - year, status (draft → validated → completed)
- **SubmissionValue** - element_name, value, source (calculated/from_settings/manual)

---

## Monaco-Specific Details

- **Not SIRET** - Monaco uses "Registre du Commerce et d'Industrie" (RCI)
- **Entity identifier scheme:** `http://www.amsf.mc`
- **French taxonomy:** Boolean values are `Oui`/`Non`, not `true`/`false`
- **Strix portal:** FT Solutions platform for AMSF submissions

---

## XBRL Validation Progress

Successfully created and validated test XBRL file:

**Fixes applied:**
1. Changed `xbrli:schemaRef` to `link:schemaRef`
2. Used absolute path to schema file
3. Changed boolean values from `true/false` to `Oui/Non`
4. Fixed element names to match taxonomy (`a381` not `a380`)
5. Added `xmlns:iso4217` namespace for unit measures

**Test file:** `/Users/laurentcurau/projects/strix/test_submission_2025.xml`
**Status:** Validates with Arelle, ready for Strix portal test

---

## Implementation Phases

### Phase 1: Foundation ✅ In Progress
- [x] Set up Jumpstart Pro project
- [x] Update database names to immo_crm
- [x] Run bin/setup to initialize
- [ ] Create Organization model
- [ ] Create Settings model
- [ ] Basic dashboard skeleton

### Phase 2: CRM Core
- Client CRUD with Turbo Frames
- Beneficial owner CRUD
- Transaction CRUD
- STR report CRUD
- Dashboard with stats

### Phase 3: Settings & Policies
- Settings UI with categories
- XBRL element mapping

### Phase 4: Calculation Engine
- Aggregates from CRM data
- Unit tests for calculations

### Phase 5: Annual Submission Flow
- 4-step wizard
- SubmissionValue model

### Phase 6: XBRL & Validation
- Port generate_xbrl.py to Ruby
- Python validation microservice

### Phase 7: Polish & Beta
- Help text, guides
- Beta user recruitment

---

## MVP Scope

### In Scope
- User auth (Jumpstart Pro)
- Organization setup with RCI
- Dashboard with stats
- Client management with BOs
- Transaction logger
- STR reports
- Settings for policies
- 4-step submission flow
- Calculation engine
- XBRL generation (Ruby)
- XULE validation (Python)

### Out of Scope (Post-MVP)
- Excel import
- Email reminders
- Multi-industry taxonomies
- Advanced CRM features
- Direct Strix submission

---

## Open Questions / Next Steps

1. **Check with Adrien** on BO tracking needs (Monday)
2. **Interview cousin** (real estate agent) for user feedback
3. **Test Strix upload** when portal access available
4. **Use spec-kit** for structured implementation

---

## Technical Stack

- **Ruby:** 3.4.7
- **Rails:** 8.1.1 with Hotwire (Turbo + Stimulus)
- **CSS:** TailwindCSS v4
- **Database:** PostgreSQL (multi-database: primary, cache, queue, cable)
- **Auth:** Devise (via Jumpstart Pro)
- **Authorization:** Pundit
- **Background Jobs:** SolidQueue
- **Deployment:** Kamal to Hetzner VPS
- **XBRL Validation:** Python FastAPI + Arelle + XULE

---

## Design Document

Full MVP design document at:
`/Users/laurentcurau/projects/strix/docs/plans/2025-11-29-mvp-design.md`

---

## Project Location

**ImmoCRM codebase:** `/Users/laurentcurau/projects/immo_crm`
**XBRL taxonomy & tools:** `/Users/laurentcurau/projects/strix`
