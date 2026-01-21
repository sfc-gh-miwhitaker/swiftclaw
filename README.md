# AI Document Processing for Entertainment Industry

![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--02--08-orange)
![Status](https://img.shields.io/badge/Status-Active-success)

> **DEMONSTRATION PROJECT - EXPIRES: 2026-02-08**
> This demo uses Snowflake AI Functions current as of November 2024.
> After expiration, this repository will be archived and made private.

**Author:** SE Community
**Purpose:** Reference implementation for AI-powered document processing in media & entertainment
**Created:** 2025-11-24 | **Expires:** 2026-02-08 (30 days) | **Status:** ACTIVE

---

## Overview

This demo showcases **REAL** Snowflake Cortex AI Functions for automating document processing workflows common in the entertainment industry. All AI functions are production-ready (GA) and execute natively in Snowflake.

### Use Cases Demonstrated:

- **Invoice Processing**: Extract structured data from vendor invoices (amounts, dates, vendors)
- **Royalty Statement Analysis**: Parse complex multi-territory royalty documents
- **Contract Review**: Classify and analyze entertainment contracts with entity extraction
- **Multilingual Support**: Translate content while preserving proper nouns and industry terminology
- **Business Intelligence**: Interactive Streamlit dashboard with real-time AI metrics

### AI Pipeline (Dynamic Tables):

```
Documents on Stage -> AI_PARSE_DOCUMENT -> AI_TRANSLATE (non-EN) -> AI_COMPLETE -> Analytics
```

**Production-Ready AI Functions:**
- **AI_PARSE_DOCUMENT** - Extract text and layout from PDF/DOCX files on stages (GA)
- **AI_TRANSLATE** - Context-aware translation for 20+ languages (GA)
- **AI_COMPLETE** - Structured enrichment (classification + extraction) with JSON schema (GA)
- **SQL Aggregation** - Standard SQL for business insights
- **Streamlit UI** - Business-user friendly dashboard with real-time metrics

---

## First Time Here?

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

3. **Explore Results** (15 min)
   - Optional: Upload PDFs to the stage (see "Uploading Your Own PDF Documents")
   - Open Streamlit: Home -> Streamlit -> `SFE_DOCUMENT_DASHBOARD`
   - Read `docs/02-USAGE.md`
   - Review insights, charts, and manual review queue
   - Cleanup when finished: run `sql/99_cleanup/teardown_all.sql`

**Total setup time: ~30 minutes**

**Additional Documentation:**
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
- 90% reduction in manual processing time
- 95%+ accuracy in data extraction
- Support for 10+ languages
- Faster financial closing processes

---

## Architecture

### Real AI Processing Pipeline

```
1. UPLOAD
   Documents (PDF/DOCX) -> @DOCUMENT_STAGE (Snowflake internal stage)

2. CATALOG
   Stage directory -> RAW_DOCUMENT_CATALOG (view)

3. AI PROCESSING (Dynamic Tables)
   - STG_PARSED_DOCUMENTS (AI_PARSE_DOCUMENT)
   - STG_TRANSLATED_CONTENT (AI_TRANSLATE)
   - STG_ENRICHED_DOCUMENTS (AI_COMPLETE structured output)

4. INSIGHTS
   FCT_DOCUMENT_INSIGHTS (aggregated metrics)

5. MONITORING
   V_PROCESSING_METRICS (pipeline health)

6. VISUALIZATION
   Streamlit Dashboard (business UI)
```

### Database Architecture

**Project Schema** (`SWIFTCLAW`):
- `RAW_DOCUMENT_CATALOG` - Stage directory view with document metadata
- `STG_PARSED_DOCUMENTS` - AI_PARSE_DOCUMENT results (dynamic table)
- `STG_TRANSLATED_CONTENT` - AI_TRANSLATE results (dynamic table)
- `STG_ENRICHED_DOCUMENTS` - AI_COMPLETE structured enrichment (dynamic table)
- `FCT_DOCUMENT_INSIGHTS` - Aggregated business insights (dynamic table)
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
| Schema | - | `SWIFTCLAW` | Project schema |
| View | `SWIFTCLAW` | `RAW_DOCUMENT_CATALOG` | Stage directory metadata |
| Dynamic Table | `SWIFTCLAW` | `STG_PARSED_DOCUMENTS` | AI parsing results |
| Dynamic Table | `SWIFTCLAW` | `STG_TRANSLATED_CONTENT` | Translated text |
| Dynamic Table | `SWIFTCLAW` | `STG_ENRICHED_DOCUMENTS` | AI_COMPLETE enrichment |
| Dynamic Table | `SWIFTCLAW` | `FCT_DOCUMENT_INSIGHTS` | Aggregated metrics |
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

**Recommendation:** Deploy for demo, then clean up after 30 days

---

## Technologies Used

**Snowflake Cortex AI Functions (All GA/Production-Ready):**
- **AI_PARSE_DOCUMENT** - Document parsing with OCR and layout extraction
- **AI_TRANSLATE** - Neural machine translation (20+ languages)
- **AI_COMPLETE** - Structured enrichment with JSON schema

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

- **Deployment:** Copy/paste `deploy_all.sql` into Snowsight, then click "Run All" (10 min)
- **UI:** Native Snowflake Streamlit app (no local web server)
- **Processing:** All AI operations run on Snowflake compute (no external ML services)
- **Storage:** All data stays in Snowflake (no external databases)
- **Tools Required:** None - Just a web browser and Snowflake account

**Why This Matters:**
- No local Python/Node.js runtime needed
- No `tools/` scripts or command-line utilities
- No environment setup or dependency installation
- Works from any device with browser access to Snowsight
- Follows the "User Experience Principle" with minimal friction

**Architecture Compliance:** This demonstrates the **Native Snowflake Architecture** pattern mandated by core rules - all workloads execute inside Snowflake unless technically impossible.

**Real AI Processing:** All AI function calls are real with no simulation. The demo uses Snowflake Cortex AI Functions that are production-ready (GA). Upload your own PDFs to see parsing, translation, and structured enrichment in action.

---

## Uploading Your Own PDF Documents

Sample PDFs are copied to the internal stage during deployment. To add your own documents, upload PDF files directly to the stage. Dynamic Tables pick up new files automatically within the target lag window.

### Upload via Snowsight

1. Open **Data** -> **Databases** -> **SNOWFLAKE_EXAMPLE** -> **SWIFTCLAW** -> **Stages**
2. Select **DOCUMENT_STAGE**
3. Upload PDF files into one of these folders:
   - `invoices/`
   - `royalty/`
   - `contracts/`
   - `other/`

### Upload via SQL (PUT)

```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

PUT file://path/to/*.pdf @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE/invoices/ AUTO_COMPRESS=FALSE;
```

### File Naming Conventions

- Use folder names to set document type.
- Use a language code in the filename to set language (for example: `invoice_en_001.pdf`, `contract_es_003.pdf`).
- If no language code is found, English is assumed.

### Included PDF Documents

The `pdfs/` folder contains multilingual bridge loan contracts:

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
- Automatic encryption and decryption (transparent to AI Functions)
- Zero configuration required

**Access Controls:**
- Role-based access to stage and views

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

-- Or using catalog view (stage and path stored separately):
SELECT
    catalog.document_id,
    AI_PARSE_DOCUMENT(
        TO_FILE(catalog.stage_name, catalog.file_path),
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
    parsed_content:text::STRING AS extracted_text
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS
LIMIT 5;
```

### 2. Translate with AI_TRANSLATE
```sql
-- Translate non-English documents to English
SELECT
    source_language,
    AI_TRANSLATE(
        source_text,
        source_language,   -- 'es', 'fr', 'de', etc. (or '' for auto-detect)
        'en'               -- Target language
    ) AS translated_text
FROM SWIFTCLAW.STG_TRANSLATED_CONTENT
LIMIT 5;

-- View translation results
SELECT
    source_language,
    target_language,
    SUBSTR(source_text, 1, 100) AS source_preview,
    SUBSTR(translated_text, 1, 100) AS translated_preview
FROM SWIFTCLAW.STG_TRANSLATED_CONTENT
LIMIT 5;
```

### 3. Enrich with AI_COMPLETE Structured Output

```sql
SELECT
    document_id,
    document_type,
    priority_level,
    total_amount,
    currency,
    document_date,
    vendor_territory,
    confidence_score
FROM SWIFTCLAW.STG_ENRICHED_DOCUMENTS
LIMIT 10;
```

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

**Demo Expiration:** This repository will be archived and made private on 2026-02-08
