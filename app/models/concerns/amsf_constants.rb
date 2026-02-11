# frozen_string_literal: true

# AMSF (Monaco AML/CFT) enumeration values and constants.
# These map to XBRL taxonomy elements for the annual AML/CFT submission.
#
# Reference: Monaco AMSF Real Estate Professionals AML/CFT Survey
# Taxonomy: strix_Real_Estate_AML_CFT_survey_2025
# See: docs/strix_Real_Estate_AML_CFT_survey_2025.xsd for full schema
# See: Xbrl::Taxonomy for element metadata parsed from AMSF taxonomy
#
module AmsfConstants
  extend ActiveSupport::Concern

  # Client types (Personne Physique, Personne Morale)
  CLIENT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY].freeze

  # Transaction types
  TRANSACTION_TYPES = %w[PURCHASE SALE RENTAL].freeze

  # Payment methods
  PAYMENT_METHODS = %w[WIRE CASH CHECK CRYPTO MIXED].freeze

  # Agency roles in transaction
  AGENCY_ROLES = %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].freeze

  # Risk assessment levels
  RISK_LEVELS = %w[LOW MEDIUM HIGH].freeze

  # Politically Exposed Person types
  PEP_TYPES = %w[DOMESTIC FOREIGN INTL_ORG].freeze

  # Beneficial owner control types
  CONTROL_TYPES = %w[DIRECT INDIRECT REPRESENTATIVE].freeze

  # Virtual Asset Service Provider types
  VASP_TYPES = %w[EXCHANGE CUSTODIAN ICO TRANSFER DEFI NFT PAYMENT FUND_MANAGEMENT OTHER].freeze

  # AMSF named VASP categories (XBRL has dedicated fields for these three)
  # Everything else maps to the AMSF "other" bucket in survey fields.
  AMSF_NAMED_VASP_TYPES = %w[EXCHANGE CUSTODIAN ICO].freeze

  # Human-readable labels for VASP types
  VASP_TYPE_LABELS = {
    "EXCHANGE" => "Virtual currency exchange",
    "CUSTODIAN" => "Custodian wallet provider",
    "ICO" => "Token offering services (ICO/STO)",
    "TRANSFER" => "Virtual asset transfer/remittance",
    "DEFI" => "DeFi services (lending, staking, yield)",
    "NFT" => "NFT marketplace/services",
    "PAYMENT" => "Crypto payment processing",
    "FUND_MANAGEMENT" => "Crypto asset/fund management",
    "OTHER" => "Other"
  }.freeze

  # Legal entity types (Monaco corporate forms + AMSF taxonomy types)
  LEGAL_ENTITY_TYPES = %w[
    SCI SARL SAM SNC SA SCS SCA SCP
    GIE EI
    FOUNDATION ASSOCIATION
    OTHER_CIVIL OTHER_COMMERCIAL
    STATE_DOMAIN
    TRUST
    OTHER
  ].freeze

  # Human-readable labels for legal entity types
  LEGAL_ENTITY_TYPE_LABELS = {
    "SCI" => "Property Investment Partnership (SCI)",
    "SARL" => "Limited Liability Company (SARL)",
    "SAM" => "Joint Stock Company (SAM)",
    "SNC" => "Commercial Partnership (SNC)",
    "SA" => "Société Anonyme (SA)",
    "SCS" => "Limited Partnership (SCS)",
    "SCA" => "Limited Partnership with Shares (SCA)",
    "SCP" => "Special Civil-law Partnership (SCP)",
    "GIE" => "Economic Interest Group (GIE)",
    "EI" => "Sole Person (EI)",
    "FOUNDATION" => "Monegasque Foundation",
    "ASSOCIATION" => "Monegasque Association",
    "OTHER_CIVIL" => "Other Civil Companies",
    "OTHER_COMMERCIAL" => "Other Commercial Companies",
    "STATE_DOMAIN" => "Private Domain of the Monegasque State",
    "TRUST" => "Trust",
    "OTHER" => "Other Legal Arrangements"
  }.freeze

  # Standard commercial/civil forms have dedicated AMSF sections.
  # Trusts have their own dedicated section (a1801-a1809).
  # Everything else is "other legal constructions" for field a11006.
  AMSF_STANDARD_LEGAL_FORMS = %w[SCI SARL SAM SNC SA SCS SCA SCP EI TRUST].freeze

  # Purchase purpose
  PURCHASE_PURPOSES = %w[RESIDENCE INVESTMENT].freeze

  # Client residence status
  RESIDENCE_STATUSES = %w[RESIDENT NON_RESIDENT].freeze

  # Transaction payment direction (who handles the funds)
  # BY_CLIENT: Client pays directly (e.g., buyer wires funds to seller's account)
  # WITH_CLIENT: Funds flow through the agency (e.g., client pays agency, agency disburses)
  TRANSACTION_DIRECTIONS = %w[BY_CLIENT WITH_CLIENT].freeze

  # Suspicious Transaction Report reasons
  STR_REASONS = %w[CASH PEP UNUSUAL_PATTERN OTHER].freeze

  # Client rejection reasons
  REJECTION_REASONS = %w[AML_CFT OTHER].freeze

  # Setting categories for organization configuration
  SETTING_CATEGORIES = %w[entity_info kyc compliance training].freeze

  # Setting value types for type casting
  SETTING_TYPES = %w[boolean integer decimal string date enum].freeze

  # AMSF country name enumeration — maps ISO alpha-2 codes to full XBRL labels
  # Format: "Name (XX, XXX, NNN)" where XX=ISO alpha-2, XXX=ISO alpha-3, NNN=ISO numeric
  # Source: strix_Real_Estate_AML_CFT_survey_2025.xsd enumeration for a3305
  AMSF_COUNTRIES = {
    "XK" => "Kosovo",
    "AF" => "Afghanistan (AF, AFG, 004)",
    "AX" => "Iles Aland (AX, ALA, 248)",
    "AL" => "Albanie (AL, ALB, 008)",
    "DZ" => "Algerie (DZ, DZA, 012)",
    "AS" => "Samoa Américaines (AS, ASM, 016)",
    "AD" => "Andorre (AD, AND, 020)",
    "AO" => "Angola (AO, AGO, 024)",
    "AI" => "Anguilla (AI, AIA, 660)",
    "AQ" => "Antarctique (AQ, ATA, 010)",
    "AG" => "Antigua-et-Barbuda (AG, ATG, 028)",
    "AR" => "Argentine (AR, ARG, 032)",
    "AM" => "Armenie (AM, ARM, 051)",
    "AW" => "Aruba (AW, ABW, 533)",
    "AU" => "Australie (AU, AUS, 036)",
    "AT" => "Autriche (AT, AUT, 040)",
    "AZ" => "Azerbaïdjan (AZ, AZE, 031)",
    "BS" => "Bahamas (BS, BHS, 044)",
    "BH" => "Bahreïn (BH, BHR, 048)",
    "BD" => "Bangladesh (BD, BGD, 050)",
    "BB" => "Barbade (BB, BRB, 052)",
    "BY" => "Biélorussie (BY, BLR, 112)",
    "BE" => "Belgique (BE, BEL, 056)",
    "BZ" => "Belize (BZ, BLZ, 084)",
    "BJ" => "Bénin (BJ, BEN, 204)",
    "BM" => "Bermudes (BM, BMU, 060)",
    "BT" => "Bhoutan (BT, BTN, 064)",
    "BO" => "Bolivie (BO, BOL, 068)",
    "BQ" => "Bonaire, Saint-Eustache et Saba (BQ, BES, 535)",
    "BA" => "Bosnie Herzégovine (BA, BIH, 070)",
    "BW" => "Botswana (BW, BWA, 072)",
    "BV" => "Ile Bouvet (BV, BVT, 074)",
    "BR" => "Brésil (BR, BRA, 076)",
    "IO" => "Territoire Britanique de l'océan Indien (IO, IOT, 086)",
    "VG" => "Iles Vierges Britanniques (VG, VGB, 092)",
    "BN" => "Brunei (BN, BRN, 096)",
    "BG" => "Bulgarie (BG, BGR, 100)",
    "BF" => "Burkina Faso (BF, BFA, 854)",
    "BI" => "Burundi (BI, BDI, 108)",
    "CV" => "Cap-Vert (CV, CPV, 132)",
    "KH" => "Cambodge (KH, KHM, 116)",
    "CM" => "Cameroun (CM, CMR, 120)",
    "CA" => "Canada (CA, CAN, 124)",
    "KY" => "Iles Caïmans (KY, CYM, 136)",
    "CF" => "République Centrafricaine (CF, CAF, 140)",
    "TD" => "Tchad (TD, TCD, 148)",
    "CL" => "Chili (CL, CHL, 152)",
    "CN" => "Chine (CN, CHN, 156)",
    "HK" => "Hong Kong (HK, HKG, 344)",
    "MO" => "Macao (MO, MAC, 446)",
    "CX" => "Ile Christmas (CX, CXR, 162)",
    "CC" => "Iles Cocos (CC, CCK, 166)",
    "CO" => "Colombie (CO, COL, 170)",
    "KM" => "Comores (KM, COM, 174)",
    "CG" => "Congo (CG, COG, 178)",
    "CK" => "Iles Cook (CK, COK, 184)",
    "CR" => "Costa Rica (CR, CRI, 188)",
    "CI" => "Côte d'Ivoire (CI, CIV, 384)",
    "HR" => "Croatie (HR, HRV, 191)",
    "CU" => "Cuba (CU, CUB, 192)",
    "CW" => "Curaçao (CW, CUW, 531)",
    "CY" => "Chypre (CY, CYP, 196)",
    "CZ" => "Tchéquie (CZ, CZE, 203)",
    "KP" => "République Populaire Démocratique de Corée (KP, PRK, 408)",
    "CD" => "République Démocratique du Congo (CD, COD, 180)",
    "DK" => "Danemark (DK, DNK, 208)",
    "DJ" => "Djibouti (DJ, DJI, 262)",
    "DM" => "Dominique (DM, DMA, 212)",
    "DO" => "République Dominicaine (DO, DOM, 214)",
    "EC" => "Equateur (EC, ECU, 218)",
    "EG" => "Egypte (EG, EGY, 818)",
    "SV" => "El Salvador (SV, SLV, 222)",
    "GQ" => "Guinée Equatoriale (GQ, GNQ, 226)",
    "ER" => "Erythrée (ER, ERI, 232)",
    "EE" => "Estonie (EE, EST, 233)",
    "SZ" => "Eswatini (SZ, SWZ, 748)",
    "ET" => "Ethiopie (ET, ETH, 231)",
    "FK" => "Iles Falkland (FK, FLK, 238)",
    "FO" => "Iles Féroé (FO, FRO, 234)",
    "FJ" => "Fidji (FJ, FJI, 242)",
    "FI" => "Finlande (FI, FIN, 246)",
    "FR" => "France (FR, FRA, 250)",
    "GF" => "Guyane Française (GF, GUF, 254)",
    "PF" => "Polynésie Française (PF, PYF, 258)",
    "TF" => "Terres Australes et Antarctiques Françaises (TF, ATF, 260)",
    "GA" => "Gabon (GA, GAB, 266)",
    "GM" => "Gambie (GM, GMB, 270)",
    "GE" => "Géorgie (GE, GEO, 268)",
    "DE" => "Allemagne (DE, DEU, 276)",
    "GH" => "Ghana (GH, GHA, 288)",
    "GI" => "Gibraltar (GI, GIB, 292)",
    "GR" => "Grèce (GR, GRC, 300)",
    "GL" => "Groenland (GL, GRL, 304)",
    "GD" => "Grenade (GD, GRD, 308)",
    "GP" => "Guadeloupe (GP, GLP, 312)",
    "GU" => "Guam (GU, GUM, 316)",
    "GT" => "Guatemala (GT, GTM, 320)",
    "GG" => "Guernesey (GG, GGY, 831)",
    "GN" => "Guinée (GN, GIN, 324)",
    "GW" => "Guinée Bissau (GW, GNB, 624)",
    "GY" => "Guyane (GY, GUY, 328)",
    "HT" => "Haïti (HT, HTI, 332)",
    "HM" => "Iles Heard-et-MacDonald (HM, HMD, 334)",
    "VA" => "Saint-Siège (VA, VAT, 336)",
    "HN" => "Honduras (HN, HND, 340)",
    "HU" => "Hongrie (HU, HUN, 348)",
    "IS" => "Islande (IS, ISL, 352)",
    "IN" => "Inde (IN, IND, 356)",
    "ID" => "Indonésie (ID, IDN, 360)",
    "IR" => "Iran (IR, IRN, 364)",
    "IQ" => "Irak (IQ, IRQ, 368)",
    "IE" => "Irlande (IE, IRL, 372)",
    "IM" => "Ile de Man (IM, IMN, 833)",
    "IL" => "Israël (IL, ISR, 376)",
    "IT" => "Italie (IT, ITA, 380)",
    "JM" => "Jamaïque (JM, JAM, 388)",
    "JP" => "Japon (JP, JPN, 392)",
    "JE" => "Jersey (JE, JEY, 832)",
    "JO" => "Jordanie (JO, JOR, 400)",
    "KZ" => "Kazakhstan (KZ, KAZ, 398)",
    "KE" => "Kenya (KE, KEN, 404)",
    "KI" => "Kiribati (KI, KIR, 296)",
    "KW" => "Koweit (KW, KWT, 414)",
    "KG" => "Kirghizistan (KG, KGZ, 417)",
    "LA" => "République Démocratique Populaire Lao (LA, LAO, 418)",
    "LV" => "Lettonie (LV, LVA, 428)",
    "LB" => "Liban (LB, LBN, 422)",
    "LS" => "Lesotho (LS, LSO, 426)",
    "LR" => "Liberia (LR, LBR, 430)",
    "LY" => "Libye (LY, LBY, 434)",
    "LI" => "Liechtenstein (LI, LIE, 438)",
    "LT" => "Lithuanie (LT, LTU, 440)",
    "LU" => "Luxembourg (LU, LUX, 442)",
    "MG" => "Madagascar (MG, MDG, 450)",
    "MW" => "Malawi (MW, MWI, 454)",
    "MY" => "Malaisie (MY, MYS, 458)",
    "MV" => "Maldives (MV, MDV, 462)",
    "ML" => "Mali (ML, MLI, 466)",
    "MT" => "Malte (MT, MLT, 470)",
    "MH" => "Iles Marshall (MH, MHL, 584)",
    "MQ" => "Martinique (MQ, MTQ, 474)",
    "MR" => "Mauritanie (MR, MRT, 478)",
    "MU" => "Ile Maurice (MU, MUS, 480)",
    "YT" => "Mayotte (YT, MYT, 175)",
    "MX" => "Mexique (MX, MEX, 484)",
    "FM" => "Etats Fédérs de Micronésie (FM, FSM, 583)",
    "MC" => "Monaco (MC, MCO, 492)",
    "MN" => "Mongolie (MN, MNG, 496)",
    "ME" => "Montenegro (ME, MNE, 499)",
    "MS" => "Montserrat (MS, MSR, 500)",
    "MA" => "Maroc (MA, MAR, 504)",
    "MZ" => "Mozambique (MZ, MOZ, 508)",
    "MM" => "Myanmar (MM, MMR, 104)",
    "NA" => "Namibie (NA, NAM, 516)",
    "NR" => "Nauru (NR, NRU, 520)",
    "NP" => "Nepal (NP, NPL, 524)",
    "NL" => "Pays-Bas (NL, NLD, 528)",
    "NC" => "Nouvelle Calédonie (NC, NCL, 540)",
    "NZ" => "Nouvelle Zélande (NZ, NZL, 554)",
    "NI" => "Nicaragua (NI, NIC, 558)",
    "NE" => "Niger (NE, NER, 562)",
    "NG" => "Nigeria (NG, NGA, 566)",
    "NU" => "Niue (NU, NIU, 570)",
    "NF" => "Ile de Norfolk (NF, NFK, 574)",
    "MK" => "Macédoine du Nord (MK, MKD, 807)",
    "MP" => "Iles Mariannes du Nord (MP, MNP, 580)",
    "NO" => "Norvège (NO, NOR, 578)",
    "OM" => "Oman (OM, OMN, 512)",
    "PK" => "Pakistan (PK, PAK, 586)",
    "PW" => "Palau (PW, PLW, 585)",
    "PA" => "Panama (PA, PAN, 591)",
    "PG" => "Papouasie Nouvelle Guinée (PG, PNG, 598)",
    "PY" => "Paraguay (PY, PRY, 600)",
    "PE" => "Pérou (PE, PER, 604)",
    "PH" => "Philippines (PH, PHL, 608)",
    "PN" => "Iles Pitcairn (PN, PCN, 612)",
    "PL" => "Pologne (PL, POL, 616)",
    "PT" => "Portugal (PT, PRT, 620)",
    "PR" => "Porto Rico (PR, PRI, 630)",
    "QA" => "Qatar (QA, QAT, 634)",
    "KR" => "République de Corée (KR, KOR, 410)",
    "MD" => "République de Moldavie (MD, MDA, 498)",
    "RE" => "Réunion (RE, REU, 638)",
    "RO" => "Roumanie (RO, ROU, 642)",
    "RU" => "Fédération de Russie (RU, RUS, 643)",
    "RW" => "Rwanda (RW, RWA, 646)",
    "BL" => "Saint-Barthélemy (BL, BLM, 652)",
    "SH" => "Sainte-Hélène, Ascension et Tristan da Cunha (SH, SHN, 654)",
    "KN" => "Saint-Christophe-et-Niévès (KN, KNA, 659)",
    "LC" => "Sainte-Lucie (LC, LCA, 662)",
    "MF" => "Saint-Martin (MF, MAF, 663)",
    "PM" => "Saint-Pierre-et-Miquelon (PM, SPM, 666)",
    "VC" => "Saint-Vincent et les Grenadines (VC, VCT, 670)",
    "WS" => "Samoa (WS, WSM, 882)",
    "SM" => "Saint Marin (SM, SMR, 674)",
    "ST" => "Sao Tomé-et-Principe (ST, STP, 678)",
    "SA" => "Arabie Saoudite (SA, SAU, 682)",
    "SN" => "Sénégal (SN, SEN, 686)",
    "RS" => "Serbie (RS, SRB, 688)",
    "SC" => "Seychelles (SC, SYC, 690)",
    "SL" => "Sierra Leone (SL, SLE, 694)",
    "SG" => "Singapour (SG, SGP, 702)",
    "SX" => "Saint-Martin (Pays-Bas) (SX, SXM, 534)",
    "SK" => "Slovakie (SK, SVK, 703)",
    "SI" => "Slovenie (SI, SVN, 705)",
    "SB" => "Iles Salomon (SB, SLB, 090)",
    "SO" => "Somalie (SO, SOM, 706)",
    "ZA" => "Afrique du Sud (ZA, ZAF, 710)",
    "GS" => "Géorgie du Sud-et-les-iles Sandwich du Sud (GS, SGS, 239)",
    "SS" => "Soudan du Sud (SS, SSD, 728)",
    "ES" => "Espagne (ES, ESP, 724)",
    "LK" => "Sri Lanka (LK, LKA, 144)",
    "PS" => "Etat de Palestine (PS, PSE, 275)",
    "SD" => "Soudan (SD, SDN, 729)",
    "SR" => "Suriname (SR, SUR, 740)",
    "SJ" => "Svalbard et Jan Mayen (SJ, SJM, 744)",
    "SE" => "Suède (SE, SWE, 752)",
    "CH" => "Suisse (CH, CHE, 756)",
    "SY" => "République Arabe Syrienne (SY, SYR, 760)",
    "TW" => "Taïwan (TW, TWN, 158)",
    "TJ" => "Tadjikistan (TJ, TJK, 762)",
    "TH" => "Thaïlande (TH, THA, 764)",
    "TL" => "Timor (TL, TLS, 626)",
    "TG" => "Togo (TG, TGO, 768)",
    "TK" => "Tokelau (TK, TKL, 772)",
    "TO" => "Tonga (TO, TON, 776)",
    "TT" => "Trinité-et-Tobago (TT, TTO, 780)",
    "TN" => "Tunisie (TN, TUN, 788)",
    "TR" => "Turquie (TR, TUR, 792)",
    "TM" => "Turkménistan (TM, TKM, 795)",
    "TC" => "Iles Turques-et-Caiques (TC, TCA, 796)",
    "TV" => "Tuvalu (TV, TUV, 798)",
    "UG" => "Ouganda (UG, UGA, 800)",
    "UA" => "Ukraine (UA, UKR, 804)",
    "AE" => "Emirats Arabes Unis (AE, ARE, 784)",
    "GB" => "Royaume-Uni de Grande-Bretagne et d'Irlande du Nord (GB, GBR, 826)",
    "TZ" => "République unie de Tanzanie (TZ, TZA, 834)",
    "UM" => "Iles mineures Eloignées des Etats-Unis (UM, UMI, 581)",
    "US" => "Etats-Unis d'Amerique (US, USA, 840)",
    "VI" => "Iles Vierges des Etats-Unis (VI, VIR, 850)",
    "UY" => "Uruguay (UY, URY, 858)",
    "UZ" => "Ouzbékistan (UZ, UZB, 860)",
    "VU" => "Vanuatu (VU, VUT, 548)",
    "VE" => "Vénézuela (VE, VEN, 862)",
    "VN" => "Vietnam (VN, VNM, 704)",
    "WF" => "Iles Wallis-et-Futuna (WF, WLF, 876)",
    "EH" => "Sahara Occidental (EH, ESH, 732)",
    "YE" => "Yémen (YE, YEM, 887)",
    "ZM" => "Zambie (ZM, ZMB, 894)",
    "ZW" => "Zimbabwe (ZW, ZWE, 716)"
  }.freeze

  # Submission workflow statuses (simplified: draft -> completed)
  SUBMISSION_STATUSES = %w[draft in_review completed].freeze

  # Source of submission values
  SUBMISSION_VALUE_SOURCES = %w[calculated from_settings manual].freeze

  # Due Diligence Levels (FR-001)
  DUE_DILIGENCE_LEVELS = %w[STANDARD SIMPLIFIED REINFORCED].freeze

  # Relationship End Reasons
  RELATIONSHIP_END_REASONS = %w[
    CLIENT_REQUEST
    AML_CONCERN
    INACTIVITY
    BUSINESS_DECISION
    OTHER
  ].freeze

  # Professional Categories (FR-002)
  PROFESSIONAL_CATEGORIES = %w[
    LEGAL
    ACCOUNTANT
    NOTARY
    REAL_ESTATE
    FINANCIAL
    OTHER
    NONE
  ].freeze

  # Property Types (FR-008)
  PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL LAND MIXED].freeze

  # Tenant Types (FR-006)
  TENANT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY].freeze

  # Training Types (FR-007)
  TRAINING_TYPES = %w[INITIAL REFRESHER SPECIALIZED].freeze

  # Training Topics
  TRAINING_TOPICS = %w[
    AML_BASICS
    PEP_SCREENING
    STR_FILING
    RISK_ASSESSMENT
    SANCTIONS
    KYC_PROCEDURES
    OTHER
  ].freeze

  # Training Providers
  TRAINING_PROVIDERS = %w[INTERNAL EXTERNAL AMSF ONLINE].freeze

  # Managed Property Types
  MANAGED_PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL].freeze

  # Third-Party CDD Types (local vs foreign providers)
  THIRD_PARTY_CDD_TYPES = %w[LOCAL FOREIGN].freeze

  # Year-over-year comparison threshold (FR-019)
  # Changes greater than this percentage require additional review
  SIGNIFICANCE_THRESHOLD = 25.0

  # Valid submission year range (AMSF established 2009, reasonable future)
  # Note: MIN set to 2009 when AMSF was established in Monaco
  MIN_SUBMISSION_YEAR = 2009
  MAX_SUBMISSION_YEAR = 2099

  # Note: Audit log action types are defined as a Rails enum in AuditLog model.
  # Use AuditLog.actions.keys to get the list of valid actions.
end
