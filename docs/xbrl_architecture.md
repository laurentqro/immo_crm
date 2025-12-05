# XBRL Architecture

This document describes the architecture of the XBRL rendering system for AMSF compliance submissions.

## Component Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION LAYER                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐       │
│  │   XbrlHelper     │    │  show.xml.erb    │    │  show.html.erb   │       │
│  │                  │    │  (XBRL template) │    │  (Review page)   │       │
│  │ • format_xbrl_*  │    │                  │    │                  │       │
│  │ • format_html_*  │    │                  │    │                  │       │
│  │ • parse_country  │    │                  │    │                  │       │
│  └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘       │
│           │                       │                       │                  │
└───────────┼───────────────────────┼───────────────────────┼──────────────────┘
            │                       │                       │
            ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               SERVICE LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                       SubmissionRenderer                              │   │
│  │                                                                       │   │
│  │  • to_xbrl()      → Renders XBRL XML instance document               │   │
│  │  • to_html()      → Renders HTML review page                         │   │
│  │  • to_markdown()  → Renders Markdown export                          │   │
│  │                                                                       │   │
│  │  Raises: SubmissionRenderer::RenderError                             │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                       Xbrl::ElementManifest                           │   │
│  │                                                                       │   │
│  │  • element_with_value(name)  → ElementValue (element + stored value) │   │
│  │  • all_elements_with_values  → Array of ElementValues with data      │   │
│  │  • elements_by_section       → Grouped by presentation section       │   │
│  │                                                                       │   │
│  │  Inner class: ElementValue (combines TaxonomyElement + SubmissionValue)│  │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                MODEL LAYER                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐              ┌─────────────────────┐               │
│  │   Xbrl::Taxonomy    │              │   SubmissionValue   │               │
│  │   (Singleton)       │              │   (ActiveRecord)    │               │
│  │                     │              │                     │               │
│  │ • element(name)     │              │ • element_name      │               │
│  │ • elements          │              │ • value             │               │
│  │ • elements_by_name  │              │ • source            │               │
│  │ • short_label_for   │              │ • overridden?       │               │
│  └──────────┬──────────┘              └──────────┬──────────┘               │
│             │                                    │                          │
│             ▼                                    │                          │
│  ┌─────────────────────┐                         │                          │
│  │ Xbrl::TaxonomyElement│                        │                          │
│  │                     │                         │                          │
│  │ • name, type, label │                         │                          │
│  │ • short_label       │                         │                          │
│  │ • unit_ref          │                         │                          │
│  │ • section, order    │                         │                          │
│  └─────────────────────┘                         │                          │
│                                                  │                          │
└──────────────────────────────────────────────────┼──────────────────────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA SOURCES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────┐    ┌─────────────────────────────────┐ │
│  │      AMSF Taxonomy Files        │    │        PostgreSQL Database      │ │
│  │      (docs/taxonomy/)           │    │                                 │ │
│  │                                 │    │  ┌───────────────────────────┐  │ │
│  │  • *.xsd  (element definitions) │    │  │    submission_values      │  │ │
│  │  • *_lab.xml (labels)           │    │  │                           │  │ │
│  │  • *_pre.xml (presentation)     │    │  │  submission_id            │  │ │
│  │                                 │    │  │  element_name             │  │ │
│  └─────────────────────────────────┘    │  │  value                    │  │ │
│                                         │  │  source                   │  │ │
│  ┌─────────────────────────────────┐    │  │  overridden               │  │ │
│  │    config/xbrl_short_labels.yml │    │  └───────────────────────────┘  │ │
│  │    (manual short labels)        │    │                                 │ │
│  └─────────────────────────────────┘    └─────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow: Rendering XBRL

```
┌──────────┐     ┌───────────────────┐     ┌─────────────────┐     ┌──────────┐
│Controller│────▶│SubmissionRenderer │────▶│ ElementManifest │────▶│  Output  │
└──────────┘     └───────────────────┘     └─────────────────┘     └──────────┘
     │                    │                        │                     │
     │  1. new(submission)│                        │                     │
     │  ─────────────────▶│                        │                     │
     │                    │  2. new(submission)    │                     │
     │                    │  ─────────────────────▶│                     │
     │                    │                        │                     │
     │  3. to_xbrl()      │                        │                     │
     │  ─────────────────▶│                        │                     │
     │                    │  4. all_elements_      │                     │
     │                    │     with_values()      │                     │
     │                    │  ─────────────────────▶│                     │
     │                    │                        │  5. Query           │
     │                    │                        │     Taxonomy +      │
     │                    │                        │     SubmissionValues│
     │                    │                        │                     │
     │                    │  6. [ElementValue,...] │                     │
     │                    │  ◀─────────────────────│                     │
     │                    │                        │                     │
     │                    │  7. Render ERB         │                     │
     │                    │     template with      │                     │
     │                    │     XbrlHelper         │                     │
     │                    │                        │                     │
     │  8. XML String     │                        │                     │
     │  ◀─────────────────│                        │                     │
     │                    │                        │                     │
```

## Key Classes

### Xbrl::Taxonomy (Singleton)

Parses and caches AMSF taxonomy files. Loaded at boot time via initializer.

```ruby
Xbrl::Taxonomy.element("a1101")     # => TaxonomyElement
Xbrl::Taxonomy.elements             # => [TaxonomyElement, ...] (sorted)
Xbrl::Taxonomy.elements_by_section  # => {"Section" => [...]}
```

**Raises:** `Xbrl::TaxonomyLoadError` if files missing/corrupt

### Xbrl::TaxonomyElement

Value object holding element metadata from taxonomy.

| Attribute       | Source              | Description                    |
|-----------------|---------------------|--------------------------------|
| `name`          | XSD                 | Element code (e.g., "a1101")   |
| `type`          | XSD                 | :integer, :monetary, :boolean  |
| `label`         | _lab.xml            | French display label           |
| `verbose_label` | _lab.xml            | Full description               |
| `short_label`   | config YAML         | Concise UI label               |
| `section`       | _pre.xml            | Presentation grouping          |
| `order`         | _pre.xml            | Display order                  |
| `unit_ref`      | Derived from type   | "unit_EUR" or "unit_pure"      |

### Xbrl::ElementManifest

Combines taxonomy elements with stored submission values.

```ruby
manifest = Xbrl::ElementManifest.new(submission)
manifest.element_with_value("a1101")  # => ElementValue
manifest.all_elements_with_values     # => [ElementValue, ...] (only stored)
```

### ElementManifest::ElementValue

Inner class combining element metadata with submission data.

| Attribute   | Type            | Description                     |
|-------------|-----------------|----------------------------------|
| `element`   | TaxonomyElement | Metadata from taxonomy           |
| `value`     | String          | Stored value                     |
| `source`    | String          | "calculated", "manual", etc.     |
| `overridden`| Boolean         | User overrode calculated value   |

Delegates type checks: `integer?`, `monetary?`, `numeric?`, `boolean?`

### SubmissionRenderer

Renders submissions to multiple output formats.

```ruby
renderer = SubmissionRenderer.new(submission)
renderer.to_xbrl      # => XML string
renderer.to_html      # => HTML string
renderer.to_markdown  # => Markdown string
```

**Raises:** `SubmissionRenderer::RenderError` with `:format` and `:cause`

### XbrlHelper

View helper for formatting values in templates.

| Method              | Output Format | Example Output        |
|---------------------|---------------|----------------------|
| `format_xbrl_value` | XBRL XML      | "Oui", "42", "123.45" |
| `format_html_value` | HTML          | "Yes", "42", "€123.45"|
| `parse_country_data`| Hash          | {"FR" => 5, "MC" => 3}|

## Error Handling

```
┌─────────────────────────────────────────────────────────────┐
│                     Exception Hierarchy                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  StandardError                                               │
│  ├── Xbrl::TaxonomyLoadError                                │
│  │   • file_path: String                                    │
│  │   • cause: Exception                                     │
│  │                                                          │
│  └── SubmissionRenderer::RenderError                        │
│      • format: Symbol (:xbrl, :html)                        │
│      • cause: Exception                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
app/
├── helpers/
│   └── xbrl_helper.rb           # Formatting for views
├── models/
│   └── xbrl/
│       ├── taxonomy.rb          # Singleton taxonomy loader
│       ├── taxonomy_element.rb  # Element value object
│       └── element_manifest.rb  # Element + value combiner
├── services/
│   └── submission_renderer.rb   # Multi-format renderer
└── views/
    └── submissions/
        └── show.xml.erb         # XBRL template

config/
└── xbrl_short_labels.yml        # Manual short labels

docs/
└── taxonomy/
    ├── *.xsd                    # Schema definitions
    ├── *_lab.xml                # Label linkbase
    └── *_pre.xml                # Presentation linkbase
```

## Testing

```bash
# Run all XBRL-related tests
bin/rails test test/models/xbrl/ test/services/submission_renderer_test.rb

# Key test coverage:
# - Taxonomy parsing and caching
# - Element manifest value resolution
# - XBRL output structure validation
# - Schema element name validation
# - Context/unit referential integrity
```

## Adding New Taxonomy Versions

When AMSF releases a new taxonomy version:

### 1. Replace Taxonomy Files

```bash
# Backup current taxonomy
mv docs/taxonomy docs/taxonomy_2025_backup

# Add new taxonomy files
mkdir docs/taxonomy
cp /path/to/new/*.xsd docs/taxonomy/
cp /path/to/new/*_lab.xml docs/taxonomy/
cp /path/to/new/*_pre.xml docs/taxonomy/
```

### 2. Update File Constants

In `app/models/xbrl/taxonomy.rb`, update the filename constants:

```ruby
SCHEMA_FILE = "strix_Real_Estate_AML_CFT_survey_2026.xsd"  # New year
LABEL_FILE = "strix_Real_Estate_AML_CFT_survey_2026_lab.xml"
PRESENTATION_FILE = "strix_Real_Estate_AML_CFT_survey_2026_pre.xml"
```

### 3. Update Short Labels

Review `config/xbrl_short_labels.yml` for any new elements that need concise labels.

### 4. Test

```bash
bin/rails test test/models/xbrl/
```

The app will fail to boot if taxonomy files are missing or malformed (fail-fast design).

## Migration Path When Taxonomy Changes

### Element Additions

New elements are automatically available. Add calculation logic in `CalculationEngine` if needed.

### Element Removals

1. Old `SubmissionValue` records remain in the database (harmless)
2. They won't appear in new XBRL output (only taxonomy elements are rendered)
3. Optional: create a migration to clean up orphaned values

```ruby
# Optional cleanup migration
SubmissionValue.where.not(element_name: Xbrl::Taxonomy.elements.map(&:name)).delete_all
```

### Element Type Changes

If an element's type changes (e.g., integer → monetary):

1. Update `config/xbrl_short_labels.yml` if the label needs adjustment
2. Existing values may need conversion—review stored data
3. The taxonomy parser will pick up the new type automatically

### Schema URL Changes

Update the schema reference in `app/views/submissions/show.xml.erb`:

```erb
<link:schemaRef
  xlink:type="simple"
  xlink:href="https://amlcft.amsf.mc/dcm/DTS/NEW_PATH/schema.xsd"/>
```

## Dimensional Elements

Dimensional elements require per-dimension breakdown (e.g., counts by country).

### How They Work

1. **Definition**: Listed in `Taxonomy::DIMENSIONAL_ELEMENTS` constant
2. **Storage**: Value is stored as JSON: `{"FR": 5, "MC": 3, "IT": 2}`
3. **Rendering**: Creates separate XBRL contexts per dimension value

```xml
<!-- Each country gets its own context -->
<context id="ctx_country_FR">
  <entity>
    <identifier scheme="http://amsf.mc/rci">12345</identifier>
    <segment>
      <strix:CountryDimension>FR</strix:CountryDimension>
    </segment>
  </entity>
  <period><instant>2024-12-31</instant></period>
</context>

<!-- Facts reference their dimensional context -->
<strix:a1103 contextRef="ctx_country_FR" unitRef="unit_pure">5</strix:a1103>
<strix:a1103 contextRef="ctx_country_MC" unitRef="unit_pure">3</strix:a1103>
```

### Adding New Dimensional Elements

1. Add the element name to the constant:

```ruby
# app/models/xbrl/taxonomy.rb
DIMENSIONAL_ELEMENTS = %w[a1103 a1104].freeze  # Add new element
```

2. Ensure the UI captures data as a hash (country → count mapping)

3. The template handles rendering automatically via `element.dimensional?`

### Validation

Country codes are validated against ISO 3166-1 alpha-2 using the `countries` gem.
Invalid codes are logged and excluded from XBRL output.
