# Research: AMSF Survey Review Page

**Branch**: `015-amsf-survey-review` | **Date**: 2025-12-05
**Source**: Brainstorming session documented in `docs/plans/2025-12-05-amsf-wizard-redesign.md`

## Summary

This document captures research findings from the brainstorming session that informed the survey review page design. Key decisions were made considering the recently merged taxonomy-driven architecture.

## Key Findings

### 1. AMSF Taxonomy Structure

The AMSF taxonomy files (`docs/taxonomy/`) contain only 3 internal groupings:
- `NoCountryDimension`
- `aAC` (Account-related)
- `aLE` (Legal Entity-related)

**Critical Discovery**: The 5-tab/25-section questionnaire structure exists only in the official PDF questionnaire, NOT in the XBRL taxonomy files. This requires a separate Ruby module to define the mapping.

### 2. Existing Infrastructure

The codebase already provides:

| Component | Purpose | Location |
|-----------|---------|----------|
| `Xbrl::Taxonomy` | Singleton loader for taxonomy elements | `app/models/xbrl/taxonomy.rb` |
| `Xbrl::TaxonomyElement` | Value object with element metadata | `app/models/xbrl/taxonomy_element.rb` |
| `Xbrl::ElementManifest` | Combines elements with submission values | `app/models/xbrl/element_manifest.rb` |
| `SubmissionValue` | Stores calculated/manual values | `app/models/submission_value.rb` |

### 3. Scale Considerations

- ~323 non-abstract elements in AMSF taxonomy
- ~300 elements displayed on review page
- ~25 sections across 5 questionnaire tabs
- Single page load with all elements is acceptable for client-side filtering

## Design Decisions

### Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Survey structure storage | Ruby module with constant | Boot-time validation, no runtime parsing, easily testable |
| Module naming | `Xbrl::Survey` | Matches terminology in spec, cleaner than "Questionnaire" or "AmsfStructure" |
| ElementManifest usage | Delegate to existing abstraction | Reuses proven infrastructure, maintains single source of truth |
| Backwards compatibility | Not needed | Old step URLs can 404, no external dependencies |

### UI/UX Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Page structure | Single scrollable page | Simpler than tabs, allows global search across all elements |
| Section display | All sections expanded | Users reviewing compliance data want to see everything |
| Filtering mechanism | Client-side Stimulus | Instant UX, all data already loaded (~300 elements) |
| Search + filter | Text search + "needs review" toggle | Addresses both "find specific element" and "focus on flagged items" use cases |
| Lock/unlock system | Removed for MVP | Complexity not justified; single-user workflows assumed initially |
| Inline editing | Read-only for MVP | Reduces scope; editing can be added in future iteration |

### Implementation Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| `needs_review` storage | `SubmissionValue.metadata['flagged_for_review']` | Uses existing JSONB field, no migration needed |
| `needs_review` surfacing | Parameter to `ElementValue` struct | Clean interface, computed at manifest build time |
| Completion flow | Button at bottom of page | Natural flow after scrolling through all elements |
| CalculationEngine | Keep existing for now | Lambda-based computation is separate refactoring effort |

## Open Questions (Resolved)

1. **Q**: Why Stimulus over Turbo Frames for filtering?
   **A**: Filtering ~300 DOM elements is faster client-side than round-tripping to server. Turbo would require network latency on every keystroke.

2. **Q**: Should sections be collapsible?
   **A**: No. Given the critical nature of AMSF compliance, users will review all answers closely. Collapsing adds clicks without value.

3. **Q**: Tabs or single page?
   **A**: Single page with section headers. With search/filter, tabs add navigation overhead without benefit.

## References

- [AMSF Wizard Redesign Plan](../../docs/plans/2025-12-05-amsf-wizard-redesign.md)
- [XBRL Architecture Documentation](../../docs/xbrl_architecture.md)
- [AMSF Taxonomy Schema](../../docs/taxonomy/strix_Real_Estate_AML_CFT_survey_2025.xsd)
