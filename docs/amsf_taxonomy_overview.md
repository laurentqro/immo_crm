# AMSF Taxonomy Overview

This document provides an overview of how the CRM maps to the AMSF (Autorité Monégasque de Sécurité Financière) strix taxonomy for real estate AML/CFT compliance reporting in Monaco.

## Taxonomy Structure

The AMSF real estate survey contains **323 elements** organized into logical sections:

| Section | Elements | Description |
|---------|----------|-------------|
| Tab 1: Customer Risk | 104 | Client demographics, risk assessment, PEP status |
| Tab 2: Products/Services | 37 | Transaction statistics, payment methods |
| Tab 3: STR/Distribution | 44 | Suspicious Transaction Reports, geographic distribution |
| Controls (Policy) | 105 | Organization policies and procedures (aC* elements) |
| Risk Indicators | 21 | Auto-calculated by AMSF based on responses |
| Entity Info | 10 | Organization identification |
| Signatories | 2 | Declaration signatories |

## Element Naming Convention

AMSF taxonomy elements follow a specific naming pattern:

```
a[C][NNNN][S]
```

- `a` - Always starts with lowercase 'a'
- `C` - Optional uppercase letter (e.g., 'C' for controls, 'S' for signatories)
- `NNNN` - 3-5 digit numeric identifier
- `S` - Optional 1-2 character suffix (e.g., 'B', 'BB', 'O')

**Examples:**
- `a1101` - Total client count
- `aC1102` - Control/policy element
- `a2102B` - Purchase transactions count
- `a2102BB` - Purchase transactions value
- `aS1` - Signatory name

## Data Sources

Elements are populated from three sources:

1. **Calculated** - Derived from CRM data (clients, transactions)
2. **From Settings** - Pulled from organization settings (controls/policies)
3. **Manual** - Entered during submission wizard

### Mapping File

See `config/amsf_element_mapping.yml` for the complete element mapping including:
- Element descriptions
- Data source type
- Value type (integer, monetary, string, enum)

## Database Fields

The following fields support taxonomy compliance:

| Table | Field | Type | Purpose |
|-------|-------|------|---------|
| `submissions` | `signatory_name` | string | aS1: Declaration signatory |
| `submissions` | `signatory_title` | string | aS2: Signatory role |
| `clients` | `is_pep_related` | boolean | a12102B: PEP family/associate |
| `clients` | `is_pep_associated` | boolean | a12202B: PEP business associate |
| `clients` | `country_code` | string | Geographic risk elements |
| `clients` | `residence_status` | string | a11302: Resident classification |
| `transactions` | `direction` | string | BY_CLIENT vs WITH_CLIENT |
| `transactions` | `transaction_value` | decimal | Transaction values (a2102BB, a2105BB, a2109B) |
| `beneficial_owners` | `country_code` | string | a1207O: BO geographic risk |
| `beneficial_owners` | `ownership_percentage` | decimal | a1204O: 25% threshold |

## Key Services

### CalculationEngine

`app/services/calculation_engine.rb` computes statistics from CRM data:

```ruby
engine = CalculationEngine.new(organization, year: 2025)

# Get all calculated values
values = engine.calculate_all

# Populate submission values
engine.populate_submission_values(submission)
```

### XbrlGenerator

`app/services/xbrl_generator.rb` creates XBRL XML from submission data:

```ruby
generator = XbrlGenerator.new(submission)
xml = generator.generate
filename = generator.suggested_filename  # "amsf_2025_RCI123456.xml"
```

**Strict Mode:** In test/development environments, the generator raises `XbrlDataError` for invalid data. In production, it logs warnings and uses fallback values.

## Control Elements (aC*)

The 105 aC* elements are Oui/Non (Yes/No) policy questions stored as Settings:

```ruby
# Setting key format: ctrl_<element_code>
Setting::SCHEMA = {
  "ctrl_aC1101Z" => { value_type: "boolean", category: "controls", xbrl: "aC1101Z" },
  "ctrl_aC1102"  => { value_type: "boolean", category: "controls", xbrl: "aC1102" },
  # ... 103 more
}
```

## Dimensional Elements

Element `a1103` (clients by nationality) uses XBRL dimensional contexts:

```xml
<context id="ctx_country_MC">
  <entity>
    <identifier scheme="http://amsf.mc/rci">RCI123456</identifier>
    <segment>
      <strix:CountryDimension>MC</strix:CountryDimension>
    </segment>
  </entity>
</context>

<strix:a1103 contextRef="ctx_country_MC" unitRef="unit_pure">25</strix:a1103>
```

## Testing

Compliance tests verify that all 323 elements can be answered by the CRM:

```bash
# Run all compliance tests
bin/rails test test/compliance/

# Run specific section tests
bin/rails test test/compliance/model_capability/tab1_customer_risk_test.rb
```

## Related Documentation

- `docs/XBRL_EXPLAINED.md` - XBRL format overview
- `docs/gap_analysis.md` - Original gap analysis
- `docs/taxonomy_gap_analysis.md` - Detailed element analysis
- `config/amsf_element_mapping.yml` - Element to CRM mapping
