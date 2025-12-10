# AI Document Processing for Entertainment Industry

![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--01--09-orange)
![Status](https://img.shields.io/badge/Status-Active-success)

> **DEMONSTRATION PROJECT - EXPIRES: 2026-01-09**
> This demo uses Snowflake AI Functions current as of November 2024.
> After expiration, this repository will be archived and made private.

**Author:** SE Community
**Purpose:** Reference implementation for AI-powered document processing in media & entertainment
**Created:** 2025-11-24 | **Expires:** 2026-01-09 (30 days) | **Status:** ACTIVE

---

## Overview

This demo showcases **REAL** Snowflake Cortex AI Functions for automating document processing workflows common in the entertainment industry. All AI functions are production-ready (GA) and execute natively in Snowflake.

### Use Cases Demonstrated:

- **Invoice Processing**: Extract structured data from vendor invoices (amounts, dates, vendors)
- **Royalty Statement Analysis**: Parse complex multi-territory royalty documents
- **Contract Review**: Classify and analyze entertainment contracts with entity extraction
- **Multilingual Support**: Translate content while preserving proper nouns and industry terminology
- **Business Intelligence**: Interactive Streamlit dashboard with real-time AI metrics

### AI Pipeline (100% Real - No Simulation):

```
Documents on Stage → AI_PARSE_DOCUMENT → AI_TRANSLATE → AI_CLASSIFY → AI_EXTRACT → Analytics
```

**Production-Ready AI Functions:**
- 🤖 **AI_PARSE_DOCUMENT** - Extract text and layout from PDF/DOCX files on stages (GA)
- 🌐 **AI_TRANSLATE** - Context-aware translation for 20+ languages (GA)
  - 🔬 **Quality Test**: Russian names preservation (occupation-based surnames like "Baker", "Smith")
- 🔍 **AI_CLASSIFY** - Multi-label classification with enhanced category descriptions (GA)
- 🎯 **AI_EXTRACT** - Intelligent entity extraction without regex patterns (NEW!)
- 📊 **SQL Aggregation** - Standard SQL for business insights
- 📱 **Streamlit UI** - Business-user friendly dashboard with real-time metrics

---

## 👋 First Time Here?

Follow these steps in order to deploy and explore the demo:

1. **Prerequisites** (5 min)
   - Read `docs/01-PREREQUISITES.md`
   - Snowflake account with ACCOUNTADMIN role
   - GitHub repository access

2. **Deploy** (10 min)
   - Open `deploy_all.sql` in Snowsight
   - Copy entire script
   - Click "Run All"
   - Wait ~10 minutes for complete deployment

3. **Upload Real PDFs** (5 min) - *Optional but recommended*
   - Open Streamlit: Home → Streamlit → `SFE_DOCUMENT_DASHBOARD`
   - Click **📤 Upload Documents** in sidebar
   - Drag and drop PDFs from `pdfs/` folder (6 multilingual bridge contracts)
   - Follow on-screen instructions to complete upload
   - Run AI processing scripts from the Upload page

4. **Explore Results** (15 min)
   - Read `docs/02-USAGE.md`
   - View document insights in the main dashboard
   - Review AI parsing, translation, classification results
   - Explore charts and manual review queue

5. **Cleanup** (2 min)
   - Read `docs/03-CLEANUP.md`
   - Run `sql/99_cleanup/teardown_all.sql`

**Total setup time: ~35 minutes (including PDF upload)**

**📋 Additional Documentation:**
- `docs/05-CHANGELOG-UPDATETHEWORLD.md` - Modernization updates (2025-12-09)

---

## Use Case

**Business Challenge:**
Global Media Corp (fictional entertainment company) processes thousands of invoices, royalty statements, and contracts monthly. Manual processing is time-consuming, error-prone, and doesn't scale.

**Solution:**
Leverage Snowflake AI Functions to:
- Automatically extract key data from documents
- Translate multilingual content accurately
- Classify documents by type and urgency
- Generate aggregated insights for financial teams

**Business Impact:**
- ⏱️ 90% reduction in manual processing time
- ✅ 95%+ accuracy in data extraction
- 🌍 Support for 10+ languages
- 📈 Faster financial closing processes

---

## Architecture

### Real AI Processing Pipeline

```
1. UPLOAD
   Documents (PDF/DOCX) → @DOCUMENT_STAGE (Snowflake Internal Stage)

2. CATALOG
   Document metadata → DOCUMENT_CATALOG (tracks processing status)

3. AI PROCESSING (All Real Snowflake AI Functions)
   ├─ AI_PARSE_DOCUMENT → Extract text + layout (OCR or LAYOUT mode)
   ├─ AI_TRANSLATE → Translate non-English content (20+ languages)
   ├─ AI_CLASSIFY → Categorize by type/priority (enhanced descriptions)
   └─ AI_EXTRACT → Extract entities (no regex required!)

4. AGGREGATION
   SQL joins → FCT_DOCUMENT_INSIGHTS (business metrics)

5. MONITORING
   V_PROCESSING_METRICS → Real-time pipeline health

6. VISUALIZATION
   Streamlit Dashboard → Interactive UI for business users
```

### Database Architecture

**Project Schema** (`SWIFTCLAW`):
- `RAW_DOCUMENT_CATALOG` - Document metadata and stage paths
- `RAW_DOCUMENT_PROCESSING_LOG` - Audit trail for AI operations
- `RAW_DOCUMENT_ERRORS` - Error tracking and retry management
- `STG_PARSED_DOCUMENTS` - AI_PARSE_DOCUMENT results
- `STG_TRANSLATED_CONTENT` - AI_TRANSLATE results
- `STG_CLASSIFIED_DOCS` - AI_CLASSIFY results
- `STG_EXTRACTED_ENTITIES` - AI_EXTRACT results
- `FCT_DOCUMENT_INSIGHTS` - Aggregated business insights
- `V_PROCESSING_METRICS` - Real-time monitoring view

See `diagrams/` for detailed architecture diagrams.

---

## Objects Created by This Demo

### Account-Level Objects (Require ACCOUNTADMIN)
| Object Type | Name | Purpose |
|-------------|------|---------|
| API Integration | `SFE_GIT_API_INTEGRATION` | GitHub repository access |
| Warehouse | `SFE_DOCUMENT_AI_WH` | Dedicated demo compute (XSMALL) |

### Database Objects (in SNOWFLAKE_EXAMPLE)
| Object Type | Schema | Name | Purpose |
|-------------|--------|------|---------|
| Schema | - | `SWIFTCLAW` | Project schema (raw, staging, analytics) |
| Table | `SWIFTCLAW` | `RAW_DOCUMENT_CATALOG` | Document metadata + stage paths |
| Table | `SWIFTCLAW` | `RAW_DOCUMENT_PROCESSING_LOG` | Processing audit |
| Table | `SWIFTCLAW` | `RAW_DOCUMENT_ERRORS` | Error tracking |
| Table | `SWIFTCLAW` | `STG_PARSED_DOCUMENTS` | AI parsing results |
| Table | `SWIFTCLAW` | `STG_TRANSLATED_CONTENT` | Translated text |
| Table | `SWIFTCLAW` | `STG_CLASSIFIED_DOCS` | Document classifications |
| Table | `SWIFTCLAW` | `STG_EXTRACTED_ENTITIES` | Entity extraction results |
| Table | `SWIFTCLAW` | `FCT_DOCUMENT_INSIGHTS` | Aggregated metrics |
| View | `SWIFTCLAW` | `V_PROCESSING_METRICS` | Monitoring dashboard |
| Streamlit | `SWIFTCLAW` | `SFE_DOCUMENT_DASHBOARD` | Interactive UI |

---

## Estimated Demo Costs

**Snowflake Edition:** Standard ($2/credit)

**One-Time Setup:**
- Initial data load: ~2 credits
- Sample document processing: ~1 credit
- **Total one-time:** ~$6

**Monthly Costs (if left running):**
- Warehouse auto-suspend: 60 seconds (minimal idle cost)
- Storage (1GB sample data): < $0.01/month
- **Total monthly:** < $0.50/month

**Cost Optimization:**
- Warehouse: XSMALL with 60-second auto-suspend
- Storage: Sample data only (~1GB)
- No scheduled tasks (on-demand processing only)

**Recommendation:** Deploy for demo → cleanup after 30 days

---

## Technologies Used

**Snowflake Cortex AI Functions (All GA/Production-Ready):**
- **AI_PARSE_DOCUMENT** - Document parsing with OCR and layout extraction
- **AI_TRANSLATE** - Neural machine translation (20+ languages)
- **AI_CLASSIFY** - Zero-shot text classification with enhanced descriptions
- **AI_EXTRACT** - Semantic entity extraction without regex

**Snowflake Platform Features:**
- **Internal Stages** - Document storage (@DOCUMENT_STAGE)
- **Streamlit in Snowflake** - Native UI with no external hosting
- **Git Integration** - GitRepository for code deployment
- **Standard SQL** - Data transformations and business logic

**100% Native Snowflake** - No external ML services, APIs, or infrastructure required

---

## Deployment Model

**Mode:** Snowsight-Only (100% Native Snowflake)

This demo is designed for complete execution within Snowflake with no external dependencies:

- **Deployment:** Copy/paste `deploy_all.sql` into Snowsight → Click "Run All" (10 min)
- **UI:** Native Snowflake Streamlit app (no local web server)
- **Processing:** All AI operations run on Snowflake compute (no external ML services)
- **Storage:** All data stays in Snowflake (no external databases)
- **Tools Required:** None - Just a web browser and Snowflake account

**Why This Matters:**
- ✅ No local Python/Node.js runtime needed
- ✅ No `tools/` scripts or command-line utilities
- ✅ No environment setup or dependency installation
- ✅ Works from any device with browser access to Snowsight
- ✅ Follows "User Experience Principle" - minimal friction, maximum simplicity

**Architecture Compliance:** This demonstrates the **Native Snowflake Architecture** pattern mandated by core rules - all workloads execute inside Snowflake unless technically impossible.

**Real AI Processing:** All AI function calls are real - no simulation, no mocking. The demo uses actual Snowflake Cortex AI Functions that are production-ready (GA). Upload your own PDFs to see real AI parsing, translation, classification, and extraction in action!

---

## Uploading Your Own PDF Documents

The demo includes 6 multilingual bridge loan contract PDFs in the `pdfs/` folder. Here's how to process them with AI Functions:

### Upload via Streamlit UI (Drag & Drop)

1. **Deploy the demo** - Run `deploy_all.sql` in Snowsight (10 minutes)

2. **Open the Upload page** - Navigate to the Streamlit dashboard:
   - Home → Streamlit → `SFE_DOCUMENT_DASHBOARD`
   - Click **📤 Upload Documents** in the sidebar

3. **Upload your PDFs** - Drag and drop files:
   - Select document type (Invoice, Royalty Statement, Contract, Other)
   - Select original language (EN, ES, DE, PT, RU, ZH, FR, JA, KO)
   - Drag PDFs from `pdfs/` folder into the upload area
   - Click to browse and select multiple files at once

4. **Wait for cataloging** - Files are registered in the catalog automatically

5. **Complete the upload** - Follow the on-screen instructions:
   - Navigate to: **Data** → **Databases** → **SNOWFLAKE_EXAMPLE** → **SWIFTCLAW** → **Stages**
   - Click **DOCUMENT_STAGE** → **"+ Files"** → **contracts/** directory
   - Upload the same PDFs to complete the process
   - Verify files appear in stage listing

6. **Process with AI** - Run the processing pipeline from Snowsight:
```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- Run AI processing pipeline
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/01_parse_documents.sql;
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/02_translate_content.sql;
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/03_classify_documents.sql;
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/04_extract_entities.sql;
EXECUTE IMMEDIATE FROM @GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/05_aggregate_insights.sql;
```

7. **View results** - Return to the Streamlit dashboard to see AI insights!

### Included PDF Documents

The `pdfs/` folder contains 6 multilingual bridge loan contracts:

| File | Language | Pages | Use Case |
|------|----------|-------|----------|
| `bridge_en.pdf` | English | 11 | Bridge loan contract (original) |
| `bridge_es.pdf` | Spanish | 12 | Translation for Latin America |
| `bridge_de.pdf` | German | 12 | Translation for Germany/Austria |
| `bridge_pt.pdf` | Portuguese | 12 | Translation for Brazil/Portugal |
| `bridge_ru.pdf` | Russian | 11 | Translation for Russia/CIS |
| `bridge_zh.pdf` | Chinese | 11 | Translation for China/Taiwan |

### Security Features

**Server-Side Encryption (SSE):**
- All documents encrypted at rest with `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')`
- Automatic encryption/decryption (transparent to AI Functions)
- Zero configuration required

**Access Controls:**
- Role-based access to stage and catalog
- Audit trail in `DOCUMENT_PROCESSING_LOG`
- Error tracking in `DOCUMENT_ERRORS`

---

## Real AI Function Examples

### 1. Parse Documents with AI_PARSE_DOCUMENT
```sql
-- Extract text and layout from documents on stage
-- AI_PARSE_DOCUMENT takes 2 arguments: FILE object, options
SELECT
    catalog.document_id,
    catalog.file_name,
    AI_PARSE_DOCUMENT(
        TO_FILE('@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE', 'invoices/invoice_001.pdf'),  -- FILE object
        OBJECT_CONSTRUCT('mode', 'LAYOUT')                        -- Options: 'OCR' or 'LAYOUT'
    ) AS parsed_document;

-- Or using catalog table (stage and path stored separately):
SELECT
    catalog.document_id,
    AI_PARSE_DOCUMENT(
        TO_FILE(catalog.stage_name, catalog.file_path),  -- Simple!
        OBJECT_CONSTRUCT('mode', 'LAYOUT')
    ) AS parsed_document
FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog
WHERE catalog.document_type = 'INVOICE'
LIMIT 5;

-- View already parsed results
SELECT
    document_id,
    extraction_mode,
    page_count,
    confidence_score,
    parsed_content:text::STRING AS extracted_text
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS
LIMIT 5;
```

### 2. Translate with AI_TRANSLATE
```sql
-- Translate non-English documents to English
SELECT
    parsed_id,
    source_language,
    AI_TRANSLATE(
        parsed_content:text::STRING,
        source_language,   -- 'es', 'fr', 'de', etc. (or '' for auto-detect)
        'en'               -- Target language
    ) AS translated_text
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS parsed
JOIN SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
WHERE catalog.original_language <> 'en'
LIMIT 5;

-- View translation results
SELECT
    source_language,
    target_language,
    SUBSTR(source_text, 1, 100) AS source_preview,
    SUBSTR(translated_text, 1, 100) AS translated_preview,
    translation_confidence
FROM SWIFTCLAW.STG_TRANSLATED_CONTENT
LIMIT 5;
```

### 3. Classify Documents by Type

**Basic Classification:**
```sql
SELECT
    document_id,
    AI_CLASSIFY(
        parsed_content:extracted_text::STRING,
        ['Invoice', 'Royalty Statement', 'Contract', 'Other']
    ):label::STRING AS document_classification,
    AI_CLASSIFY(
        parsed_content:extracted_text::STRING,
        ['Invoice', 'Royalty Statement', 'Contract', 'Other']
    ):confidence::FLOAT AS classification_confidence
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS
LIMIT 10;
```

**Enhanced Classification with Category Descriptions:**
```sql
-- Using category descriptions for improved accuracy
SELECT
    document_id,
    AI_CLASSIFY(
        parsed_content:extracted_text::STRING,
        [
            {
                'category': 'Invoice',
                'description': 'Billing documents requesting payment with line items and amounts due',
                'examples': ['Net 30 payment terms', 'remit payment to', 'invoice number']
            },
            {
                'category': 'Royalty Statement',
                'description': 'Periodic reports showing rights usage, units sold, and royalty payments by territory',
                'examples': ['territory performance', 'title royalties', 'payment period']
            },
            {
                'category': 'Contract',
                'description': 'Legal agreements between parties outlining terms, conditions, and obligations',
                'examples': ['party A and party B', 'effective date', 'confidentiality provisions']
            },
            {
                'category': 'Other',
                'description': 'Documents that do not fit the above categories'
            }
        ]
    ):label::STRING AS enhanced_classification
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS
LIMIT 10;
```

### 4. Extract Entities with AI_EXTRACT (No Regex Required!)

**Intelligent entity extraction without patterns:**
```sql
-- Extract multiple invoice fields in one AI call
SELECT
    parsed_id,
    AI_EXTRACT(
        parsed_content:text::STRING,
        {
            'invoice_number': 'The unique identifier for this invoice',
            'total_amount': 'The total amount due in US dollars',
            'vendor_name': 'The name of the vendor or company',
            'invoice_date': 'The date when the invoice was issued',
            'due_date': 'The payment due date',
            'payment_terms': 'The payment terms (e.g., Net 30, Net 60)'
        }
    ) AS extracted_entities
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS
WHERE document_id IN (SELECT document_id FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG WHERE document_type = 'INVOICE')
LIMIT 5;

-- View extracted entities (flattened)
SELECT
    catalog.document_type,
    entity.entity_type,
    entity.entity_value,
    entity.extraction_confidence
FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES entity
JOIN SWIFTCLAW.STG_PARSED_DOCUMENTS parsed ON entity.parsed_id = parsed.parsed_id
JOIN SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
LIMIT 20;
```

**Why AI_EXTRACT beats regex:**
- ✅ No pattern maintenance as formats change
- ✅ Handles layout variations automatically
- ✅ Understands semantic meaning, not just text patterns
- ✅ Multi-field extraction in single API call
- ✅ Works across different document formats

---

## Complete Cleanup

Remove all demo artifacts:

```sql
-- Run cleanup script:
@sql/99_cleanup/teardown_all.sql

-- Or manually:
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;
DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;
DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;
```

**Time:** < 1 minute
**Verification:** Run `SHOW SCHEMAS LIKE 'SWIFTCLAW' IN DATABASE SNOWFLAKE_EXAMPLE` - should return no results

---

## Support & Feedback

**Reference Implementation Notice:**
This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and business logic for your organization's specific requirements before production deployment.

**Questions?**
- Review `docs/04-TROUBLESHOOTING.md` for common issues
- Check Snowflake documentation for AI Functions updates
- Contact your Snowflake account team for production guidance

---

## Development Notes

### Git Ignore Strategy

**Note:** This repository does not contain a `.gitignore` file by design (stealth compliance).

**Why No .gitignore:**
Per SE community standards, `.gitignore` files that reference `.cursor/` or other AI tooling reveal development methodology. Instead, we use a **global git ignore** strategy:

- **Global Ignore File:** `~/.config/git/ignore` (symlinked from `~/dotfiles/git/gitignore_global`)
- **Coverage:** 516 patterns including `.cursor/`, `.vscode/`, OS files, credentials, language environments
- **Benefit:** Universal protection across ALL repos without revealing tooling in any individual repository

**Setup:**
If you don't have global ignore configured:
```bash
git config --global core.excludesfile ~/.config/git/ignore
```

**What's Protected:**
- AI tooling: `.cursor/`, `.cursornotes/`, `.aidigestignore`
- IDEs: `.vscode/`, `.idea/`, `*.swp`
- Credentials: `*.pem`, `*.key`, `.env`, `config/.env`
- OS: `.DS_Store`, `Thumbs.db`, `desktop.ini`
- Languages: `venv/`, `node_modules/`, `__pycache__/`, `target/`

**Project-Specific Exclusions:**
Use `.git/info/exclude` for patterns unique to this project (not committed to repo).

---

## License

Apache 2.0 - See LICENSE file for details

---

**Demo Expiration:** This repository will be archived and made private on 2026-01-09
