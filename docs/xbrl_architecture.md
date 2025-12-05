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

Parses and caches AMSF taxonomy files. Thread-safe loading with mutex.

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
