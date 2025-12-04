# AMSF Taxonomy 100% Coverage Gap Analysis

**Generated:** 2025-12-03 23:05
**Objective:** Identify all model changes needed to answer 323 taxonomy questions

---

## Executive Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ COMPLETE | 21 | 6.5% |
| ⚠️ PARTIAL | 43 | 13.3% |
| ❌ MISSING | 165 | 51.1% |
| ⏭️ N/A (auto-calc) | 21 | 6.5% |
| ❓ UNKNOWN | 73 | 22.6% |
| **TOTAL** | **323** | **100%** |

---

## Current Model Fields

### Client

**Existing fields:** `name`, `client_type`, `nationality`, `residence_country`, `is_pep`, `pep_type`, `is_vasp`, `vasp_type`, `risk_level`, `legal_person_type`, `business_sector`, `became_client_at`, `relationship_ended_at`, `rejection_reason`, `notes`

### Transaction

**Existing fields:** `transaction_date`, `transaction_type`, `transaction_value`, `payment_method`, `cash_amount`, `commission_amount`, `agency_role`, `purchase_purpose`, `property_country`, `reference`, `notes`

### BeneficialOwner

**Existing fields:** `name`, `nationality`, `residence_country`, `ownership_pct`, `control_type`, `is_pep`, `pep_type`

### StrReport

**Existing fields:** `report_date`, `reason`, `notes`, `client_id`, `transaction_id`

### Setting

**Existing fields:** `key`, `value`, `value_type`, `category`, `xbrl_element`

### Organization

**Existing fields:** `name`, `rci_number`

### Submission

**Existing fields:** `year`, `status`

---

## Missing Fields by Model

### Client

| Missing Field | Required For Elements |
|--------------|----------------------|
| `Client.residence_status (national/foreign_resident/non_resident)` | a1104 |
| `Transaction.direction (by_client/with_client)` | a1105W |
| `Transaction.direction` | a1106W |
| `Client.is_hnwi or Client.net_worth_bracket` | a112012B |
| `Client.is_high_risk_country or derive from nationality/residence` | a11201BCD, a11201BCDU, a11301 |
| `Client.is_uhnwi or Client.net_worth_bracket` | a11206B |
| `Client.is_nonprofit or derive from legal_person_type` | a11602B |
| `Better: Client.incorporation_country` | a11702B |
| `Client.is_pep_related` | a12102B |
| `Client.is_pep_associated` | a12202B |
| `Various Client risk category flags` | a12302B, a12402B, a12502B, a12602B, a12702B, ... |

### BeneficialOwner

| Missing Field | Required For Elements |
|--------------|----------------------|
| `BeneficialOwner category fields` | a1202O, a1202OB, a1204O, a1207O, a1210O |

### Transaction

| Missing Field | Required For Elements |
|--------------|----------------------|
| `Transaction.direction` | a2101W, a2102BW, a2102W, a2104W, a2105BW, ... |
| `Transaction.is_recurring` | a2101WRP, a2104WRP, a2107WRP |
| `Transaction sub-categorization fields` | a2110B, a2110W, a2113AB, a2113AW, a2113B, ... |
| `More detailed VASP tracking` | a2501, a2501A |

### StrReport

| Missing Field | Required For Elements |
|--------------|----------------------|
| `StrReport.client_type or derive from client` | a3103, a3104, a3105 |

### Client/StrReport

| Missing Field | Required For Elements |
|--------------|----------------------|
| `Multiple fields for client identification methods` | a3201, a3202, a3203, a3204, a3205, ... |

### Organization

| Missing Field | Required For Elements |
|--------------|----------------------|
| `Organization metadata fields` | aACTIVE, aACTIVEPS, aACTIVERENTALS, aB1801B, aB3206, ... |

### Setting

| Missing Field | Required For Elements |
|--------------|----------------------|
| `Setting with key='aC1101Z'` | aC1101Z |
| `Setting with key='aC1102'` | aC1102 |
| `Setting with key='aC1102A'` | aC1102A |
| `Setting with key='aC1106'` | aC1106 |
| `Setting with key='aC11101'` | aC11101 |
| `Setting with key='aC11102'` | aC11102 |
| `Setting with key='aC11103'` | aC11103 |
| `Setting with key='aC11104'` | aC11104 |
| `Setting with key='aC11105'` | aC11105 |
| `Setting with key='aC11201'` | aC11201 |
| `Setting with key='aC1125A'` | aC1125A |
| `Setting with key='aC11301'` | aC11301 |
| `Setting with key='aC11302'` | aC11302 |
| `Setting with key='aC11303'` | aC11303 |
| `Setting with key='aC11304'` | aC11304 |
| `Setting with key='aC11305'` | aC11305 |
| `Setting with key='aC11306'` | aC11306 |
| `Setting with key='aC11307'` | aC11307 |
| `Setting with key='aC114'` | aC114 |
| `Setting with key='aC11401'` | aC11401 |
| `Setting with key='aC11402'` | aC11402 |
| `Setting with key='aC11403'` | aC11403 |
| `Setting with key='aC11501B'` | aC11501B |
| `Setting with key='aC11502'` | aC11502 |
| `Setting with key='aC11504'` | aC11504 |
| `Setting with key='aC11508'` | aC11508 |
| `Setting with key='aC11601'` | aC11601 |
| `Setting with key='aC116A'` | aC116A |
| `Setting with key='aC1201'` | aC1201 |
| `Setting with key='aC1202'` | aC1202 |
| `Setting with key='aC1203'` | aC1203 |
| `Setting with key='aC1204'` | aC1204 |
| `Setting with key='aC1205'` | aC1205 |
| `Setting with key='aC1206'` | aC1206 |
| `Setting with key='aC1207'` | aC1207 |
| `Setting with key='aC1208'` | aC1208 |
| `Setting with key='aC1209'` | aC1209 |
| `Setting with key='aC1209B'` | aC1209B |
| `Setting with key='aC1209C'` | aC1209C |
| `Setting with key='aC12236'` | aC12236 |
| `Setting with key='aC12237'` | aC12237 |
| `Setting with key='aC12333'` | aC12333 |
| `Setting with key='aC1301'` | aC1301 |
| `Setting with key='aC1302'` | aC1302 |
| `Setting with key='aC1303'` | aC1303 |
| `Setting with key='aC1304'` | aC1304 |
| `Setting with key='aC1401'` | aC1401 |
| `Setting with key='aC1402'` | aC1402 |
| `Setting with key='aC1403'` | aC1403 |
| `Setting with key='aC1501'` | aC1501 |
| `Setting with key='aC1503B'` | aC1503B |
| `Setting with key='aC1506'` | aC1506 |
| `Setting with key='aC1518A'` | aC1518A |
| `Setting with key='aC1601'` | aC1601 |
| `Setting with key='aC1602'` | aC1602 |
| `Setting with key='aC1608'` | aC1608 |
| `Setting with key='aC1609'` | aC1609 |
| `Setting with key='aC1610'` | aC1610 |
| `Setting with key='aC1611'` | aC1611 |
| `Setting with key='aC1612'` | aC1612 |
| `Setting with key='aC1612A'` | aC1612A |
| `Setting with key='aC1614'` | aC1614 |
| `Setting with key='aC1615'` | aC1615 |
| `Setting with key='aC1616A'` | aC1616A |
| `Setting with key='aC1616B'` | aC1616B |
| `Setting with key='aC1616C'` | aC1616C |
| `Setting with key='aC1617'` | aC1617 |
| `Setting with key='aC1618'` | aC1618 |
| `Setting with key='aC1619'` | aC1619 |
| `Setting with key='aC1620'` | aC1620 |
| `Setting with key='aC1621'` | aC1621 |
| `Setting with key='aC1622A'` | aC1622A |
| `Setting with key='aC1622B'` | aC1622B |
| `Setting with key='aC1622F'` | aC1622F |
| `Setting with key='aC1625'` | aC1625 |
| `Setting with key='aC1626'` | aC1626 |
| `Setting with key='aC1627'` | aC1627 |
| `Setting with key='aC1629'` | aC1629 |
| `Setting with key='aC1630'` | aC1630 |
| `Setting with key='aC1631'` | aC1631 |
| `Setting with key='aC1633'` | aC1633 |
| `Setting with key='aC1634'` | aC1634 |
| `Setting with key='aC1635'` | aC1635 |
| `Setting with key='aC1635A'` | aC1635A |
| `Setting with key='aC1636'` | aC1636 |
| `Setting with key='aC1637'` | aC1637 |
| `Setting with key='aC1638A'` | aC1638A |
| `Setting with key='aC1639A'` | aC1639A |
| `Setting with key='aC1640A'` | aC1640A |
| `Setting with key='aC1641A'` | aC1641A |
| `Setting with key='aC1642A'` | aC1642A |
| `Setting with key='aC168'` | aC168 |
| `Setting with key='aC1701'` | aC1701 |
| `Setting with key='aC1702'` | aC1702 |
| `Setting with key='aC1703'` | aC1703 |
| `Setting with key='aC171'` | aC171 |
| `Setting with key='aC1801'` | aC1801 |
| `Setting with key='aC1802'` | aC1802 |
| `Setting with key='aC1806'` | aC1806 |
| `Setting with key='aC1807'` | aC1807 |
| `Setting with key='aC1811'` | aC1811 |
| `Setting with key='aC1812'` | aC1812 |
| `Setting with key='aC1813'` | aC1813 |
| `Setting with key='aC1814W'` | aC1814W |
| `Setting with key='aC1904'` | aC1904 |

### Submission

| Missing Field | Required For Elements |
|--------------|----------------------|
| `Submission.signatory_name` | aS1 |
| `Submission.signatory_title` | aS2 |

---

## Detailed Element Analysis

### Tab 1: Customer Risk (a1xxx)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `a11001BTOLA` | enum | Unknown | ❓ | Needs analysis |
| `a11006` | string | Unknown | ❓ | Needs analysis |
| `a1101` | integer | Client | ✅ | Count all clients |
| `a1102` | integer | Client | ✅ | Count natural persons (PP) |
| `a1103` | integer | Client | ✅ | Clients by nationality |
| `a1104` | integer | Client | ❌ | Count non-resident clients |
| `a1105B` | integer | Client | ⚠️ | Operations BY clients - count |
| `a1105W` | integer | Client | ⚠️ | Operations WITH clients (agent) - count |
| `a1106B` | monetary | Client | ⚠️ | Operations BY clients - total value |
| `a1106BRENTALS` | monetary | Transaction | ✅ | Rental value BY clients |
| `a1106W` | monetary | Client | ⚠️ | Operations WITH clients (agent) - total value |
| `a112012B` | integer | Client | ❌ | High-net-worth clients (>5M EUR) |
| `a11201BCD` | enum | Client | ⚠️ | High-risk country clients |
| `a11201BCDU` | enum | Client | ⚠️ | High-risk country clients |
| `a11206B` | integer | Client | ❌ | Ultra high-net-worth clients (>50M EUR) |
| `a11301` | enum | Client | ⚠️ | High-risk country clients |
| `a11302` | integer | Client | ⚠️ | High-risk country count |
| `a11302RES` | integer | Client | ⚠️ | High-risk country count |
| `a11304B` | integer | Unknown | ❓ | Needs analysis |
| `a11305B` | monetary | Unknown | ❓ | Needs analysis |
| `a11307` | integer | Unknown | ❓ | Needs analysis |
| `a11309B` | integer | Unknown | ❓ | Needs analysis |
| `a11502B` | integer | Client | ✅ | Legal entity clients (PM) |
| `a11602B` | integer | Client | ❌ | Non-profit legal entities |
| `a11702B` | integer | Client | ⚠️ | Foreign legal entities |
| `a11802B` | integer | Client | ✅ | Trust clients |
| `a12002B` | integer | Client | ✅ | PEP clients |
| `a1202O` | integer | BeneficialOwner | ⚠️ | BO by category |
| `a1202OB` | integer | BeneficialOwner | ⚠️ | BO by category |
| `a1203` | enum | Unknown | ❓ | Needs analysis |
| `a1203D` | enum | Unknown | ❓ | Needs analysis |
| `a120425O` | integer | Unknown | ❓ | Needs analysis |
| `a1204O` | enum | BeneficialOwner | ⚠️ | BO by category |
| `a1204S` | enum | Unknown | ❓ | Needs analysis |
| `a1204S1` | complex | Unknown | ❓ | Needs analysis |
| `a1207O` | integer | BeneficialOwner | ⚠️ | BO by category |
| `a12102B` | integer | Client | ❌ | PEP-related clients (family) |
| `a1210O` | integer | BeneficialOwner | ⚠️ | BO by category |
| `a12202B` | integer | Client | ❌ | PEP-associated clients (close associates) |
| `a12302B` | integer | Client | ❌ | Other risk category clients |
| `a12302C` | integer | Unknown | ❓ | Needs analysis |
| `a12402B` | integer | Client | ❌ | Other risk category clients |
| `a12502B` | integer | Client | ❌ | Other risk category clients |
| `a12602B` | integer | Client | ❌ | Other risk category clients |
| `a12702B` | integer | Client | ❌ | Other risk category clients |
| `a12802B` | integer | Client | ❌ | Other risk category clients |
| `a12902B` | integer | Client | ❌ | Other risk category clients |
| `a13002B` | integer | Client | ❌ | Other risk category clients |
| `a13202B` | integer | Client | ❌ | Other risk category clients |
| `a13302B` | integer | Unknown | ❓ | Needs analysis |
| `a13402B` | integer | Unknown | ❓ | Needs analysis |
| `a13501B` | enum | Unknown | ❓ | Needs analysis |
| `a13601` | enum | Unknown | ❓ | Needs analysis |
| `a13601A` | enum | Unknown | ❓ | Needs analysis |
| `a13601B` | enum | Unknown | ❓ | Needs analysis |
| `a13601C` | enum | Unknown | ❓ | Needs analysis |
| `a13601C2` | enum | Unknown | ❓ | Needs analysis |
| `a13601CW` | enum | Unknown | ❓ | Needs analysis |
| `a13601EP` | enum | Unknown | ❓ | Needs analysis |
| `a13601ICO` | enum | Unknown | ❓ | Needs analysis |
| `a13601OTHER` | enum | Unknown | ❓ | Needs analysis |
| `a13602A` | integer | Unknown | ❓ | Needs analysis |
| `a13602B` | integer | Unknown | ❓ | Needs analysis |
| `a13602C` | integer | Unknown | ❓ | Needs analysis |
| `a13602D` | integer | Unknown | ❓ | Needs analysis |
| `a13603AB` | integer | Unknown | ❓ | Needs analysis |
| `a13603BB` | integer | Unknown | ❓ | Needs analysis |
| `a13603CACB` | integer | Unknown | ❓ | Needs analysis |
| `a13603DB` | integer | Unknown | ❓ | Needs analysis |
| `a13604AB` | monetary | Unknown | ❓ | Needs analysis |
| `a13604BB` | monetary | Unknown | ❓ | Needs analysis |
| `a13604CB` | monetary | Unknown | ❓ | Needs analysis |
| `a13604DB` | monetary | Unknown | ❓ | Needs analysis |
| `a13604E` | string | Unknown | ❓ | Needs analysis |
| `a13702B` | integer | Unknown | ❓ | Needs analysis |
| `a13802B` | integer | Unknown | ❓ | Needs analysis |
| `a13902B` | integer | Unknown | ❓ | Needs analysis |
| `a14001` | string | Unknown | ❓ | Needs analysis |
| `a1401` | integer | Client | ✅ | High-risk clients count |
| `a1401R` | integer | Unknown | ❓ | Needs analysis |
| `a1402` | integer | Unknown | ❓ | Needs analysis |
| `a1403B` | integer | Unknown | ❓ | Needs analysis |
| `a1403R` | integer | Unknown | ❓ | Needs analysis |
| `a1404B` | monetary | Unknown | ❓ | Needs analysis |
| `a14102B` | integer | Unknown | ❓ | Needs analysis |
| `a14202B` | integer | Unknown | ❓ | Needs analysis |
| `a14302B` | integer | Unknown | ❓ | Needs analysis |
| `a14402B` | integer | Unknown | ❓ | Needs analysis |
| `a14502B` | integer | Unknown | ❓ | Needs analysis |
| `a14602B` | integer | Unknown | ❓ | Needs analysis |
| `a14702B` | integer | Unknown | ❓ | Needs analysis |
| `a14801` | enum | Unknown | ❓ | Needs analysis |
| `a1501` | integer | BeneficialOwner | ✅ | Total beneficial owners identified |
| `a1502B` | integer | BeneficialOwner | ✅ | PEP beneficial owners |
| `a1503B` | monetary | Unknown | ❓ | Needs analysis |
| `a155` | enum | Unknown | ❓ | Needs analysis |
| `a1801` | enum | Unknown | ❓ | Needs analysis |
| `a1802BTOLA` | enum | Unknown | ❓ | Needs analysis |
| `a1802TOLA` | integer | Unknown | ❓ | Needs analysis |
| `a1806TOLA` | integer | Unknown | ❓ | Needs analysis |
| `a1807ATOLA` | integer | Unknown | ❓ | Needs analysis |
| `a1807TOLA` | monetary | Unknown | ❓ | Needs analysis |
| `a1808` | integer | Unknown | ❓ | Needs analysis |
| `a1809` | integer | Unknown | ❓ | Needs analysis |

### Tab 2: Products & Services (a2xxx)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `a2101B` | enum | Transaction | ✅ | Transaction indicator BY clients |
| `a2101W` | enum | Transaction | ❌ | Transaction indicator WITH clients |
| `a2101WRP` | enum | Transaction | ❌ | Recurring payments indicator |
| `a2102B` | integer | Transaction | ✅ | Transaction indicator BY clients |
| `a2102BB` | monetary | Transaction | ✅ | Transaction value BY clients |
| `a2102BW` | monetary | Transaction | ❌ | Transaction value WITH clients |
| `a2102W` | integer | Transaction | ❌ | Transaction indicator WITH clients |
| `a2104B` | enum | Transaction | ✅ | Transaction indicator BY clients |
| `a2104W` | enum | Transaction | ❌ | Transaction indicator WITH clients |
| `a2104WRP` | enum | Transaction | ❌ | Recurring payments indicator |
| `a2105B` | integer | Transaction | ✅ | Transaction indicator BY clients |
| `a2105BB` | monetary | Transaction | ✅ | Transaction value BY clients |
| `a2105BW` | monetary | Transaction | ❌ | Transaction value WITH clients |
| `a2105W` | integer | Transaction | ❌ | Transaction indicator WITH clients |
| `a2107B` | enum | Transaction | ✅ | Transaction indicator BY clients |
| `a2107W` | enum | Transaction | ❌ | Transaction indicator WITH clients |
| `a2107WRP` | enum | Transaction | ❌ | Recurring payments indicator |
| `a2108B` | integer | Transaction | ✅ | Transaction indicator BY clients |
| `a2108W` | integer | Transaction | ❌ | Transaction indicator WITH clients |
| `a2109B` | monetary | Transaction | ✅ | Transaction indicator BY clients |
| `a2109W` | monetary | Transaction | ❌ | Transaction indicator WITH clients |
| `a2110B` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2110W` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2113AB` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2113AW` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2113B` | enum | Transaction | ⚠️ | Sub-category transaction counts |
| `a2113W` | enum | Transaction | ⚠️ | Sub-category transaction counts |
| `a2114A` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2114AB` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2115AB` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2115AW` | integer | Transaction | ⚠️ | Sub-category transaction counts |
| `a2201A` | enum | Transaction | ⚠️ | Cash payment statistics |
| `a2201D` | enum | Transaction | ⚠️ | Cash payment statistics |
| `a2202` | enum | Transaction | ⚠️ | Cash payment statistics |
| `a2203` | string | Transaction | ⚠️ | Cash payment statistics |
| `a2501` | string | Transaction | ⚠️ | Virtual asset/VASP statistics |
| `a2501A` | enum | Transaction | ⚠️ | Virtual asset/VASP statistics |

### Tab 3: Distribution/STR (a3xxx)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `a3101` | enum | StrReport | ✅ | Had STRs? (Oui/Non) |
| `a3102` | integer | StrReport | ✅ | STR count |
| `a3103` | enum | StrReport | ⚠️ | STR breakdown by client type |
| `a3104` | integer | StrReport | ⚠️ | STR breakdown by client type |
| `a3105` | integer | StrReport | ⚠️ | STR breakdown by client type |
| `a3201` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3202` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3203` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3204` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3205` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3208TOLA` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3209` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3210` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3210B` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3210C` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3211` | string | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3211B` | string | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3211C` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3212CTOLA` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3301` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3302` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3303` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3304` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3304C` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3305` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3306` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3306A` | complex | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3306B` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3307` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3308` | string | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3401` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3402` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3403` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3414` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3415` | enum | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3416` | integer | Client/StrReport | ❌ | Distribution channel/identification data |
| `a3501B` | enum | Unknown | ❓ | Needs analysis |
| `a3501C` | enum | Unknown | ❓ | Needs analysis |
| `a3701` | string | Unknown | ❓ | Needs analysis |
| `a3701A` | enum | Unknown | ❓ | Needs analysis |
| `a3802` | monetary | Unknown | ❓ | Needs analysis |
| `a3803` | monetary | Unknown | ❓ | Needs analysis |
| `a3804` | monetary | Unknown | ❓ | Needs analysis |
| `a381` | monetary | Unknown | ❓ | Needs analysis |

### Tab 4: Controls (aCxxx)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `aC1101Z` | other | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1102` | other | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1102A` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1106` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11101` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11102` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11103` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11104` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11105` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11201` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1125A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11301` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11302` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11303` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11304` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11305` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11306` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11307` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC114` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11401` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11402` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11403` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11501B` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11502` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11504` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11508` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC11601` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC116A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1201` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1202` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1203` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1204` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1205` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1206` | other | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1207` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1208` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1209` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1209B` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1209C` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC12236` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC12237` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC12333` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1301` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1302` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1303` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1304` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1401` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1402` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1403` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1501` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1503B` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1506` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1518A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1601` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1602` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1608` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1609` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1610` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1611` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1612` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1612A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1614` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1615` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1616A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1616B` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1616C` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1617` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1618` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1619` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1620` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1621` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1622A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1622B` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1622F` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1625` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1626` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1627` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1629` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1630` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1631` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1633` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1634` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1635` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1635A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1636` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1637` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1638A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1639A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1640A` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1641A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1642A` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC168` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1701` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1702` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1703` | complex | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC171` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1801` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1802` | integer | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1806` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1807` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1811` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1812` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1813` | string | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1814W` | enum | Setting | ❌ | Policy/control question (Oui/Non) |
| `aC1904` | enum | Setting | ❌ | Policy/control question (Oui/Non) |

### Risk Indicators (aIRxxx)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `aIR117` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR1210` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR129` | enum | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR2313` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR2316` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR233` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR233B` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR233S` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR234` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR235B_1` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR235B_2` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR235S` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR236` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR237B` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR238B` | monetary | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR2391` | enum | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR2392` | integer | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR2393` | monetary | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR239B` | monetary | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR328` | enum | N/A | ⏭️ | Auto-calculated by AMSF validator |
| `aIR33LF` | enum | N/A | ⏭️ | Auto-calculated by AMSF validator |

### Entity Info (aA/aB/aG/aM)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `aACTIVE` | enum | Organization | ⚠️ | Entity information |
| `aACTIVEPS` | enum | Organization | ⚠️ | Entity information |
| `aACTIVERENTALS` | enum | Organization | ⚠️ | Entity information |
| `aB1801B` | enum | Organization | ⚠️ | Entity information |
| `aB3206` | integer | Organization | ⚠️ | Entity information |
| `aB3207` | integer | Organization | ⚠️ | Entity information |
| `aG24010B` | monetary | Organization | ⚠️ | Entity information |
| `aG24010W` | monetary | Organization | ⚠️ | Entity information |
| `aMLES` | integer | Organization | ⚠️ | Entity information |

### Signatories (aSxxx)

| Element | Type | Model | Status | Data Requirement |
|---------|------|-------|--------|------------------|
| `aS1` | string | Submission | ❌ | Signatory name |
| `aS2` | string | Submission | ❌ | Signatory title |

---

## Implementation Roadmap

### Phase 1: Critical Missing Fields

These fields block multiple taxonomy elements:

1. **Transaction.direction** (`by_client` / `with_client`)
   - Unlocks: All W-suffix elements (a2102W, a2105W, a2108W, a2109W, etc.)
   - Impact: ~15 elements

2. **Client.residence_status** (`national` / `foreign_resident` / `non_resident`)
   - Unlocks: a1104, a11302RES, etc.
   - Impact: ~5 elements

3. **Client.is_pep_related** / **Client.is_pep_associated**
   - Unlocks: a12102B, a12202B
   - Impact: 2 elements

4. **Submission.signatory_name** / **Submission.signatory_title**
   - Unlocks: aS1, aS2
   - Impact: 2 elements (REQUIRED for valid submission)

### Phase 2: Settings Expansion (105 elements)

Add Settings records for all aCxxxx control elements.
These are simple Oui/Non policy questions.

### Phase 3: Nice-to-Have Fields

- Client.is_hnwi / Client.net_worth_bracket
- Client.is_nonprofit
- Transaction.is_recurring
- BeneficialOwner category breakdowns
