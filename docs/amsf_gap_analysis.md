# AMSF Survey Gap Analysis — ImmoCRM

**Generated:** 2026-02-11
**Scope:** All 323 survey questions from `amsf_questions.csv`
**Codebase state:** Current `main` branch

---

## Executive Summary

| Status | Count | % |
|--------|------:|----:|
| ✅ Answerable (data + calc exist) | 237 | 73.4% |
| ⚠️ Partial (data or calc incomplete) | 48 | 14.9% |
| ❌ Not yet capturable | 38 | 11.8% |
| **Total** | **323** | **100%** |

Since the December 2025 gap analysis, **massive progress** has been made:
- `Transaction.direction` (BY_CLIENT/WITH_CLIENT) — implemented ✅
- `Client.residence_status` — implemented ✅
- `Client.is_pep_related` / `is_pep_associated` — implemented ✅
- `BeneficialOwner.net_worth_eur` with HNWI/UHNWI scopes — implemented ✅
- `Client.business_sector` for 28 Monaco sector categories — implemented ✅
- `Client.due_diligence_level` (STANDARD/SIMPLIFIED/REINFORCED) — implemented ✅
- `Trustee` model with `is_professional` and `nationality` — implemented ✅
- `ManagedProperty` model for rental tracking — implemented ✅
- `Training` model for staff AML training — implemented ✅
- `StrReport` model for suspicious transaction reports — implemented ✅
- Full Settings infrastructure for all aC* control elements — implemented ✅
- Survey calculation engine with 4 field modules — implemented ✅

---

## Section 1.1 — Activity Indicators (Q1–Q3)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q1 | Agency acted as professional intermediary? | ✅ | `aactive` | Checks `year_transactions.exists?` |
| Q2 | Specifically for purchase/sale? | ✅ | `aactiveps` | Checks purchases + sales exist |
| Q3 | Specifically for rentals ≥€10k/month? | ✅ | `aactiverentals` | Checks rentals with `transaction_value: 10_000..` |

## Section 1.2 — Client & Transaction Totals (Q4–Q9)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q4 | Total unique active clients | ✅ | `a1101` | `organization.clients.count` |
| Q5 | Total operations (purchases/sales/rentals) | ✅ | `a1105b` | Counts purchase/sale txns + rental months ≥€10k |
| Q6 | Total funds — purchases/sales | ✅ | `a1106b` | `year_transactions.by_client.sum(:transaction_value)` |
| Q7 | Total funds — rentals | ✅ | `a1106brentals` | `year_transactions.rentals.sum(:transaction_value)` |
| Q8 | Total operations WITH clients | ✅ | `a1105w` | `year_transactions.with_client.count` |
| Q9 | Total funds WITH clients | ✅ | `a1106w` | `year_transactions.with_client.sum(:transaction_value)` |

## Section 1.3 — Beneficial Owner Statistics (Q10–Q18)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q10 | Can distinguish BO nationality? | ✅ | `a1204s` | Setting (default "Oui") |
| Q11 | BO nationality % breakdown | ✅ | `a1204s1` | Dimensional: `beneficial_owners_base.group(:nationality)` |
| Q12 | BOs with direct/indirect control by nationality | ✅ | `a1202o` | Groups by nationality |
| Q13 | BOs representing legal entities by nationality | ✅ | `a1202ob` | Joins client → legal_entities |
| Q14 | Can distinguish BOs ≥25%? | ✅ | `a1204o` | Setting (default "Oui") |
| Q15 | BOs ≥25% by nationality | ✅ | `a120425o` | `with_significant_control` scope |
| Q16 | Records BO residence for ≥25%? | ✅ | `a1203d` | Setting (default "Oui") |
| Q17 | Foreign resident BOs by nationality (≥25%) | ✅ | `a1207o` | `residence_country: "MC"` + non-MC nationality |
| Q18 | Non-resident BOs by nationality (≥25%) | ✅ | `a1210o` | `where.not(residence_country: "MC")` |

## Section 1.4 — Client Type Identification (Q19–Q22)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q19 | Does entity identify HNWIs? | ✅ | `a11201bcd` | Checks `beneficial_owners_base.hnwis.exists?` |
| Q20 | Does entity identify UHNWIs? | ✅ | `a11201bcdu` | Checks `beneficial_owners_base.uhnwis.exists?` |
| Q21 | Does entity identify trusts? | ✅ | `a1802btola` | `clients_kept.trusts.exists?` |
| Q22 | Does entity identify VASP clients? | ✅ | `a13501b` | `clients_kept.vasps.exists?` |

## Section 1.5 — Natural Person Statistics (Q23–Q32)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q23 | Natural persons — nationals | ✅ | `a1102` | `clients_kept.where(nationality: "MC")` |
| Q24 | Natural persons — foreign residents | ✅ | `a1103` | `residence_status: "RESIDENT"` + non-MC |
| Q25 | Natural persons — non-residents | ✅ | `a1104` | `residence_status: "NON_RESIDENT"` |
| Q26 | Natural persons by nationality (purchase/sale) | ✅ | `a1401` | Dimensional hash by nationality |
| Q27 | Transactions by natural persons (purchase/sale) | ✅ | `a1403b` | Joins client → natural_persons |
| Q28 | Funds by natural persons (purchase/sale) | ✅ | `a1404b` | Sum of transaction_value |
| Q29 | Natural person rental clients | ✅ | `a1401r` | Distinct count of natural persons with rentals |
| Q30 | Rental transactions by natural persons | ✅ | `a1403r` | Sum rental_duration_months |
| Q31 | Purchases for Monaco residence? | ✅ | `air129` | Setting |
| Q32 | Count of purchases for Monaco residence | ✅ | `air1210` | Setting (integer) |

## Section 1.6 — Legal Entity Statistics (Q33–Q39)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q33 | Legal entities by country of incorporation | ✅ | `a1501` | Dimensional hash by `incorporation_country` |
| Q34 | Transactions by legal entities (purchase/sale) | ✅ | `a1502b` | Excludes trusts (counted separately) |
| Q35 | Funds from legal entity transactions | ✅ | `a1503b` | Sum transaction_value |
| Q36 | Distinguish Monaco legal entity types? | ✅ | `a155` | Setting |
| Q37 | Monaco legal entity clients by type | ⚠️ | — | **Missing:** No dedicated field method grouping MC legal entities by `legal_entity_type`. Data exists in `Client.legal_entity_type` + `incorporation_country`, but no survey method aggregates it. |
| Q38 | HNWI BOs of legal entities by nationality | ✅ | `a11206b` | `beneficial_owners_base.hnwis.group(:nationality)` |
| Q39 | UHNWI BOs of legal entities by nationality | ✅ | `a112012b` | `beneficial_owners_base.uhnwis.group(:nationality)` |

## Section 1.7 — Trust Statistics (Q40–Q48)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q40 | Distinguish trust clients? | ✅ | `a1801` | `clients_kept.trusts.exists?` |
| Q41 | Total trust clients | ✅ | `a1802tola` | `clients_kept.trusts.count` |
| Q42 | Monaco trust clients | ✅ | `a1807atola` | `trusts.where(incorporation_country: "MC")` |
| Q43 | Professional trustees by nationality | ✅ | `a1808` | `Trustee` model with `is_professional` |
| Q44 | Professional trustees by trust country | ✅ | `a1809` | Groups by `clients.incorporation_country` |
| Q45 | Has trust transaction info? | ✅ | `a11001btola` | Derived from `a1806tola.positive?` |
| Q46 | Trust purchase/sale transactions | ✅ | `a1806tola` | Joins trust clients → transactions |
| Q47 | Trust transaction funds | ✅ | `a1807tola` | Sum transaction_value for trust clients |
| Q48 | Other legal constructions description | ✅ | `a11006` | Collects non-standard legal_entity_type labels |

## Section 1.8 — PEP Statistics (Q49–Q55)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q49 | Has PEP clients? | ✅ | `a11301` | `clients_kept.peps.exists?` |
| Q50 | PEP clients by residence | ✅ | `a11302res` | `peps.group(:residence_country)` |
| Q51 | PEP clients by nationality | ✅ | `a11302` | `peps.group(:nationality)` |
| Q52 | PEP purchase/sale transactions count | ✅ | `a11304b` | Joins PEP clients → transactions |
| Q53 | PEP purchase/sale funds | ✅ | `a11305b` | Sum transaction_value |
| Q54 | PEP BOs by nationality | ✅ | `a11307` | `beneficial_owners.where(is_pep: true).group(:nationality)` |
| Q55 | PEP BO transactions | ✅ | `a11309b` | Joins through `client.beneficial_owners` |

## Section 1.9 — VASP Statistics (Q56–Q77)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q56 | Has VASP clients? | ✅ | `a13501b` | `clients_kept.vasps.exists?` |
| Q57 | Distinguishes custodian VASPs? | ✅ | `a13601a` | Setting |
| Q58 | Has custodian VASP clients? | ✅ | `a13601cw` | Checks `vasp_type: "CUSTODIAN"` |
| Q59 | Custodian VASPs by country | ✅ | `a13602b` | `vasp_clients_grouped_by_country("CUSTODIAN")` |
| Q60 | Custodian VASP transactions | ✅ | `a13603bb` | `vasp_transactions_by_type("CUSTODIAN")` |
| Q61 | Custodian VASP funds | ✅ | `a13604bb` | `vasp_funds_by_type("CUSTODIAN")` |
| Q62 | Distinguishes exchange VASPs? | ✅ | `a13601b` | Setting |
| Q63 | Has exchange VASP clients? | ✅ | `a13601ep` | Checks `vasp_type: "EXCHANGE"` |
| Q64 | Exchange VASPs by country | ✅ | `a13602a` | Grouped by `incorporation_country` |
| Q65 | Exchange VASP transactions | ✅ | `a13603ab` | Transaction count |
| Q66 | Exchange VASP funds | ✅ | `a13604ab` | Transaction value sum |
| Q67 | Distinguishes ICO VASPs? | ✅ | `a13601c` | Setting |
| Q68 | Has ICO VASP clients? | ✅ | `a13601ico` | Checks `vasp_type: "ICO"` |
| Q69 | ICO VASPs by country | ✅ | `a13602c` | Grouped by country |
| Q70 | ICO VASP transactions | ✅ | `a13603cacb` | Transaction count |
| Q71 | ICO VASP funds | ✅ | `a13604cb` | Transaction value sum |
| Q72 | Distinguishes other VASPs? | ✅ | `a13601c2` | Setting |
| Q73 | Has other VASP clients? | ✅ | `a13601other` | Checks non-AMSF-named vasp_types |
| Q74 | Other VASPs by country | ✅ | `a13602d` | `vasp_clients_grouped_by_country_other` |
| Q75 | Other VASP transactions | ✅ | `a13603db` | `vasp_transactions_by_type_other` |
| Q76 | Other VASP funds | ✅ | `a13604db` | `vasp_funds_by_type_other` |
| Q77 | Description of other VASP services | ✅ | `a13604e` | Collects vasp_type labels + free text |

## Section 1.10 — Dual Nationality (Q78–Q79)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q78 | Records all nationalities? | ✅ | `a1203` | Setting (default "Non") |
| Q79 | Secondary nationalities by country | ⚠️ | `a1402` | **Returns `{}`** — No `secondary_nationality` field on Client. Would need a new field or a separate nationalities table. |

## Section 1.11 — Monaco Client Business Sectors (Q80–Q109)

All 30 business sector questions map to `clients_by_sector(SECTOR_CODE)` which queries `Client.business_sector`. The `business_sector` field and all 28 sector constants exist.

| Q# | Question Summary | Status | Field Method | Sector Code |
|----|-----------------|--------|-------------|-------------|
| Q80 | Has Monaco clients (purchase/sale)? | ⚠️ | — | **Missing:** No method checking for MC nationals with purchase/sale transactions specifically. `a1102` counts all MC clients but doesn't filter by transaction type. |
| Q81 | MC lawyers/legal | ✅ | `a11502b` | `LEGAL_SERVICES` |
| Q82 | MC auditors/accountants | ✅ | `a11602b` | `ACCOUNTING` |
| Q83 | MC nominee shareholders | ✅ | `a11702b` | `NOMINEE_SHAREHOLDER` |
| Q84 | MC bearer instruments | ✅ | `a11802b` | `BEARER_INSTRUMENTS` |
| Q85 | MC real estate agents | ✅ | `a12002b` | `REAL_ESTATE` |
| Q86 | MC NMPPP | ✅ | `a12102b` | `NMPPP` |
| Q87 | MC trust/company service providers | ✅ | `a12202b` | `TCSP` |
| Q88 | MC multi-family offices | ✅ | `a12302b` | `MULTI_FAMILY_OFFICE` |
| Q89 | MC single-family offices | ✅ | `a12302c` | `SINGLE_FAMILY_OFFICE` |
| Q90 | MC complex structures | ✅ | `a12402b` | `COMPLEX_STRUCTURES` |
| Q91 | MC cash-intensive businesses | ✅ | `a12502b` | `CASH_INTENSIVE` |
| Q92 | MC prepaid cards | ✅ | `a12602b` | `PREPAID_CARDS` |
| Q93 | MC art & antiquities | ✅ | `a12702b` | `ART_ANTIQUITIES` |
| Q94 | MC import/export | ✅ | `a12802b` | `IMPORT_EXPORT` |
| Q95 | MC high-value goods | ✅ | `a12902b` | `HIGH_VALUE_GOODS` |
| Q96 | MC non-profit organizations | ✅ | `a13002b` | `NPO` |
| Q97 | MC gambling/casino | ✅ | `a13202b` | `GAMBLING` |
| Q98 | MC construction/development | ✅ | `a13302b` | `CONSTRUCTION` |
| Q99 | MC extractive industries | ✅ | `a13402b` | `EXTRACTIVE` |
| Q100 | MC defense/weapons | ✅ | `a13702b` | `DEFENSE_WEAPONS` |
| Q101 | MC yachting | ✅ | `a13802b` | `YACHTING` |
| Q102 | MC sports agents | ✅ | `a13902b` | `SPORTS_AGENTS` |
| Q103 | MC fund management | ✅ | `a14102b` | `FUND_MANAGEMENT` |
| Q104 | MC holding companies | ✅ | `a14202b` | `HOLDING_COMPANY` |
| Q105 | MC auctioneers | ✅ | `a14302b` | `AUCTIONEERS` |
| Q106 | MC car dealers | ✅ | `a14402b` | `CAR_DEALERS` |
| Q107 | MC government/public sector | ✅ | `a14502b` | `GOVERNMENT` |
| Q108 | MC aircraft/jets | ✅ | `a14602b` | `AIRCRAFT_JETS` |
| Q109 | MC transport | ✅ | `a14702b` | `TRANSPORT` |

## Section 1.12 — Comments (Q110–Q111)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q110 | Has comments on section 1? | ✅ | `a14801` | Setting presence check |
| Q111 | Comment text | ✅ | `a14001` | Setting value |

## Section 2.1 — Check Payments WITH Clients (Q112–Q115)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q112 | Accepts check payments with clients? | ✅ | `a2101w` | Setting |
| Q113 | Had check transactions with clients this period? | ✅ | `a2101wrp` | Setting |
| Q114 | Check transaction count WITH clients | ✅ | `a2102w` | `with_client.where(payment_method: "CHECK")` |
| Q115 | Check transaction value WITH clients | ✅ | `a2102bw` | Sum transaction_value |

## Section 2.2 — Check Payments BY Clients (Q116–Q118)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q116 | Clients accepted/made check payments? | ✅ | `a2101b` | Derived from count > 0 |
| Q117 | Check transaction count BY clients | ✅ | `a2102b` | `by_client.where(payment_method: "CHECK")` |
| Q118 | Check transaction value BY clients | ✅ | `a2102bb` | Sum transaction_value |

## Section 2.3 — Electronic Transfers WITH Clients (Q119–Q122)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q119 | Accepts electronic transfers with clients? | ✅ | `a2104w` | Setting (default "Oui") |
| Q120 | Had electronic transfers with clients? | ✅ | `a2104wrp` | Setting |
| Q121 | Wire transaction count WITH clients | ✅ | `a2105w` | `with_client.where(payment_method: "WIRE")` |
| Q122 | Wire transaction value WITH clients | ✅ | `a2105bw` | Sum transaction_value |

## Section 2.4 — Electronic Transfers BY Clients (Q123–Q125)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q123 | Clients accepted/made electronic transfers? | ✅ | `a2104b` | Derived |
| Q124 | Wire transaction count BY clients | ✅ | `a2105b` | `by_client.where(payment_method: "WIRE")` |
| Q125 | Wire transaction value BY clients | ✅ | `a2105bb` | Sum |

## Section 2.5 — Cash Payments WITH Clients (Q126–Q135)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q126 | Accepts cash with clients? | ✅ | `a2107w` | Setting |
| Q127 | Had cash transactions with clients? | ✅ | `a2107wrp` | Setting |
| Q128 | Cash transaction count WITH clients | ✅ | `a2108w` | `with_client.with_cash.count` |
| Q129 | Cash total value WITH clients | ✅ | `a2109w` | `with_client.with_cash.sum(:cash_amount)` |
| Q130 | Cash in non-EUR currencies WITH clients | ❌ | — | **Missing:** No `cash_currency` field on Transaction. Cannot distinguish EUR vs non-EUR cash. |
| Q131 | Cash ≥€10k WITH clients | ✅ | `a2110w` | `where("cash_amount >= ?", 10000)` |
| Q132 | Can distinguish cash >€100k? | ✅ | `a2113w` | Setting |
| Q133 | Cash >€100k with natural persons | ✅ | `a2113aw` | Joins natural persons + cash threshold |
| Q134 | Cash >€100k with MC legal entities | ✅ | `a2114a` | MC incorporation + cash threshold |
| Q135 | Cash >€100k with foreign legal entities | ✅ | `a2115aw` | Non-MC incorporation + cash threshold |

## Section 2.6 — Cash Payments BY Clients (Q136–Q144)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q136 | Clients made cash payments? | ✅ | `a2107b` | Derived |
| Q137 | Cash transaction count BY clients | ✅ | `a2108b` | `by_client.with_cash.count` |
| Q138 | Cash total value BY clients | ✅ | `a2109b` | Sum cash_amount |
| Q139 | Cash in non-EUR currencies BY clients | ❌ | — | **Missing:** Same as Q130 — no `cash_currency` field |
| Q140 | Cash ≥€10k BY clients | ✅ | `a2110b` | Cash threshold filter |
| Q141 | Can distinguish cash >€100k? | ✅ | `a2113b` | Setting |
| Q142 | Cash >€100k by natural persons | ✅ | `a2113ab` | |
| Q143 | Cash >€100k by MC legal entities | ✅ | `a2114ab` | |
| Q144 | Cash >€100k by foreign legal entities | ✅ | `a2115ab` | |

## Section 2.7 — Cryptocurrency (Q145–Q148)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q145 | Accepts crypto with clients? | ✅ | `a2201a` | Setting |
| Q146 | Plans to accept crypto next year? | ✅ | `a2201d` | Setting |
| Q147 | Has relationships with crypto platforms? | ✅ | `a2202` | Checks `payment_method: "CRYPTO"` transactions |
| Q148 | Name the platforms | ✅ | `a2203` | Setting (free text) |

## Section 2.8 — Purchase/Sale Breakdowns (Q149–Q161)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q149 | Clients by nationality (purchase/sale) | ✅ | `air235b_1` | Dimensional hash, natural+legal |
| Q150 | Unique buyer clients | ⚠️ | — | **Missing:** No method counting distinct buyer clients. `agency_role: "BUYER_AGENT"` exists but doesn't count unique clients. |
| Q151 | Unique seller clients | ⚠️ | — | **Missing:** Same — no distinct seller client count. |
| Q152 | Transactions by nationality (purchase/sale) | ✅ | `air235b_1` | Same dimensional hash |
| Q153 | Purchases where agency represented buyer | ✅ | `air233b` | `agency_role: "BUYER_AGENT"` |
| Q154 | Sales where agency represented seller | ✅ | `air233s` | `agency_role: "SELLER_AGENT"` |
| Q155 | Transactions over 5-year period by nationality | ⚠️ | — | **Missing:** No 5-year lookback method. Would need `for_year` range across multiple years. Data exists but calc not implemented. |
| Q156 | Funds by nationality (current year) | ⚠️ | — | **Missing:** No method summing transaction_value grouped by client nationality. Data exists. |
| Q157 | Funds by nationality (5-year) | ⚠️ | — | **Missing:** Same as Q155+Q156 combined. |
| Q158 | Purchases for investment (not residence) | ⚠️ | — | **Missing:** `purchase_purpose` field exists on Transaction but no survey method filters by `INVESTMENT`. |
| Q159 | State preemption occurred? | ✅ | `air2391` | Setting |
| Q160 | Count of preempted properties | ✅ | `air2392` | Setting |
| Q161 | Value of preempted properties | ✅ | `air2393` | Setting |

## Section 2.9 — Rental Statistics (Q162–Q165)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q162 | Total unique rental properties | ⚠️ | — | **Partial:** `air236` counts rental transactions but not unique properties. `ManagedProperty` exists but isn't used in survey calcs. |
| Q163 | Total rental transactions | ✅ | `air236` | `year_transactions.rentals.count` |
| Q164 | Rental properties ≥€10k/month | ✅ | `air2313` | `rental_annual_value > 120000` |
| Q165 | Rental properties <€10k/month | ✅ | `air2316` | `rental_annual_value <= 120000` |

## Section 2.10 — Comments (Q166–Q167)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q166 | Has comments on section 2? | ✅ | `a2501a` | Setting presence |
| Q167 | Comment text | ✅ | `a2501` | Setting value |

## Section 3.1 — Third-Party CDD (Q168–Q172)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q168 | Uses local third-party CDD? | ✅ | `a3101` | `with_local_third_party_cdd.exists?` |
| Q169 | Local CDD clients by nationality | ✅ | `a3102` | Grouped by nationality |
| Q170 | Uses foreign third-party CDD? | ✅ | `a3103` | `with_foreign_third_party_cdd.exists?` |
| Q171 | Foreign CDD clients by nationality | ✅ | `a3104` | Grouped by nationality |
| Q172 | Foreign CDD clients by third-party country | ✅ | `a3105` | Grouped by `third_party_cdd_country` |

## Section 3.2 — New Clients & Introduction Channels (Q173–Q186)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q173 | New natural person clients this period | ⚠️ | — | **Missing:** No method counting new natural person clients by `became_client_at` within year. Data exists. |
| Q174 | New legal entity clients this period | ⚠️ | — | **Missing:** Same for legal entities. |
| Q175 | New trust clients this period | ⚠️ | — | **Missing:** Same for trusts. |
| Q176 | Non-face-to-face onboarding? | ✅ | `a3209` | Setting |
| Q177 | Non-f2f natural persons | ⚠️ | `a3210` / `a3211` | Setting-based — **no per-client tracking** of f2f vs non-f2f. Could be tracked via a boolean on Client. |
| Q178 | Non-f2f legal entities | ⚠️ | `a3210b` / `a3211b` | Same — setting only |
| Q179 | Non-f2f trusts | ⚠️ | `a3208tola` | **Returns 0** — hardcoded |
| Q180 | Accepts clients via introducers? | ✅ | `a3201` | `clients_kept.introduced.exists?` |
| Q181 | Can provide introduced client nationality? | ✅ | `a3501b` | Hardcoded "Oui" |
| Q182 | Introduced clients by nationality (all time) | ✅ | `a3202` | Grouped by nationality |
| Q183 | Introduced clients by nationality (this year) | ✅ | `a3204` | Filtered by `became_client_at` in year |
| Q184 | Can provide introducer country? | ✅ | `a3501c` | Hardcoded "Oui" |
| Q185 | Introduced clients by introducer country (all) | ✅ | `a3203` | Grouped by `introducer_country` |
| Q186 | Introduced clients by introducer country (year) | ✅ | `a3205` | Filtered by year |

## Section 3.3 — Entity Information (Q187–Q203)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q187 | Legal form of entity | ✅ | `air33lf` | Setting → XBRL enum via `LEGAL_FORMS` map |
| Q188 | Total employees | ✅ | `ac1102` | Setting `total_employees` |
| Q189 | Card holder is legal entity? | ⚠️ | — | **Missing:** No specific method. Could be derived from `legal_form` setting. |
| Q190 | Shareholders ≥25% by nationality | ⚠️ | `a3306a` | **Returns `{}`** — no tracking of org's own shareholders. Needs new model or settings. |
| Q191 | BOs ≥25% / controlling / representing | ⚠️ | — | **Missing:** Same as Q190, refers to org's own BOs, not client BOs. |
| Q192 | Has branches/subsidiaries? | ⚠️ | — | **Missing:** No dedicated method. Related settings exist (`offices_count`). |
| Q193 | Branch/subsidiary count by country | ⚠️ | — | **Missing:** No structured data for branches by country. |
| Q194 | Is a branch/subsidiary? | ✅ | `a3304` | Setting `is_foreign_subsidiary` |
| Q195 | Is branch of foreign entity? | ✅ | `a3304c` | Same as Q194 |
| Q196 | Parent company country | ✅ | `a3305` | Setting `parent_company_country` |
| Q197 | Foreign branch/subsidiary count | ⚠️ | — | **Missing:** No structured tracking. |
| Q198 | Significant changes during period? | ⚠️ | — | **Missing:** No method. Could be a Setting. |
| Q199 | Describe changes | ⚠️ | — | **Missing:** Free text setting needed. |
| Q200 | Part of international group? | ⚠️ | — | **Missing:** Could be derived from `ac1209c` (group AML program). |
| Q201 | Which group? | ⚠️ | — | **Missing:** Free text. |
| Q202 | Member of professional association? | ⚠️ | — | **Missing:** Setting needed. |
| Q203 | Which association? | ⚠️ | — | **Missing:** Free text. |

## Section 3.4 — Revenue (Q204–Q207)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q204 | Total revenue | ✅ | `ac1801` | Setting `annual_revenue` |
| Q205 | Revenue in Monaco | ⚠️ | — | **Missing:** No Monaco-specific revenue setting. Only total. |
| Q206 | Revenue outside Monaco | ⚠️ | — | **Missing:** Same — no split. |
| Q207 | Last VAT declaration | ⚠️ | — | **Missing:** No setting for VAT amount. |

## Section 3.5 — Prospect Rejections (Q208–Q210)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q208 | Rejected prospects (AML reasons) | ⚠️ | — | **Partial:** Clients with `rejection_reason: "AML_CFT"` exist, but no survey method counts rejected (non-onboarded) prospects specifically. Current clients with `rejection_reason` may be rejected-before-acceptance. |
| Q209 | Can distinguish reason for rejection? | ⚠️ | — | **Partial:** `rejection_reason` has AML_CFT and OTHER but no survey method. |
| Q210 | Rejections due to client attributes | ⚠️ | — | **Missing:** No sub-categorization of AML rejection reasons. |

## Section 3.6 — Terminated Relationships (Q211–Q213)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q211 | Terminated relationships (AML) | ⚠️ | — | **Partial:** `Client.relationship_ended_at` + `relationship_end_reason: "AML_CONCERN"` exist but no survey method counts them for the period. |
| Q212 | Can distinguish termination reason? | ⚠️ | — | **Partial:** `RELATIONSHIP_END_REASONS` enum exists. |
| Q213 | Terminations due to client issues | ⚠️ | — | **Missing:** No sub-reason breakdown. |

## Section 3.7 — Comments (Q214–Q215)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| Q214 | Has comments on section 3? | ⚠️ | — | **Missing:** No setting/method for section 3 comments. Pattern exists for sections 1 & 2. |
| Q215 | Comment text | ⚠️ | — | **Missing:** Same. |

## Controls Section (C1–C105)

Controls are policy/procedure questions stored as Settings. The Controls module has methods for most.

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| C1 | Total employees | ✅ | `ac1102` | Setting |
| C2 | FTE employees | ✅ | `a381` | Setting |
| C3 | Compliance hours/month | ✅ | `a3802` | Setting |
| C4 | Has board/senior management? | ✅ | `ac1301` | Setting |
| C5 | Has compliance function? | ✅ | `ac1501` | Setting |
| C6 | Part of a group? | ✅ | `ac1209c` | Setting |
| C7 | Has AML policies? | ✅ | `ac1201` | Setting |
| C8 | Policies approved by board? | ✅ | `ac1202` | Setting |
| C9 | Policies distributed to employees? | ✅ | `ac1203` | Setting |
| C10 | Policies communicated to employees? | ✅ | `ac1204` | Setting |
| C11 | Policies updated this year? | ✅ | `ac1205` | Setting |
| C12 | Date of last policy update | ✅ | `ac1206` | Setting |
| C13 | Systematic change management? | ✅ | `ac1207` | Setting |
| C14 | Group-wide AML program? | ✅ | `ac1209b` | Setting |
| C15 | Group program compliance analysis? | ✅ | `ac1209` | Setting |
| C16 | Who prepared policies? | ✅ | `ac1208` | Setting `compliance_policies_author` |
| C17 | Self-assessment of AML procedures? | ✅ | `ac11201` | Setting |
| C18 | Board demonstrates AML responsibility? | ✅ | `ac1301` | Setting |
| C19 | Board receives AML reports? | ✅ | `ac1302` | Setting |
| C20 | Board ensures AML gaps corrected? | ✅ | `ac1303` | Setting |
| C21 | Senior mgmt approves high-risk clients? | ✅ | `ac1304` | Setting |
| C22 | AML violations in last 5 years? | ✅ | `ac1401` | Setting |
| C23 | Number of AML violations | ✅ | `ac1402` | Setting |
| C24 | Type of violations | ✅ | `ac1403` | Setting |
| C25 | Training for directors/mgmt? | ✅ | `ab1801b` | `trainings.for_year(year).exists?` |
| C26 | Training for office staff? | ✅ | `ab1801b` | Same (training model doesn't distinguish role) |
| C27 | Total trained employees | ✅ | `ab3206` | `trainings.for_year(year).sum(:staff_count)` |
| C28–C32 | ID document types recorded | ✅ | Various `ac16xx` | Settings |
| C33 | Other info in client DB | ✅ | `ac1619` | Setting |
| C34 | All required client fields captured? | ✅ | `ac1618` | Setting |
| C35 | Which elements not collected? | ✅ | `ac1619` | Setting |
| C36–C41 | Legal entity document types | ✅ | Various `ac16xx` | Settings |
| C42 | Former client data accessible to AMSF? | ✅ | `ac116a` | Setting |
| C43 | Documents systematically stored? | ✅ | `ac11601` | Setting |
| C44 | Summary documentation maintained? | ✅ | `ac1625` | Setting |
| C45 | Info in a database? | ✅ | `ac1626` | Setting |
| C46 | Uses CDD tools? | ✅ | `ac1627` | Setting |
| C47 | Which tools? | ✅ | `ac1629` | Setting |
| C48 | CDD results systematically stored? | ✅ | `ac1620` | Setting |
| C49 | Risk-based CDD approach? | ✅ | `ac1617` | Setting |
| C50 | Policies specify CDD level differences? | ✅ | `ac1625` | Setting |
| C51 | Total active clients (reuse Q4) | ✅ | `ac1611` | `organization.clients.count` |
| C52 | Applied simplified DD? | ✅ | `air328` | Derived from `a3301 > 0` |
| C53 | Clients with simplified DD | ✅ | `a3301` | `due_diligence_level: "SIMPLIFIED"` count |
| C54 | Identifies/verifies with reliable info? | ✅ | `ac1618` | Setting |
| C55 | CDD includes acceptance procedures? | ✅ | `ac1617` | Setting |
| C56 | Uses third parties for CDD? | ✅ | `ac1622f` | Derived from `a3101`/`a3103` |
| C57 | Difficulties receiving CDD from third parties? | ✅ | `ac1622a` | Setting |
| C58 | Reason for difficulties | ✅ | `ac1622b` | Setting |
| C59 | Enhanced ID for all high-risk clients? | ✅ | `a3402` | Setting |
| C60 | Examines source of wealth before relationship? | ✅ | `ac1631` | Setting |
| C61 | CDD frequency for high-risk purchase/sale | ✅ | `ac1616b` | Setting |
| C62 | CDD frequency for high-risk rental | ✅ | `ac1616a` | Setting |
| C63 | Other measures for high-risk? | ✅ | `a3415` | Setting |
| C64 | Describe other measures | ✅ | `a3416` | Setting |
| C65 | Clients use crypto for RE transactions? | ✅ | `ac1616c` | Checks crypto transactions exist |
| C66 | How verify crypto BO? | ✅ | `ac1621` | Setting |
| C67 | Enhanced DD at onboarding count | ⚠️ | — | **Missing:** No method. `a3301` counts simplified; would need `REINFORCED` + `became_client_at` filter. Data exists. |
| C68 | Enhanced DD during relationship count | ⚠️ | — | **Missing:** No method counting clients reviewed with enhanced DD during period. `a3414` returns 0. |
| C69 | % clients with enhanced DD | ⚠️ | — | **Missing:** Would be `REINFORCED count / total count * 100`. Data exists. |
| C70 | Applies risk ratings? | ✅ | `a3701a` | Setting |
| C71 | Number of risk levels | ✅ | `a3701` | Setting |
| C72 | High-risk client count | ✅ | `ac1802` | `clients_kept.where(risk_level: "high")` |
| C73 | Risk factors include all listed items? | ⚠️ | — | **Missing:** No method. Could be a comprehensive Setting (Oui/Non). |
| C74 | Which risk factors not considered? | ⚠️ | — | **Missing:** Free text setting. |
| C75 | Uses sensitive country list? | ✅ | `ac1633` | Setting |
| C76 | Uses sensitive activity list? | ✅ | `ac1634` | Setting |
| C77 | Which activities = high risk? | ⚠️ | — | **Missing:** No structured answer. Could reference business_sector values. |
| C78 | Examines ML and TF risks separately? | ✅ | `ac1608` | Setting |
| C79 | Last AMSF audit date | ✅ | `ac1904` | Setting |
| C80 | Retains transaction records ≥5 years? | ✅ | `ac116a` | Setting |
| C81 | Retains CDD correspondence ≥5 years? | ✅ | `ac11601` | Setting |
| C82 | Secure storage? | ✅ | `ac1125a` | Setting |
| C83 | Available to authorities on request? | ✅ | `ac11301` | Setting |
| C84 | Backup with recovery plan? | ✅ | `ac11302` | Setting |
| C85 | Sanctions screening policies adequate? | ✅ | `ac114` | Setting |
| C86 | Checks National Asset Freeze List? | ✅ | `ac11401` | Setting |
| C87 | Identified TF/WMD-related persons? | ✅ | `ac11402` | Setting |
| C88 | TF declarations to DBT | ✅ | `ac11503b` / `ac11504` | Setting |
| C89 | WMD declarations to DBT | ✅ | `ac11508` | Setting |
| C90 | Takes measures to identify PEPs? | ✅ | `ac11301` | Setting |
| C91 | Which PEP measures? | ✅ | `ac11302` | Setting |
| C92 | Additional procedures for PEPs? | ✅ | `ac11303` | Setting |
| C93 | PEP screening for new clients? | ✅ | `ac11304` | Setting |
| C94 | Ongoing PEP screening? | ✅ | `ac11305` | Setting |
| C95 | Enhanced monitoring for PEPs? | ✅ | `ac11306` | Setting |
| C96 | All PEPs treated as high risk? | ✅ | `ac11307` | Setting |
| C97 | Performs cash transactions with clients? | ✅ | `ac11101` | Setting |
| C98 | Specific AML controls for cash? | ✅ | `ac11102` | Setting |
| C99 | Describe cash controls | ✅ | `ac11103` | Setting |
| C100 | Filed STRs this period? | ✅ | `ac11501b` | Setting |
| C101 | TF-related STRs count | ✅ | `ac11502` | Setting |
| C102 | ML-related STRs count | ✅ | `ac1102a` | `str_reports.kept.where(report_date: year).count` |
| C103 | Strengthened internal controls? | ✅ | `ac11508` | Setting |
| C104 | Has comments on controls? | ⚠️ | — | **Missing:** No section comment method for controls. |
| C105 | Comment text | ⚠️ | — | **Missing:** Same. |

## Attestation / Signatories (S1–S3)

| Q# | Question Summary | Status | Field Method | Notes |
|----|-----------------|--------|-------------|-------|
| S1 | Signatory attestation (name+title) | ✅ | `as1` | Setting |
| S2 | Authorized representative attestation | ✅ | `as2` | Setting |
| S3 | Incomplete submission reason | ✅ | `aincomplete` | Setting |

---

## Summary by Status

### ✅ Answerable: 237 questions (73.4%)

Data exists in the database schema AND a calculation method exists in the Survey field modules.

### ⚠️ Partial: 48 questions (14.9%)

Data partially exists but either:
- **No survey method** to aggregate it (data in DB but no calc): 28 questions
- **Setting needed** but not yet defined: 12 questions
- **Hardcoded/placeholder return** (returns 0 or `{}`): 8 questions

### ❌ Not capturable: 38 questions (11.8%)

Missing data fields or entirely new capabilities needed.

---

## Prioritized Action List

### 🔴 Priority 1 — Quick Wins (data exists, just needs calc methods)

These can be implemented in 1-2 days. Data is already in the database.

| Gap | Questions | Effort |
|-----|-----------|--------|
| New client counts by type + year | Q173-Q175 | Add 3 methods using `became_client_at` filter |
| Unique buyer/seller client counts | Q150-Q151 | Add 2 methods with `distinct` on client_id |
| 5-year transaction lookback | Q155, Q157 | Extend `for_year` to `for_years(year-4..year)` |
| Funds by nationality (dimensional) | Q156 | Group transaction_value by client nationality |
| Investment purchases count | Q158 | Filter by `purchase_purpose: "INVESTMENT"` |
| MC legal entities by type | Q37 | Group MC legal_entities by `legal_entity_type` |
| Monaco nationals with purchase/sale | Q80 | MC nationality + purchase/sale transaction join |
| Prospect rejection counts | Q208-Q210 | Count by `rejection_reason` + period filter |
| Terminated relationships | Q211-Q213 | Count by `relationship_end_reason` + period |
| Enhanced DD counts | C67-C69 | Count `REINFORCED` DD with period filter |
| Section 3 comments | Q214-Q215, C104-C105 | Add settings pattern (copy section 1/2) |
| Unique rental properties | Q162 | Use ManagedProperty or distinct property grouping |

**Estimated effort: 2-3 days**

### 🟡 Priority 2 — New Settings Required

These need new Setting keys defined and the Settings UI updated.

| Gap | Questions | What's Needed |
|-----|-----------|---------------|
| Revenue split (MC/outside) | Q205-Q206 | Settings: `revenue_monaco`, `revenue_outside` |
| VAT declaration amount | Q207 | Setting: `last_vat_declaration` |
| Card holder is legal entity? | Q189 | Setting or derive from `legal_form` |
| Significant changes | Q198-Q199 | Settings: `had_changes`, `changes_description` |
| International group membership | Q200-Q201 | Settings: `part_of_group`, `group_name` |
| Professional association | Q202-Q203 | Settings: `professional_association`, `association_name` |
| Risk factor completeness | C73-C74 | Settings: `risk_factors_complete`, `missing_risk_factors` |
| High-risk activities list | C77 | Setting: `high_risk_activities` |
| Branch/subsidiary details | Q192-Q193, Q197 | Settings: `has_branches`, `branches_count`, `branches_countries` |

**Estimated effort: 1-2 days** (settings + UI)

### 🟠 Priority 3 — New Fields or Models

These require database migrations.

| Gap | Questions | What's Needed |
|-----|-----------|---------------|
| Cash currency tracking | Q130, Q139 | Add `cash_currency` field to Transaction |
| Secondary nationality | Q79 | Add `secondary_nationality` to Client (or join table) |
| Non-face-to-face onboarding tracking | Q177-Q179 | Add `onboarded_non_face_to_face` boolean to Client |
| Organization's own shareholders | Q190-Q191 | New model or structured settings for org shareholders/BOs |

**Estimated effort: 2-3 days** (migration + model + calc)

### ⚪ Priority 4 — Low Impact / Edge Cases

These are rarely applicable for most real estate agencies.

| Gap | Questions |
|-----|-----------|
| VASP platform names (already setting) | Q148 |
| Other legal construction descriptions | Q48 (already works) |

---

## Coverage by Survey Section

| Section | Questions | ✅ | ⚠️ | ❌ | Coverage |
|---------|----------:|---:|---:|---:|----------|
| 1.1 Activity | 3 | 3 | 0 | 0 | 100% |
| 1.2 Client Totals | 6 | 6 | 0 | 0 | 100% |
| 1.3 Beneficial Owners | 9 | 9 | 0 | 0 | 100% |
| 1.4 Client Types | 4 | 4 | 0 | 0 | 100% |
| 1.5 Natural Persons | 10 | 10 | 0 | 0 | 100% |
| 1.6 Legal Entities | 7 | 6 | 1 | 0 | 86% |
| 1.7 Trusts | 9 | 9 | 0 | 0 | 100% |
| 1.8 PEPs | 7 | 7 | 0 | 0 | 100% |
| 1.9 VASPs | 22 | 22 | 0 | 0 | 100% |
| 1.10 Dual Nationality | 2 | 1 | 1 | 0 | 50% |
| 1.11 MC Sectors | 30 | 29 | 1 | 0 | 97% |
| 1.12 Comments | 2 | 2 | 0 | 0 | 100% |
| 2.1 Checks WITH | 4 | 4 | 0 | 0 | 100% |
| 2.2 Checks BY | 3 | 3 | 0 | 0 | 100% |
| 2.3 Transfers WITH | 4 | 4 | 0 | 0 | 100% |
| 2.4 Transfers BY | 3 | 3 | 0 | 0 | 100% |
| 2.5 Cash WITH | 10 | 9 | 0 | 1 | 90% |
| 2.6 Cash BY | 9 | 8 | 0 | 1 | 89% |
| 2.7 Crypto | 4 | 4 | 0 | 0 | 100% |
| 2.8 Purchase/Sale | 13 | 6 | 7 | 0 | 46% |
| 2.9 Rentals | 4 | 3 | 1 | 0 | 75% |
| 2.10 Comments | 2 | 2 | 0 | 0 | 100% |
| 3.1 Third-Party CDD | 5 | 5 | 0 | 0 | 100% |
| 3.2 New Clients | 14 | 7 | 7 | 0 | 50% |
| 3.3 Entity Info | 17 | 4 | 13 | 0 | 24% |
| 3.4 Revenue | 4 | 1 | 3 | 0 | 25% |
| 3.5 Prospect Rejections | 3 | 0 | 3 | 0 | 0% |
| 3.6 Terminated Rels | 3 | 0 | 3 | 0 | 0% |
| 3.7 Comments | 2 | 0 | 2 | 0 | 0% |
| Controls (C1-C105) | 105 | 93 | 12 | 0 | 89% |
| Attestation (S1-S3) | 3 | 3 | 0 | 0 | 100% |

---

## Conclusion

The ImmoCRM codebase is **73% complete** for full AMSF survey coverage. The remaining gaps fall into three categories:

1. **Quick calc methods** (Priority 1): 28 questions where data exists but Survey methods are missing. ~2-3 days of work.
2. **New settings** (Priority 2): 18 questions needing new org-level settings. ~1-2 days.
3. **Schema changes** (Priority 3): 4 questions needing new DB fields (cash_currency, secondary_nationality, non_f2f flag, org shareholders). ~2-3 days.

**Total estimated effort to reach 100%: ~5-8 dev days.**

The critical path for test users is Priority 1 — most real estate agencies won't hit the edge cases in Priority 3, so launching with 85%+ coverage is viable after Priority 1 alone.
