# AMSF Survey Audit Log

Bugs and mismatches found by cross-referencing the AMSF questionnaire (French source text + gem taxonomy) against the Survey field implementations.

## Bugs Found

### 1. `ab3206` / `ab3207` in controls.rb — Wrong field IDs
- **PR:** #98
- **Fields:** `aB3206` (Q173), `aB3207` (Q174)
- **Expected:** Count of new natural person / legal entity clients in reporting period
- **Actual:** `ab3206` returned training staff count (`organization.trainings.for_year(year).sum(:staff_count)`), `ab3207` returned a setting value
- **Root cause:** Field IDs were incorrectly assigned to training methods in controls.rb. The training methods should be `ac1102a` / `ac1102`.
- **Impact:** Survey would report training headcount instead of new client counts. Both values are integers so no type error — silent wrong data.

### 2. `air233b` / `air233s` — Counting transactions instead of unique clients
- **PR:** #99
- **Fields:** `aIR233B` (Q150), `aIR233S` (Q151)
- **Expected:** "Combien de clients uniques étaient des acheteurs/vendeurs?" — count of **unique clients** who were buyers/sellers
- **Actual:** Counted number of purchase/sale transactions (`.count` instead of `.distinct.count(:client_id)`)
- **Root cause:** Subtle mistranslation — "how many" was interpreted as transaction count rather than unique client count
- **Impact:** A client with 3 purchases would be counted as 3 instead of 1. Inflated buyer/seller numbers.

### 3. `a3208tola` in distribution_risk.rb — Hardcoded to 0
- **PR:** #98
- **Field:** `a3208TOLA` (Q175)
- **Expected:** Count of new trust/legal construction clients in reporting period
- **Actual:** Returned hardcoded `0` with comment about non-face-to-face tracking
- **Root cause:** Field was mistakenly associated with non-face-to-face relationships instead of new client onboarding
- **Impact:** Trust client count always reported as 0 regardless of actual data.

### 4. `air237b` — Rental transactions instead of 5-year purchase/sale count by nationality
- **PR:** #100
- **Field:** `aIR237B` (Q155)
- **Expected:** "Total transactions for purchases/sales over reporting period + 4 previous years, by client nationality"
- **Actual:** Counted rental transactions grouped by property_country (wrong transaction type, wrong grouping dimension, wrong time range)
- **Root cause:** Method was incorrectly implementing a rental query instead of the 5-year purchase/sale lookback
- **Impact:** Completely wrong data — rental counts by property location instead of purchase/sale counts by client nationality over 5 years

### 5. `air238b` — Rental values instead of current-year purchase/sale funds by nationality
- **PR:** #100
- **Field:** `aIR238B` (Q156)
- **Expected:** "Total funds for purchases/sales in current year, by client nationality"
- **Actual:** Summed rental transaction_value by property_country
- **Root cause:** Same as #4 — rental query instead of purchase/sale
- **Impact:** Rental values reported instead of purchase/sale amounts

### 6. `air239b` — Rental annual values instead of 5-year purchase/sale funds by nationality
- **PR:** #100
- **Field:** `aIR239B` (Q157)
- **Expected:** "Total funds for purchases/sales over 5 years, by client nationality"
- **Actual:** Summed rental_annual_value by property_country
- **Root cause:** Same as #4/#5
- **Impact:** Rental annual values reported instead of purchase/sale funds over 5 years

---

*This log is maintained as part of the AMSF gap analysis work. Each survey method gets a semantic audit against the French source questionnaire and the gem's taxonomy structure before implementation.*
