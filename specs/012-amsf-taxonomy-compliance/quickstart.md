# Quickstart: AMSF Taxonomy Compliance

**Branch**: `012-amsf-taxonomy-compliance`
**Date**: 2024-12-03

## Prerequisites

- Ruby 3.2+
- Rails 8.0
- PostgreSQL running
- Dependencies installed (`bundle install`)

## Verify Current State (Tests Failing)

```bash
# Run compliance tests - expect 4 failures
bin/rails test test/compliance/

# Expected output shows invalid elements:
# - 21 invalid element names in CalculationEngine
# - 11 invalid category names in mapping configuration
```

## Key Files to Modify

| File | Purpose | Change Type |
|------|---------|-------------|
| `app/services/calculation_engine.rb` | Fix 21 element names | Element name changes |
| `config/amsf_element_mapping.yml` | Restructure to flat format | Configuration restructure |
| `app/services/xbrl_generator.rb` | Fix dimensional contexts, type handling | Logic changes |

## Implementation Order

### Step 1: Fix CalculationEngine Element Names

Update element name strings in these methods:

```ruby
# client_statistics method
"a1301" => "a12002B"  # PEP clients

# beneficial_owner_statistics method
"a1502" => "a1502B"   # PEP beneficial owners

# transaction_statistics method
"a2102" => "a2102B"   # Purchase count
"a2103" => "a2105B"   # Sale count
"a2104" => "a2107B"   # Rental count

# transaction_values method
"a2105" => "a2102BB"  # Purchase value
"a2106" => "a2105BB"  # Sale value
"a2107" => "a2107BB"  # Rental value

# payment_method_statistics method
"a2201" => "a2203"    # Cash count
"a2301" => "a2501A"   # Crypto count

# Remove pep_transaction_statistics entirely (a2401 not in taxonomy)
```

### Step 2: Fix Country Breakdown

Replace underscore pattern with metadata:

```ruby
# Before (invalid)
result["a1103_#{safe_nationality}"] = count

# After (valid - store metadata for XbrlGenerator)
result["a1103"] ||= {}
result["a1103"][safe_nationality] = count
```

### Step 3: Restructure Element Mapping YAML

Convert from category-nested to flat structure. Remove non-taxonomy elements.

### Step 4: Fix XbrlGenerator Type Handling

Update `format_value` to use French booleans:

```ruby
# Before
value.to_s.downcase.in?(%w[true yes 1]) ? "true" : "false"

# After
value.to_s.downcase.in?(%w[true yes 1 oui]) ? "Oui" : "Non"
```

### Step 5: Fix Dimensional Contexts

Update `build_country_contexts` and `build_facts` to handle the new country data structure with proper dimensional contexts.

## Verify Success

```bash
# All compliance tests should pass
bin/rails test test/compliance/

# Expected: 57 tests, 0 failures, 0 errors

# Run RuboCop
bin/rubocop app/services/calculation_engine.rb app/services/xbrl_generator.rb
```

## Test Commands

```bash
# Run specific test files
bin/rails test test/compliance/xbrl_taxonomy_test.rb      # Element names
bin/rails test test/compliance/xbrl_calculation_test.rb   # Calculation accuracy
bin/rails test test/compliance/element_mapping_test.rb    # YAML structure
bin/rails test test/compliance/xbrl_dimension_test.rb     # Country contexts
bin/rails test test/compliance/xbrl_type_test.rb          # Type handling
bin/rails test test/compliance/xbrl_structure_test.rb     # Document structure

# Run all compliance tests
bin/rails test test/compliance/

# Run with verbose output
bin/rails test test/compliance/ -v
```

## Debugging Tips

### Check Generated XBRL

```ruby
# In Rails console
submission = Submission.last
CalculationEngine.new(submission).populate_submission_values!
xml = XbrlGenerator.new(submission).generate
puts xml
```

### Validate Element Names

```ruby
# Check if element exists in taxonomy
XbrlTestHelper.valid_element_names.include?("a12002B")  # => true
XbrlTestHelper.valid_element_names.include?("a1301")    # => false

# Get suggestion for invalid element
XbrlTestHelper.suggest_element_name("a1301")  # => "a1101" (closest match)
```

### Check Element Types

```ruby
# Get type for an element
XbrlTestHelper.element_types["a12002B"]  # => :integer
XbrlTestHelper.element_types["a2104B"]   # => :monetary

# Get allowed values for enum
XbrlTestHelper.enum_values["a11001BTOLA"]  # => ["Oui", "Non"]
```

## Reference Documents

- `docs/gap_analysis.md` - Element mapping reference
- `docs/strix_Real_Estate_AML_CFT_survey_2025.xsd` - Official taxonomy
- `test/support/xbrl_test_helper.rb` - Test utilities
