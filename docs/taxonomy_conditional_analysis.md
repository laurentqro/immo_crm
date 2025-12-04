# AMSF Taxonomy: Gate Questions & Conditional Logic

**Generated:** 2025-12-03
**Purpose:** Map gate questions to conditional follow-ups for prioritized implementation

---

## How the Questionnaire Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CONDITIONAL LOGIC                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   GATE QUESTION                    CONDITIONALS                             │
│   ─────────────                    ────────────                             │
│                                                                             │
│   'Do you have PEP clients?'  ──► If Oui: 'How many PEP-related?'          │
│   (a12002B = count or 0)          (a12102B, a12202B required)               │
│                                                                             │
│   'Did you file STRs?'        ──► If Oui: 'How many? By type?'             │
│   (a3101 = Oui/Non)               (a3102, a3104, a3105 required)            │
│                                                                             │
│   'Do you have AML policy?'   ──► Standalone (no conditionals)             │
│   (aC1101Z = Oui/Non)                                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Summary by Section

| Section | Gate Questions | Conditional Details | Notes |
|---------|----------------|---------------------|-------|
| Tab 1: Customer Risk | ~25 | ~75 | If no clients, skip details |
| Tab 2: Products & Services | ~15 | ~22 | If no transactions, skip details |
| Tab 3: STR & Distribution | ~15 | ~29 | If no STRs, skip details |
| Tab 4: Controls | 70 | 35 | Policy Oui/Non questions |
| Signatories | 2 | 0 | **Always required** |
| Entity Info | 9 | 0 | Basic org data |
| Risk Indicators | 0 | 21 | Auto-calculated by AMSF |

---

## Tab 1: Customer Risk

### `a1101`: Do you have clients?

- **Type:** integer
- **Status:** ✅ READY
- **If answered:** Must provide: `a1102`, `a1103`, `a1104`
- **Conditional desc:** Client type breakdowns

### `a1105B`: Operations BY clients?

- **Type:** integer
- **Status:** ⚠️ CHECK
- **If answered:** Must provide: `a1106B`, `a1106BRENTALS`
- **Conditional desc:** Operation values BY clients

### `a1105W`: Operations WITH clients (agent)?

- **Type:** integer
- **Status:** ❌ NEEDS: Transaction.direction
- **If answered:** Must provide: `a1106W`
- **Conditional desc:** Operation values WITH clients

### `a11201BCD`: Clients from high-risk countries?

- **Type:** oui_non
- **Status:** ⚠️ CHECK
- **If answered:** Must provide: `a11302`, `a11302RES`, `a11304B`, `a11305B`, `a11307`, `a11309B`
- **Conditional desc:** High-risk country details

### `a11502B`: Legal entity clients?

- **Type:** integer
- **Status:** ✅ READY
- **If answered:** Must provide: `a11602B`, `a11702B`
- **Conditional desc:** Legal entity breakdowns

### `a11802B`: Trust/TOLA clients?

- **Type:** integer
- **Status:** ✅ READY
- **If answered:** Must provide: `a11001BTOLA`
- **Conditional desc:** TOLA details

### `a12002B`: PEP clients?

- **Type:** integer
- **Status:** ✅ READY
- **If answered:** Must provide: `a12102B`, `a12202B`
- **Conditional desc:** PEP-related/associated

### `a1202O`: Beneficial owners identified?

- **Type:** integer
- **Status:** ⚠️ CHECK
- **If answered:** Must provide: `a1202OB`, `a1203`, `a1203D`, `a1204O`, `a1207O`, `a1210O`
- **Conditional desc:** BO breakdowns

### `a1501`: Total beneficial owners?

- **Type:** integer
- **Status:** ✅ READY
- **If answered:** Must provide: `a1502B`
- **Conditional desc:** PEP beneficial owners

## Tab 2: Products & Services

### `a2101B`: Transactions BY clients?

- **Type:** oui_non
- **Status:** ✅ READY (can derive from Transaction count)
- **If answered:** Must provide: `a2102B`, `a2105B`, `a2108B`, `a2102BB`, `a2105BB`, `a2109B`
- **Conditional desc:** Transaction counts and values BY clients

### `a2101W`: Transactions WITH clients (agent)?

- **Type:** oui_non
- **Status:** ❌ NEEDS: Transaction.direction
- **If answered:** Must provide: `a2102W`, `a2105W`, `a2108W`, `a2102BW`, `a2105BW`, `a2109W`
- **Conditional desc:** Transaction counts and values WITH clients

### `a2101WRP`: Recurring payments WITH clients?

- **Type:** oui_non
- **Status:** ❌ NEEDS: Transaction.direction
- **If answered:** Must provide: `a2104WRP`, `a2107WRP`
- **Conditional desc:** Recurring payment details

### `a2202`: Cash transactions?

- **Type:** oui_non
- **Status:** ✅ READY
- **If answered:** Must provide: `a2203`
- **Conditional desc:** Cash transaction details

### `a2501A`: Virtual asset transactions?

- **Type:** oui_non
- **Status:** ✅ READY
- **If answered:** Must provide: `a2501`
- **Conditional desc:** VASP details

## Tab 3: STR & Distribution

### `a3101`: Filed any STRs?

- **Type:** oui_non
- **Status:** ✅ READY (can derive from StrReport count)
- **If answered:** Must provide: `a3102`, `a3104`, `a3105`
- **Conditional desc:** STR counts by client type

### `a3201`: Use specific identification methods?

- **Type:** oui_non
- **Status:** ⚠️ CHECK
- **If answered:** Must provide: `a3202`, `a3203`, `a3204`, `a3205`
- **Conditional desc:** Identification method details

## Tab 4: Controls (Policy Questions)

> Total 70 policy questions. All are Oui/Non with no conditionals.

### `aC1106`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11101`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11102`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11103`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11104`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11105`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11201`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC1125A`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11301`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

### `aC11304`: Policy question (Oui/Non)

- **Type:** oui_non
- **Status:** ⚠️ NEEDS: Setting record

## Signatories (Required)

### `aS1`: Signatory name

- **Type:** string
- **Status:** ❌ NEEDS: Submission.signatory_name field

### `aS2`: Signatory title

- **Type:** string
- **Status:** ❌ NEEDS: Submission.signatory_title field

---

## Implementation Priority

### 🔴 Priority 1: Always Required

| Element | What | Model Change |
|---------|------|--------------|
| `aS1` | Signatory name | `Submission.signatory_name` |
| `aS2` | Signatory title | `Submission.signatory_title` |

### 🟠 Priority 2: Gate Questions We Must Answer

These gates determine what else we need to provide:

| Gate | Question | Current Status |
|------|----------|----------------|
| `a2101B` | Had transactions BY clients? | ✅ Can derive from Transaction count |
| `a2101W` | Had transactions WITH clients? | ❌ Need Transaction.direction |
| `a3101` | Filed STRs? | ✅ Can derive from StrReport count |
| `a12002B` | Have PEP clients? | ✅ Can derive from Client.is_pep |
| `aC*` (70) | Policy questions | ⚠️ Need 70 Setting records |

### 🟡 Priority 3: Conditional Details (only if gate = Oui)

If you answered Oui to a gate, you must provide its conditionals.

**Already covered:**
- Transaction counts/values BY clients (a2102B, a2105B, a2108B, etc.)
- STR count (a3102)
- Client breakdowns (a1101, a1102, etc.)

**Need model changes:**
- WITH clients data (need Transaction.direction)
- PEP-related/associated (need Client.is_pep_related, is_pep_associated)
- Residence breakdowns (need Client.residence_status)

### 🟢 Priority 4: Nice to Have

- High-net-worth indicators (Client.is_hnwi)
- Recurring payment tracking (Transaction.is_recurring)
- Detailed BO categories
