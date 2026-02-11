# New Client Counts by Type for Survey Period (Q173-Q175)

## Survey Questions
- **Q173:** Number of new clients (natural persons) during reporting period
- **Q174:** Number of new clients (legal entities) during reporting period  
- **Q175:** Number of new clients (trusts/other legal constructions) during reporting period

## What Needs to Be Done
Add calculation methods to derive new client counts by type within a given survey period, using the `became_client_at` timestamp on the Client model.

## Implementation
- Add `new_natural_persons_count(year:)` method
- Add `new_legal_entities_count(year:)` method
- Add `new_trusts_count(year:)` method
- Wire into the calculation engine for survey elements

## Acceptance Criteria
- [ ] Methods return correct counts filtered by `became_client_at` within the reporting year
- [ ] Counts are broken down by client_type (NATURAL_PERSON, LEGAL_ENTITY, trust subtypes)
- [ ] Tests cover edge cases (client created on Jan 1, Dec 31, outside period)
- [ ] Integrated into CalculationEngine
