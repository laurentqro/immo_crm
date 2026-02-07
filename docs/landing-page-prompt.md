# Landing Page Prompt for Immo CRM

> Design and build a marketing landing page for **Immo CRM** — an AML/KYC compliance CRM purpose-built for Monaco real estate professionals.
>
> ## Product positioning
>
> Immo CRM eliminates the compliance burden for Monaco real estate agents, notaries, and property managers who must comply with AML/CFT regulations and submit annual AMSF surveys. Instead of spreadsheets and manual XBRL filing, Immo CRM automates client onboarding, beneficial owner tracking, risk scoring, transaction monitoring, staff training records, and generates ready-to-submit AMSF regulatory surveys — all from one place.
>
> ## Page structure
>
> **Hero section:**
> - Headline emphasizing pain relief: compliance is mandatory, but it doesn't have to be painful
> - Subheadline: one platform replacing scattered spreadsheets, manual XBRL, and audit anxiety
> - Primary CTA: waitlist signup form (name, email, company name, role dropdown: Agent immobilier / Notaire / Promoteur / Syndic / Autre)
> - Trust signal: "Built for Monaco AML/CFT regulations"
>
> **Benefits section (4-6 cards):**
> 1. **Automated AMSF surveys** — Annual regulatory submissions generated from your live data, no manual XBRL editing
> 2. **Client onboarding & KYC** — Structured client intake with document collection, PEP screening, risk scoring
> 3. **Beneficial owner tracking** — Full UBO chains with HNWI/UHNWI classification, automatically reflected in compliance reports
> 4. **Transaction monitoring** — Track cash payments, cross-border transfers, suspicious activity — with audit trails
> 5. **Staff training management** — Log AML training hours per employee, satisfy regulatory requirements
> 6. **Audit-ready at all times** — Every decision documented, every field traceable, ready for AMSF inspection
>
> **Social proof / credibility section:**
> - "Designed by compliance professionals in Monaco"
> - "Aligned with AMSF (amsf.mc) requirements"
> - "AMSF questionnaire coverage: 323 fields, fully automated"
>
> **How it works (3 steps):**
> 1. Add your clients and properties
> 2. Immo CRM scores risks and tracks obligations automatically
> 3. Generate and submit your AMSF survey with one click
>
> **FAQ section (4-5 questions):**
> - Who is this for?
> - What regulations does it cover?
> - Do I need to understand XBRL?
> - When will it be available?
> - Is my data secure?
>
> **Footer:** Repeat waitlist CTA, contact email, Monaco flag/locale indicator
>
> ## Technical requirements
>
> - Single static HTML page with TailwindCSS (CDN is fine for a landing page)
> - Clean, professional design — navy/dark blue primary, white/light gray backgrounds, subtle gold or green accents for trust
> - Mobile-responsive
> - The waitlist form should POST to `/waitlist` (we'll wire up the backend separately)
> - Include proper `<meta>` tags for SEO (title, description, og:image placeholder)
> - Smooth scroll between sections
> - Subtle animations on scroll (intersection observer, nothing heavy)
> - Create **two versions**: English (`public/landing.html`) and French (`public/landing-fr.html`). The French version should use formal "vous" throughout. Both pages should include a language switcher linking to the other version.
> - Primary market is Monaco francophone professionals, but an English version is needed for international clients.
>
> ## Design tone
>
> Professional but not corporate-sterile. The feeling should be: "finally, someone built this for us." Avoid generic SaaS jargon. Speak directly to the Monaco real estate professional who dreads their annual AMSF submission and worries about their next audit.
