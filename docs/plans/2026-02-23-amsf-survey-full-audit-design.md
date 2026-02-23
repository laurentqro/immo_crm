# AMSF Survey Full Audit — Design

**Date:** 2026-02-23
**Goal:** A single Claude Code prompt that triggers a comprehensive end-to-end audit of ImmoCRM's AMSF survey support, verifying that the app captures, computes, displays, and exports all 323 questionnaire fields correctly.

## Problem

Seed data validates calculations but obscures whether the UI has the right fields to capture real user data. We need a systematic audit that checks every survey field across 4 layers.

## Authority Hierarchy

| Source | Authoritative For |
|--------|-------------------|
| XBRL labels (`_lab.xml`) | Field semantics — what each field means |
| Instructions PDF | Presentation — question numbering, section titles, section grouping, display order |
| `questionnaire_structure.yml` | Derived artifact merging XBRL + PDF; discrepancies with either source are gem-level bugs |

## Audit Layers

### L1: Data Capture
Can the user enter all raw data needed for every survey field?

- Every model field referenced by `survey/fields/*.rb` must have a corresponding UI input
- Enum values in the UI must match AMSF-defined values
- Settings pages must expose all keys read by `setting_value()`

### L2: Calculation Correctness
Does each `Survey::Fields` method compute the semantically correct value?

For each of 323 fields:
1. Read the XBRL label (French) to understand what the field *means*
2. Classify as: computed-from-DB / fetched-from-settings / hardcoded
3. Verify query/logic matches the semantic meaning
4. Check filters are correct (e.g., excludes trusts where it should)
5. **ZERO TOLERANCE for defaults/fallbacks** — any hardcoded value (0, `""`, `{}`, `nil`, `false`) instead of real data/query = automatic FAIL

### L3: Review Display
Does the submission review page show all 323 fields correctly?

- Every field_id in questionnaire_structure.yml appears on the review page
- Grouping matches parts/sections per the instructions PDF
- Display format matches field type (currency, boolean, dimensional, text)
- Question numbering and section titles match the instructions PDF

### L4: XBRL Correctness
Does the generated XBRL match the taxonomy?

- Field IDs map to correct XBRL codes
- Dimensional fields have correct member values
- No orphan fields (in code but not in taxonomy, or vice versa)

## Cross-Source Consistency Check

Flag any discrepancies between `questionnaire_structure.yml` and its sources:
- Field placement vs instructions PDF section numbering
- Field labels vs XBRL label text
- Missing or extra fields relative to XBRL taxonomy

## Zero-Tolerance Rules

1. **No defaults/fallbacks** — ever. Every field must derive from real data.
2. **Every field audited** — all 323, no sampling.
3. **XBRL label is semantic truth** — if code computes something different from what the label says, it's wrong.
4. **PDF is presentation truth** — if the review page groups or numbers differently from the PDF, it's wrong.

## Output

### Deliverable 1: Structured Report
`docs/audits/YYYY-MM-DD-amsf-survey-audit.md` with per-part sections. Each field listed with:
- Field ID, XBRL label (French), question number
- Verdict per layer: PASS / FAIL / PARTIAL
- Failure reason (specific and actionable)

### Deliverable 2: Summary Statistics
- Total fields: 323
- L1/L2/L3/L4 pass rates
- Critical failures list sorted by severity

### Deliverable 3: GitHub Issues
One issue per actionable gap:
- Title: `[AMSF Audit] L{n}: {field_id} — {short description}`
- Body: what's wrong, what correct looks like, which files to change
- Labels: `amsf-survey`, `bug` or `enhancement`

## Reference File Paths

| File | Path |
|------|------|
| Survey PORO | `app/models/survey.rb` |
| Field modules | `app/models/survey/fields/*.rb` (5 files + helpers) |
| Client model | `app/models/client.rb` |
| Beneficial Owner model | `app/models/beneficial_owner.rb` |
| Trustee model | `app/models/trustee.rb` |
| Transaction model | `app/models/transaction.rb` |
| Setting model | `app/models/setting.rb` |
| Organization model | `app/models/organization.rb` |
| Submission controller | `app/controllers/submissions_controller.rb` |
| Review page | `app/views/submissions/review.html.erb` |
| Question partial | `app/views/submissions/_survey_question.html.erb` |
| Client forms | `app/views/clients/` |
| BO forms | `app/views/beneficial_owners/` |
| Transaction forms | `app/views/transactions/` |
| Settings views | `app/views/settings/` |
| AMSF constants | `app/models/concerns/amsf_constants.rb` |
| DB schema | `db/schema.rb` |
| Instructions PDF | `docs/AMSF_Instructions questionnaire real estate_VGB_250313.pdf` |
| Questionnaire structure | `/Users/laurentcurau/projects/amsf_survey/amsf_survey-real_estate/taxonomies/2025/questionnaire_structure.yml` |
| XBRL labels | `/Users/laurentcurau/projects/amsf_survey/amsf_survey-real_estate/taxonomies/2025/strix_Real_Estate_AML_CFT_survey_2025_lab.xml` |

## Execution Strategy

Use parallel subagents where layers are independent:
- L1 (Data Capture) and L3 (Review Display) can run in parallel
- L2 (Calculation Correctness) is the heaviest — may need to be broken into field module chunks
- L4 (XBRL Correctness) can run in parallel with L1/L3
- Final consolidation merges all layer results into the report

---

## The Prompt

```
You are auditing ImmoCRM's AMSF survey support. The app must capture, compute, display, and export all 323 regulatory questionnaire fields correctly so that a Monaco real estate professional can submit their annual AMSF survey in one click.

## Your Mission

Perform a full end-to-end audit across 4 layers, producing a structured report, summary statistics, and GitHub issues for every failure.

## Authority Hierarchy

- **XBRL labels** (`strix_Real_Estate_AML_CFT_survey_2025_lab.xml`) = source of truth for field SEMANTICS (what each field means)
- **Instructions PDF** (`docs/AMSF_Instructions questionnaire real estate_VGB_250313.pdf`) = source of truth for PRESENTATION (question numbering, section titles/numbering, grouping, display order)
- **`questionnaire_structure.yml`** = derived artifact merging both sources. Discrepancies with XBRL or PDF are gem-level bugs to flag.

## Reference Files

ImmoCRM app (working directory):
- Survey PORO: `app/models/survey.rb`
- Field modules: `app/models/survey/fields/customer_risk.rb`, `products_services_risk.rb`, `distribution_risk.rb`, `controls.rb`, `signatories.rb`, `helpers.rb`
- Models: `app/models/client.rb`, `app/models/beneficial_owner.rb`, `app/models/trustee.rb`, `app/models/transaction.rb`, `app/models/setting.rb`, `app/models/organization.rb`
- Constants: `app/models/concerns/amsf_constants.rb`
- Submission review: `app/views/submissions/review.html.erb`, `app/views/submissions/_survey_question.html.erb`
- Client forms: `app/views/clients/`
- Beneficial owner forms: `app/views/beneficial_owners/`
- Transaction forms: `app/views/transactions/`
- Settings views: `app/views/settings/`
- DB schema: `db/schema.rb`
- Instructions PDF: `docs/AMSF_Instructions questionnaire real estate_VGB_250313.pdf`

AMSF Survey gem (external):
- Questionnaire structure: `/Users/laurentcurau/projects/amsf_survey/amsf_survey-real_estate/taxonomies/2025/questionnaire_structure.yml`
- XBRL labels: `/Users/laurentcurau/projects/amsf_survey/amsf_survey-real_estate/taxonomies/2025/strix_Real_Estate_AML_CFT_survey_2025_lab.xml`

## Audit Layers

### Layer 1: Data Capture
For every survey field, trace backward to the raw data it needs. Verify:
- The corresponding model has the database column/association
- A UI form exists with an input for that data
- Enum values in the UI match AMSF-defined values
- Settings keys read by `setting_value()` are exposed on a settings page

### Layer 2: Calculation Correctness
For EACH of the 323 fields in `survey/fields/*.rb`:
1. Read the French XBRL label to understand what the field MEANS
2. Classify the method as: computed-from-DB / fetched-from-settings / hardcoded
3. If computed-from-DB: verify the ActiveRecord query is semantically correct (right model, right filters, right aggregation)
4. If fetched-from-settings: verify the setting key matches the intended data
5. If hardcoded: **automatic FAIL** — NO DEFAULT OR FALLBACK VALUES ALLOWED, EVER. Any method returning a hardcoded 0, empty string, empty hash, nil, false, or any constant instead of querying real data is a failure.
6. Check filter correctness (e.g., legal entity counts excluding trusts where required, year scoping on transactions)
7. Cross-reference the computation against what the XBRL label says the field represents

### Layer 3: Review Display
Compare the submission review page against the questionnaire structure and PDF:
- Every field_id in questionnaire_structure.yml appears on the review page
- Question numbering matches the instructions PDF
- Section titles and grouping match the instructions PDF
- Display format is appropriate for field type (currency with €, boolean as Oui/Non, dimensional as tables, etc.)

### Layer 4: XBRL Correctness
Verify the mapping between app field IDs and XBRL taxonomy:
- Every field_id maps to a valid XBRL code in the taxonomy
- Dimensional fields produce correct member values (e.g., legal entity type → XBRL dimension members)
- No orphan fields exist (in code but not taxonomy, or vice versa)

### Cross-Source Consistency
Flag discrepancies between `questionnaire_structure.yml` and its authoritative sources:
- Field placement vs PDF section numbering
- Field labels vs XBRL label text
- Missing or extra fields relative to XBRL taxonomy

## Zero-Tolerance Rules

1. **No defaults/fallbacks** — EVER. Every field must derive from real data (DB query or settings). Hardcoded values = FAIL.
2. **Every field audited** — all 323. No sampling, no skipping.
3. **XBRL label is semantic truth** — if code computes something different from what the French label says, it's wrong.
4. **PDF is presentation truth** — if the review page numbers or groups differently from the PDF, it's wrong.

## Execution Strategy

Use parallel subagents to maximize throughput:
- Run L1 (Data Capture), L3 (Review Display), and L4 (XBRL Correctness) in parallel
- Run L2 (Calculation Correctness) broken into chunks by field module (customer_risk, products_services_risk, distribution_risk, controls, signatories)
- Consolidate all results into the final report

## Output

### Deliverable 1: Structured Audit Report
Write to `docs/audits/2026-02-23-amsf-survey-audit.md`.

Organize by questionnaire part, then section. For each field:
```
#### {question_number} — {field_id}
**XBRL Label:** {French label text}
| Layer | Verdict | Detail |
|-------|---------|--------|
| L1 Data Capture | PASS/FAIL/PARTIAL | {specific finding} |
| L2 Calculation | PASS/FAIL/PARTIAL | {specific finding} |
| L3 Review Display | PASS/FAIL/PARTIAL | {specific finding} |
| L4 XBRL | PASS/FAIL/PARTIAL | {specific finding} |
```

### Deliverable 2: Summary Statistics
At the top of the report:
- Total fields: 323
- Per-layer pass/fail/partial counts and percentages
- Critical failures list (sorted by severity)
- Cross-source inconsistencies list

### Deliverable 3: GitHub Issues
After the report is complete, create one GitHub issue per actionable failure:
- Title: `[AMSF Audit] L{n}: {field_id} — {short description}`
- Body: what's wrong, what correct looks like, which files need changes
- Labels: `amsf-survey` + `bug` or `enhancement`

Begin the audit now.
```
