# XBRL Explained - For This Project

## What is XBRL?

**XBRL** = eXtensible Business Reporting Language

Think of it as a **smart spreadsheet format** that computers can read and understand.

### The Problem XBRL Solves

**Without XBRL (Current Manual Process):**

```
AMSF Form asks: "How many clients do you have?"
You type: "42"

AMSF Form asks: "How many are natural persons?"
You type: "30"

AMSF Form asks: "How many are legal entities?"
You type: "10"

Result: 180+ questions, manual typing, 2 weeks of work
```

**With XBRL:**

```
You create a file that says:
<strix:a1101>42</strix:a1101>          (total clients)
<strix:a1102>30</strix:a1102>          (natural persons)
<strix:a1501>10</strix:a1501>          (legal entities)

AMSF Portal reads the file and auto-fills all 180+ questions

Result: Upload one file, done in minutes
```

---

## How XBRL Works in This Project

### The Three Parts of XBRL

#### 1. **Taxonomy** (The Dictionary)

**What it is:** A set of rules that define what data can be reported and how

**In this project:** The 6 files from FT Solutions:
- `strix_Real_Estate_AML_CFT_survey_2025.xsd` - Main dictionary
- `_lab.xml` - Human-readable labels (English, French, etc.)
- `_pre.xml` - How to display the data
- `_def.xml` - Relationships between data points
- `_cal.xml` - Mathematical formulas
- `_xule` - Validation rules (275 business logic rules)

**Analogy:** Like a dictionary that says:
- "a1101" means "Total unique clients"
- It must be an integer (whole number)
- It must be >= sum of a1102 + a1501 + a1801

#### 2. **Instance Document** (The Report)

**What it is:** An XML file with your actual data

**In this project:** The file you generate (e.g., `test_submission_2025.xml`)

**Contains:**
- Your entity ID
- Reporting date (2025-12-31)
- All your data points: 42 clients, €5.2M transactions, etc.

**Analogy:** Like filling out a form, but in XML format instead of a web form

#### 3. **Validator** (The Checker)

**What it is:** Software that checks if your instance matches the taxonomy

**In this project:** Arelle + XULE plugin

**Checks:**
- Are all elements valid? (defined in taxonomy)
- Are data types correct? (integers, money amounts, text)
- Do business rules pass? (total >= sum of parts)

**Analogy:** Like spell-check, but for compliance data

---

## The Complete Workflow

### Current Process (Manual Form)

```
Step 1: Count clients manually from folders
        ↓ (hours/days)
Step 2: Open AMSF web form
        ↓
Step 3: Type answer to Question 1
        ↓
Step 4: Type answer to Question 2
        ↓
        ... (repeat 180 times)
        ↓
Step 5: Submit form
        ↓
Done! (after 2 weeks)
```

### XBRL Process (What You're Building)

```
Step 1: Enter data into YOUR APP (25-30 questions)
        ↓ (2-4 hours)
Step 2: App calculates remaining values automatically
        ↓ (instant)
Step 3: App generates XBRL file
        ↓ (seconds)
Step 4: App validates XBRL file
        ↓ (seconds)
Step 5: Download XBRL file
        ↓
Step 6: Upload to Strix Portal
        ↓ (minutes)
Step 7: Portal auto-fills all 180+ form fields
        ↓
Step 8: Review and submit
        ↓
Done! (in 2-4 hours total)
```

---

## What Each File Does

### Taxonomy Files (Downloaded from Strix)

**1. strix_Real_Estate_AML_CFT_survey_2025.xsd**
- **Purpose:** Defines all data elements (a1101, a1102, etc.)
- **Size:** 186KB, ~5,500 lines
- **Contains:** 400+ element definitions
- **Example:**
  ```xml
  <element id="strix_a1101"
           name="a1101"
           type="xbrli:integerItemType"
           ...>
  ```
- **What it means:** "a1101 is an integer that represents total clients"

**2. strix_Real_Estate_AML_CFT_survey_2025_lab.xml**
- **Purpose:** Human-readable labels for elements
- **Size:** 423KB
- **Languages:** French, English, etc.
- **Example:** "a1101" = "Veuillez indiquer le nombre total de clients uniques..."

**3. strix_Real_Estate_AML_CFT_survey_2025_pre.xml**
- **Purpose:** Presentation hierarchy (how to display)
- **Defines:** Parent-child relationships
- **Example:** Section 1.1 contains a1101, a1102, a1103...

**4. strix_Real_Estate_AML_CFT_survey_2025_def.xml**
- **Purpose:** Dimensional breakdowns (by country, etc.)
- **Example:** "a1101 can be broken down by CountryDimension"

**5. strix_Real_Estate_AML_CFT_survey_2025_cal.xml**
- **Purpose:** Mathematical relationships
- **Example:** "Total = sum(Part1 + Part2)"

**6. strix_Real_Estate_AML_CFT_survey_2025.xule**
- **Purpose:** Business validation rules
- **Contains:** 275 rules
- **Example:** "Rule 123: a1101 must be >= (a1102 + a1501 + a1801)"

### Your Generated Files

**test_submission_2025.xml (Instance Document)**
- **Purpose:** Contains YOUR actual data for submission
- **Size:** ~2KB (tiny!)
- **Structure:**
  ```xml
  <xbrl>
    <context id="current">
      <entity>TEST_ENTITY_12345</entity>
      <period>2025-12-31</period>
    </context>

    <strix:a1101>42</strix:a1101>
    <strix:a1102>30</strix:a1102>
    ...
  </xbrl>
  ```

**strix_ruleset.zip (Compiled Validation Rules)**
- **Purpose:** Binary version of XULE rules for faster validation
- **Created by:** Arelle compiling the .xule file
- **Used for:** Validating instance documents

---

## Why XBRL is Powerful

### 1. Machine-Readable

**Manual Form:**
- Human reads: "How many clients?"
- Human types: "42"
- Computer stores: "42" (just text)

**XBRL:**
- Computer reads: `<strix:a1101 unitRef="pure">42</strix:a1101>`
- Computer knows: "This is total clients, it's an integer, it's a count"
- Computer can validate: "Is 42 >= sum of client types?"

### 2. Auto-Validation

**Manual Form:**
- You enter: Total = 42, Natural = 30, Legal = 15
- Math error! (30 + 15 = 45, not 42)
- AMSF rejects submission, you have to fix and resubmit

**XBRL:**
- Your app checks BEFORE generating XBRL
- If 30 + 15 ≠ 42, app shows error immediately
- You fix before uploading
- AMSF receives only valid data

### 3. Reusability

**Manual Form:**
- Every year: Start from scratch
- Re-type everything
- No memory of last year

**XBRL:**
- Import last year's XBRL file
- Update changed values
- Generate new file
- Much faster year-over-year

---

## The Value Chain (Who Does What)

### FT Solutions (Infrastructure Provider)

**They built:**
- ✅ Strix Portal (submission website)
- ✅ Taxonomy Generator (creates the 6 .xsd/.xml files)
- ✅ Upload System (accepts XBRL files)
- ✅ Form Auto-Fill (reads XBRL, fills web form)

**They DON'T provide:**
- ❌ Tool to CREATE XBRL files from business data
- ❌ User-friendly data entry
- ❌ Simplified questionnaire

**Their expectation:** Users are "XBRL-lingual" (technical experts)

### Your App (Missing Link)

**You're building:**
- ✅ User-friendly questionnaire (25-30 questions)
- ✅ Calculation engine (auto-calculates related values)
- ✅ XBRL generator (creates instance document)
- ✅ Validator (checks before upload)

**Value:** Translates "normal business data" → "XBRL format"

### AMSF Monaco (Regulator)

**They receive:**
- Compliant XBRL files through Strix portal
- Can analyze data automatically
- Can aggregate across all firms
- Machine-readable for their analytics

---

## Technical Components Explained

### Namespaces

**What they are:** Like area codes for XML elements

**Why needed:** Prevent naming collisions

**Example:**
- `xbrli:context` - From XBRL International standard
- `strix:a1101` - From AMSF's real estate taxonomy
- `iso4217:EUR` - From ISO currency standard

**In code:**
```python
NAMESPACE_STRIX = "https://amlcft.amsf.mc/dcm/DTS/strix_Real_Estate_AML_CFT_survey_2025/fr"
```

This URL is just an identifier, not an actual website you visit.

### Contexts

**What they are:** Define WHEN and WHO the data is about

**Required elements:**
- **Entity:** Who is reporting (your tax ID)
- **Period:** When is this data for (2025-12-31)

**Why needed:** Same entity can submit multiple periods, same period can have multiple entities

**In your XBRL:**
```xml
<context id="current">
  <entity>
    <identifier scheme="http://www.amsf.mc">TEST_ENTITY_12345</identifier>
  </entity>
  <period>
    <instant>2025-12-31</instant>
  </period>
</context>
```

Then every fact references this context:
```xml
<strix:a1101 contextRef="current">42</strix:a1101>
```

### Units

**What they are:** What measurement type (currency, pure numbers, percentages)

**In this taxonomy:**
- **pure** - For counts (42 clients, 85 transactions)
- **EUR** - For money (€5,200,000)

**In your XBRL:**
```xml
<unit id="pure">
  <measure>xbrli:pure</measure>
</unit>

<unit id="EUR">
  <measure>iso4217:EUR</measure>
</unit>
```

Then every fact specifies its unit:
```xml
<strix:a1101 unitRef="pure">42</strix:a1101>
<strix:a1106B unitRef="EUR">5200000</strix:a1106B>
```

### Facts

**What they are:** The actual data points

**Format:**
```xml
<strix:a1101 contextRef="current" unitRef="pure" decimals="0">42</strix:a1101>
```

**Breaking it down:**
- `strix:a1101` - Element name (from taxonomy)
- `contextRef="current"` - Links to context (who/when)
- `unitRef="pure"` - Links to unit (it's a count, not money)
- `decimals="0"` - No decimal places (whole number)
- `42` - The actual value

---

## Why XBRL Can Be Confusing

### It's XML (Verbose)

**To say "42 clients":**

**Simple format:**
```
clients: 42
```

**XBRL format:**
```xml
<xbrli:xbrl xmlns:strix="https://amlcft.amsf.mc/dcm/DTS/strix_Real_Estate_AML_CFT_survey_2025/fr" xmlns:xbrli="http://www.xbrl.org/2003/instance">
  <xbrli:context id="current">
    <xbrli:entity>
      <xbrli:identifier scheme="http://www.amsf.mc">ENTITY_123</xbrli:identifier>
    </xbrli:entity>
    <xbrli:period>
      <xbrli:instant>2025-12-31</xbrli:instant>
    </xbrli:period>
  </xbrli:context>
  <xbrli:unit id="pure">
    <xbrli:measure>xbrli:pure</xbrli:measure>
  </xbrli:unit>
  <strix:a1101 contextRef="current" unitRef="pure" decimals="0">42</strix:a1101>
</xbrli:xbrl>
```

**Why?** The verbosity enables:
- Automatic validation
- Cross-system compatibility
- Multi-dimensional reporting (by country, time, entity)
- Regulatory compliance

### Technical Jargon

- **Schema** = Dictionary of allowed elements
- **Instance** = Your actual data
- **Taxonomy** = Industry-specific schema (real estate, banking, etc.)
- **Linkbase** = Supporting files that add meaning to schema
- **XULE** = Validation rule language
- **Context** = Who and when
- **Fact** = A single data point

---

## Your Project's XBRL Workflow

### Input: Business Data

```
Real Estate Agent's Data:
- 42 clients total
- 30 natural persons, 10 legal entities, 2 trusts
- 85 transactions worth €5.2M
- 15 clients from France, 10 from Monaco, ...
```

### Process: Your App

**Step 1: User Entry**
- User answers 25-30 simplified questions in your web app
- OR uploads Excel with transaction data

**Step 2: Calculation**
- App uses taxonomy knowledge to calculate derived values
- Example: "30 natural persons + 10 legal + 2 trusts = 42 total" ✓

**Step 3: Validation**
- App checks 275 XULE rules
- Ensures data is logically consistent
- Catches errors before XBRL generation

**Step 4: XBRL Generation**
- Your Python code (`generate_xbrl.py`) creates instance document
- Converts data dictionary to proper XML format
- Adds contexts, units, namespaces

**Step 5: Output**
- Download `amsf_submission_2025.xml`
- Ready to upload to Strix

### Output: XBRL Instance File

```xml
<?xml version="1.0"?>
<xbrli:xbrl>
  <!-- Context: Who and When -->
  <xbrli:context id="current">
    <xbrli:entity>
      <xbrli:identifier scheme="http://www.amsf.mc">AGENT_12345</xbrli:identifier>
    </xbrli:entity>
    <xbrli:period>
      <xbrli:instant>2025-12-31</xbrli:instant>
    </xbrli:period>
  </xbrli:context>

  <!-- Units: How to measure -->
  <xbrli:unit id="EUR">
    <xbrli:measure>iso4217:EUR</xbrli:measure>
  </xbrli:unit>

  <xbrli:unit id="pure">
    <xbrli:measure>xbrli:pure</xbrli:measure>
  </xbrli:unit>

  <!-- Facts: The actual data -->
  <strix:a1101 contextRef="current" unitRef="pure" decimals="0">42</strix:a1101>
  <strix:a1102 contextRef="current" unitRef="pure" decimals="0">30</strix:a1102>
  <strix:a1501 contextRef="current" unitRef="pure" decimals="0">10</strix:a1501>
  <strix:a1801 contextRef="current" unitRef="pure" decimals="0">2</strix:a1801>
  <strix:a1106B contextRef="current" unitRef="EUR" decimals="0">5200000</strix:a1106B>
  <!-- ... all other values ... -->
</xbrli:xbrl>
```

### Submission: Upload to Strix

1. Login to Strix portal
2. Choose "Upload XBRL File" (instead of filling form manually)
3. Upload your generated .xml file
4. Portal reads the file
5. Portal auto-fills all 180+ form fields
6. You review and submit
7. Done!

---

## Why This Works for Your Product

### The Magic: Taxonomy Intelligence

**The taxonomy defines relationships:**

```
a1101 (Total clients) =
  a1102 (Natural persons) +
  a1501 (Legal entities) +
  a1801 (Trusts)
```

**Your app knows this rule, so:**

**User enters:**
- Natural persons: 30
- Legal entities: 10
- Trusts: 2

**App calculates:**
- Total clients: 42 (auto-calculated!)

**App generates XBRL:**
```xml
<strix:a1101>42</strix:a1101>
<strix:a1102>30</strix:a1102>
<strix:a1501>10</strix:a1501>
<strix:a1801>2</strix:a1801>
```

**Result:** User answers 3 questions, app populates 4 values (and validates they're consistent)

**Multiply this by 180 questions:** User answers ~30, app populates ~180

---

## Tools Explained

### Arelle

**What it is:** Open-source XBRL processor (like a compiler for XBRL)

**What it does:**
- Loads XBRL taxonomies
- Validates instance documents
- Runs XULE validation rules
- Command-line tool for automation

**Commands you'll use:**
```bash
# Validate instance against schema
arelleCmdLine --file submission.xml --validate

# Run business rule validation
arelleCmdLine --plugins='xule/plugin/xule' \
  --file submission.xml \
  --xule-rule-set strix_ruleset.zip \
  --xule-run
```

### XULE Plugin

**What it is:** Extension for Arelle that adds advanced validation

**What it does:**
- Runs 275 business logic rules
- Example rules:
  - "Total clients >= sum of client types"
  - "Revenue in Monaco + Revenue outside = Total revenue"
  - "PEP transaction count <= total transactions"

**Why you need it:** Schema validation only checks structure, XULE checks business logic

---

## Common XBRL Concepts

### Element Types

**From the taxonomy:**

- **integerItemType** - Whole numbers (42 clients, 85 transactions)
- **monetaryItemType** - Money amounts (€5,200,000)
- **stringItemType** - Text (entity name, comments)
- **booleanItemType** - Yes/No (is PEP? true/false)

### Dimensional Reporting

**Simple fact:**
```xml
<strix:a1101>42</strix:a1101>
```
Means: "42 total clients" (aggregate)

**Dimensional fact:**
```xml
<strix:a1102 contextRef="France">15</strix:a1102>
<strix:a1102 contextRef="Monaco">10</strix:a1102>
<strix:a1102 contextRef="UK">8</strix:a1102>
```
Means: "15 clients from France, 10 from Monaco, 8 from UK" (breakdown by country)

**Your taxonomy uses:** CountryDimension for most metrics

---

## What You Need to Know vs What You Don't

### ✅ You NEED to understand:

1. **Elements** - What data points exist (a1101, a1102, etc.)
2. **Element mapping** - Which question maps to which element
3. **Validation rules** - What relationships must hold (parent >= sum of children)
4. **Instance generation** - How to create the XML file
5. **Upload process** - How to submit to Strix

### ❌ You DON'T need to understand (for your MVP):

1. **How to create taxonomies** - FT Solutions does this
2. **Advanced XBRL features** - Dimensional reporting (comes later)
3. **XULE programming** - Rules already written
4. **Linkbase internals** - Already configured
5. **XBRL specification details** - Your code abstracts this away

---

## For Your Product

### What Users See (Simple)

```
Web form:
┌────────────────────────────────────┐
│ How many clients did you serve?    │
│ [  42  ]                           │
│                                     │
│ Break down by type:                │
│ Natural persons: [ 30 ]            │
│ Legal entities:  [ 10 ]            │
│ Trusts:          [  2 ]            │
│                                     │
│ [Next Step →]                      │
└────────────────────────────────────┘
```

### What Happens Behind the Scenes (Complex)

```
1. Validate input (30 + 10 + 2 = 42 ✓)
2. Map to taxonomy elements
3. Calculate derived values
4. Generate XBRL with proper structure:
   - Namespaces
   - Contexts
   - Units
   - Facts
5. Validate against 275 rules
6. Output XML file
```

### What Users Get (Simple Result)

```
Download: amsf_submission_2025.xml

→ Upload to Strix Portal
→ Portal auto-fills 180+ fields
→ Submit!
```

---

## Summary

**XBRL is:**
- A standardized format for business reporting
- More complex than JSON/CSV but much more powerful
- Enables automatic validation and processing
- Required by AMSF for efficient submission

**Your product:**
- Hides XBRL complexity from users
- Generates XBRL files automatically
- Makes "XBRL submission" accessible to non-technical users
- Saves 2 weeks of manual work

**The opportunity:**
- FT Solutions built XBRL infrastructure but no user-facing tool
- Real estate agents don't know XBRL exists
- You bridge the gap between "business data" and "XBRL format"
- Nobody else is doing this for Monaco

**Next step:** Upload your generated test file to Strix portal to see if it actually works end-to-end!

---

**Questions?** Let me know what you'd like me to explain further!
