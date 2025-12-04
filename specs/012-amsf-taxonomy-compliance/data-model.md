# Data Model: AMSF Taxonomy Compliance

**Branch**: `012-amsf-taxonomy-compliance`
**Date**: 2024-12-03

## Overview

This feature does not introduce new database models. Instead, it modifies how existing models interact with XBRL generation to produce taxonomy-compliant output.

## Existing Entities (No Schema Changes)

### SubmissionValue

Stores calculated XBRL element values for a submission.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Primary key |
| `submission_id` | integer | FK to Submission |
| `element_name` | string | XBRL element name (e.g., `a1101`) |
| `value` | string | Element value |
| `source` | string | `calculated`, `from_settings`, or `manual` |
| `overridden` | boolean | Whether user has manually overridden |
| `confirmed` | boolean | Whether value has been confirmed |

**Change Impact**: Element names stored here will change from invalid to valid taxonomy names. Existing records with invalid element names will be orphaned but not cause errors.

### Submission

Parent record for annual AMSF submission.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Primary key |
| `organization_id` | integer | FK to Organization (account scoping) |
| `year` | integer | Reporting year |
| `taxonomy_version` | string | Taxonomy version (e.g., "2025") |

**Change Impact**: None

### Client

Source data for client statistics calculations.

| Field | Type | Description |
|-------|------|-------------|
| `client_type` | enum | `natural_person`, `legal_entity`, `trust` |
| `nationality` | string | ISO 3166-1 alpha-2 country code |
| `is_pep` | boolean | Politically Exposed Person flag |
| `high_risk` | boolean | High-risk client flag |

**Change Impact**: No schema changes. Calculation queries remain the same, only output element names change.

### Transaction

Source data for transaction statistics calculations.

| Field | Type | Description |
|-------|------|-------------|
| `transaction_type` | enum | `purchase`, `sale`, `rental` |
| `transaction_value` | decimal | Value in EUR |
| `payment_method` | string | `CASH`, `MIXED`, `CRYPTO`, etc. |
| `cash_amount` | decimal | Cash portion if applicable |

**Change Impact**: No schema changes. W-suffix elements (WITH clients) deferred per clarification.

## Data Flow Changes

### Before (Invalid)

```
Client data → CalculationEngine → {"a1301" => 5, "a1103_FR" => 10}
                                       ↓
XbrlGenerator → <strix:a1301>5</strix:a1301>  ← INVALID ELEMENT
                <strix:a1103_FR>10</strix:a1103_FR>  ← INVALID ELEMENT
```

### After (Valid)

```
Client data → CalculationEngine → {"a12002B" => 5, "a1103" => {FR: 10, GB: 5}}
                                       ↓
XbrlGenerator → <strix:a12002B>5</strix:a12002B>  ← VALID
                <context id="ctx_country_FR">...</context>
                <strix:a1103 contextRef="ctx_country_FR">10</strix:a1103>  ← VALID
```

## Element Name Mapping Table

This table serves as the authoritative mapping for implementation:

| Current Element | New Element | Type | Notes |
|-----------------|-------------|------|-------|
| `a1101` | `a1101` | integer | ✓ Valid - no change |
| `a1102` | `a1102` | integer | ✓ Valid - no change |
| `a11502B` | `a11502B` | integer | ✓ Valid - no change |
| `a11802B` | `a11802B` | integer | ✓ Valid - no change |
| `a1301` | `a12002B` | integer | PEP clients |
| `a1401` | *(keep for now)* | integer | Needs semantic clarification |
| `a1501` | `a1501` | integer | ✓ Valid - no change |
| `a1502` | `a1502B` | integer | Add B suffix |
| `a2101B` | `a2101B` | integer | ✓ Valid - no change |
| `a2102` | `a2102B` | integer | Add B suffix |
| `a2103` | `a2105B` | integer | Sale txns, change prefix |
| `a2104` | `a2107B` | integer | Rental txns, change prefix |
| `a2104B` | `a2104B` | monetary | ✓ Valid - no change |
| `a2105` | `a2102BB` | monetary | Purchase value |
| `a2106` | `a2105BB` | monetary | Sale value |
| `a2107` | `a2107BB` | monetary | Rental value |
| `a2201` | `a2203` | integer | Cash txn count |
| `a2202` | `a2202` | monetary | ✓ Valid - no change |
| `a2301` | `a2501A` | integer | Crypto txns |
| `a2302` | *(remove)* | - | Combine with a2501A |
| `a2401` | *(remove)* | - | Not in taxonomy |
| `a3101` | `a3101` | integer | ✓ Valid - no change |
| `a1103_XX` | `a1103` + context | integer | Use dimensional context |

## Dimensional Context Structure

For country-specific data, XBRL uses dimensional contexts:

```xml
<!-- Context definition -->
<context id="ctx_country_{CODE}">
  <entity>
    <identifier scheme="http://amsf.mc/rci">{RCI_NUMBER}</identifier>
    <segment>
      <strix:CountryDimension>{CODE}</strix:CountryDimension>
    </segment>
  </entity>
  <period>
    <instant>{YEAR}-12-31</instant>
  </period>
</context>

<!-- Fact referencing dimensional context -->
<strix:a1103 contextRef="ctx_country_{CODE}" unitRef="unit_pure">{COUNT}</strix:a1103>
```

## Type Handling Reference

| Element Type | XBRL Type | Attributes | Value Format |
|--------------|-----------|------------|--------------|
| Integer counts | `xbrli:integerItemType` | `unitRef="unit_pure"` | Whole number |
| Monetary values | `xbrli:monetaryItemType` | `unitRef="unit_EUR"`, `decimals="2"` | `###.##` |
| French boolean | Custom enum | None | `Oui` or `Non` |
| String | `xbrli:stringItemType` | None | Text |

## Configuration File Structure

The `config/amsf_element_mapping.yml` must be restructured:

**Before** (invalid category keys):
```yaml
client_statistics:
  a1101:
    description: "..."
```

**After** (flat element keys):
```yaml
a1101:
  description: "Total number of clients"
  source: calculated
  type: integer

a12002B:
  description: "Number of PEP clients"
  source: calculated
  type: integer
```

Only valid taxonomy element names may be top-level keys.
