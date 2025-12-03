# XBRL Gap Analysis Report

**Date:** December 2024
**Taxonomy:** AMSF Real Estate AML/CFT Survey 2025
**Schema:** `strix_Real_Estate_AML_CFT_survey_2025.xsd`

## Executive Summary

| Metric | Count |
|--------|-------|
| **Total taxonomy elements** | 321 |
| **Our mapped elements (before fix)** | 49 |
| **Elements correctly matching taxonomy** | 11 (22%) |
| **Elements NOT in taxonomy (wrong names)** | 38 (78%) |
| **Taxonomy coverage (before fix)** | ~3.4% |

## Critical Issues Found

### 1. Wrong Element Names (38 elements)

Our original mapping used element names that **don't exist** in the XBRL taxonomy:

| Our Element | Issue | Correct Element |
|-------------|-------|-----------------|
| `a0101-a0104` | Entity identification | Not in taxonomy - handled differently |
| `a1001-a1003` | Entity info | Not in taxonomy |
| `a1301` | PEP clients | Does not exist - use `a12002B` |
| `a1502` | PEP beneficial owners | Should be `a1502B` |
| `a2102` | Purchase transactions | Should be `a2102B` |
| `a2103` | Sale transactions | Should be `a2105B` |
| `a2104` | Rental transactions | Should be `a2107B` |
| `a2105` | Purchase value | Should be `a2102BB` |
| `a2106` | Sale value | Should be `a2105BB` |
| `a2107` | Rental value | Different structure |
| `a2201` | Cash transaction count | Should be `a2203` |
| `a2301-a2302` | Crypto transactions | Use `a2501A` |
| `a2401` | PEP transactions | Not in taxonomy |
| `a4101-a4206` | KYC/Compliance | Controls use `aCxxxx` prefix |
| `a5101-a5104` | Training | Use `aC1301-aC1304` |
| `a6101-a6103` | Monitoring | Use `aC1801-aC1807` |

### 2. Elements We Had Correctly

Only 11 elements were correctly mapped:

| Element | Description | Status |
|---------|-------------|--------|
| `a1101` | Total number of unique clients | Correct |
| `a1102` | Natural persons - nationals | **Semantic mismatch** - we used for "all natural persons" |
| `a1103` | Natural persons - foreign residents | **Semantic mismatch** - we used for nationality breakdown |
| `a11502B` | Legal entity clients | Correct |
| `a11802B` | Trust clients | Correct |
| `a1401` | Natural persons for purchase/sale | **Semantic mismatch** - we used for "high-risk clients" |
| `a1501` | Total beneficial owners identified | Correct |
| `a2101B` | Total transactions | Correct |
| `a2104B` | Total transaction value | Correct |
| `a2202` | Cash amount | Correct |
| `a3101` | STRs filed | Correct |

### 3. Missing Taxonomy Elements

The taxonomy has 321 elements. We were missing coverage for:

| Section | Elements | Our Coverage |
|---------|----------|--------------|
| **Tab 1 (Customer Risk)** | 104 | ~8 elements |
| **Tab 2 (Products/Services)** | 37 | ~3 elements |
| **Tab 3 (Distribution Risk)** | 44 | ~1 element |
| **Tab 4 (Controls)** | 105 (`aCxxxx`) | **0 elements** |
| **Calculated Risk** | 19 (`aIRxxx`) | **0 elements** |
| **Signatories** | 2 (`aS1`, `aS2`) | **0 elements** |

### 4. Semantic Misunderstandings

The taxonomy uses specific suffixes with meaning:

| Suffix | Meaning | Example |
|--------|---------|---------|
| `B` | "By clients" (client-initiated operations) | `a1105B` = Operations BY clients |
| `W` | "With clients" (agent fees/commissions) | `a1105W` = Operations WITH clients |
| `R` | Rentals only | `a1401R` = Natural persons for rentals |
| `TOLA` | Trusts and Other Legal Arrangements | `a1802TOLA` = TOLA clients |
| `BB` | By clients - value (EUR) | `a2102BB` = Purchase value BY clients |
| `BW` | With clients - value (EUR) | `a2102BW` = Commission value |

**Key architectural difference:** The taxonomy separates operations BY clients (they pay/receive) vs WITH clients (agent fees/commissions). Our `Transaction` model doesn't distinguish this.

## Data Model Gaps

### Client Model Missing Fields

| Field | Purpose | Required By Elements |
|-------|---------|---------------------|
| `residence_status` | national/foreign_resident/non_resident | `a1102`, `a1103`, `a1104` |
| `is_hnwi` | High Net Worth Individual (>5M EUR) | `a112012B` |
| `is_uhnwi` | Ultra HNWI (>50M EUR) | `a11206B` |
| `is_pep_related` | Related to a PEP | `a12102B` |
| `is_pep_associated` | Closely associated with PEP | `a12202B` |

### Transaction Model Missing Fields

| Field | Purpose | Required By Elements |
|-------|---------|---------------------|
| `direction` | `by_client` vs `with_client` | All B/W suffix elements |
| `is_recurring` | Recurring payment flag | `a2101WRP`, `a2104WRP` |
| `commission_amount` | Agent commission for transaction | `a2102BW`, `a2105BW` |

### BeneficialOwner Model Missing Fields

| Field | Purpose | Required By Elements |
|-------|---------|---------------------|
| `ownership_percentage` | For 25%+ filtering | `a1202OB` |
| `residence_country` | BO residence | `a1203D` |

### Settings Model Missing Fields

The Settings model needs **105 new boolean/enum fields** to support the Controls section (`aCxxxx` elements). See `config/amsf_element_mapping.yml` for full list.

## Remediation Steps

### Completed

1. **Updated `config/amsf_element_mapping.yml`** - Now correctly maps to all 321 taxonomy elements with proper naming

### In Progress

2. **Update `CalculationEngine`** - Fix element names and add new calculations

### Pending

3. **Database migrations** - Add missing fields to Client, Transaction, BeneficialOwner models
4. **Settings expansion** - Add all Controls section fields to Settings model
5. **XbrlGenerator updates** - Handle B/W suffix elements properly
6. **Wizard updates** - Add Controls and Signatories steps
7. **Dimensional contexts** - Implement CountryDimension for nationality breakdowns

## Element Categories

### Tab 1: Customer Risk (104 elements)

- Client counts by type (natural person, legal entity, trust)
- Client counts by residence status
- Operation counts and values (B/W suffix)
- Beneficial ownership statistics
- PEP and high-risk country exposure
- VASP/crypto client statistics

### Tab 2: Products & Services Risk (37 elements)

- Transaction counts by type (purchase, sale, rental)
- Transaction values by direction (B/W suffix)
- Payment method statistics (cash, virtual assets)
- Recurring payment tracking

### Tab 3: Distribution Risk (44 elements)

- STR statistics by client type
- Client identification methods
- Business structure information
- Source of funds/wealth verification

### Tab 4: Controls (105 elements)

All use `aCxxxx` naming convention:

- Governance (`aC1101Z`, `aC1102`, etc.)
- Risk Assessment (`aC11101-aC11105`)
- CDD Procedures (`aC11201-aC11307`)
- EDD Procedures (`aC114xx`)
- Compliance Function (`aC1201-aC1209C`)
- Training (`aC1301-aC1304`)
- STR Procedures (`aC1401-aC1403`)
- Sanctions/TFS (`aC1501-aC1518A`)
- PEP Procedures (`aC1601-aC1619`)
- Technology Controls (`aC1701-aC171`)
- Audit (`aC1801-aC1814W`)
- Record Keeping (`aC1904`)

### Tab 5: Signatories (2 elements)

- `aS1` - Authorized signatory name
- `aS2` - Authorized signatory title/position

### Calculated Risk Indicators (19 elements)

Auto-calculated by XBRL validator based on responses:

- `aIR117` - Customer type risk score
- `aIR233` - Product risk score
- `aIR236` - Overall inherent risk
- `aIR237B` - Control effectiveness
- `aIR238B` - Residual risk
- etc.

## Priority Order for Implementation

1. **High Priority** - Fix CalculationEngine element names
2. **High Priority** - Add Client.residence_status field
3. **Medium Priority** - Add Controls settings fields
4. **Medium Priority** - Add Signatories to wizard
5. **Lower Priority** - Add Transaction.direction for B/W split
6. **Lower Priority** - Implement VASP client tracking
