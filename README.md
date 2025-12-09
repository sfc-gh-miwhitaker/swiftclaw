# AI Document Processing for Entertainment Industry

![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2025--12--24-orange)
![Status](https://img.shields.io/badge/Status-Active-success)

> **DEMONSTRATION PROJECT - EXPIRES: 2025-12-24**  
> This demo uses Snowflake AI Functions current as of November 2024.  
> After expiration, this repository will be archived and made private.

**Author:** SE Community  
**Purpose:** Reference implementation for AI-powered document processing in media & entertainment  
**Created:** 2025-11-24 | **Expires:** 2025-12-24 (30 days) | **Status:** ACTIVE

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

3. **Explore** (15 min)
   - Read `docs/02-USAGE.md`
   - Open Streamlit app: `SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD`
   - Review sample document processing results

4. **Cleanup** (2 min)
   - Read `docs/03-CLEANUP.md`
   - Run `sql/99_cleanup/teardown_all.sql`

**Total setup time: ~30 minutes**

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

**RAW LAYER** (`SFE_RAW_ENTERTAINMENT`):
- `DOCUMENT_CATALOG` - Document metadata and stage paths
- `DOCUMENT_PROCESSING_LOG` - Audit trail for all AI operations
- `DOCUMENT_ERRORS` - Error tracking and retry management

**STAGING LAYER** (`SFE_STG_ENTERTAINMENT`):
- `STG_PARSED_DOCUMENTS` - AI_PARSE_DOCUMENT results
- `STG_TRANSLATED_CONTENT` - AI_TRANSLATE results
- `STG_CLASSIFIED_DOCS` - AI_CLASSIFY results
- `STG_EXTRACTED_ENTITIES` - AI_EXTRACT results

**ANALYTICS LAYER** (`SFE_ANALYTICS_ENTERTAINMENT`):
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
| Schema | - | `SFE_RAW_ENTERTAINMENT` | Raw document storage |
| Schema | - | `SFE_STG_ENTERTAINMENT` | Parsed content |
| Schema | - | `SFE_ANALYTICS_ENTERTAINMENT` | Business insights |
| Table | `SFE_RAW_ENTERTAINMENT` | `RAW_INVOICES` | Invoice documents |
| Table | `SFE_RAW_ENTERTAINMENT` | `RAW_ROYALTY_STATEMENTS` | Royalty documents |
| Table | `SFE_RAW_ENTERTAINMENT` | `RAW_CONTRACTS` | Contract documents |
| Table | `SFE_STG_ENTERTAINMENT` | `STG_PARSED_DOCUMENTS` | AI parsing results |
| Table | `SFE_STG_ENTERTAINMENT` | `STG_TRANSLATED_CONTENT` | Translated text |
| Table | `SFE_STG_ENTERTAINMENT` | `STG_CLASSIFIED_DOCS` | Document classifications |
| Table | `SFE_ANALYTICS_ENTERTAINMENT` | `FCT_DOCUMENT_INSIGHTS` | Aggregated metrics |
| View | `SFE_ANALYTICS_ENTERTAINMENT` | `V_PROCESSING_METRICS` | Monitoring dashboard |
| Streamlit | `SFE_ANALYTICS_ENTERTAINMENT` | `SFE_DOCUMENT_DASHBOARD` | Interactive UI |

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

## Real AI Function Examples

### 1. Parse Documents with AI_PARSE_DOCUMENT
```sql
-- Extract text and layout from documents on stage
-- AI_PARSE_DOCUMENT requires 3 arguments: stage, path, options
SELECT 
    catalog.document_id,
    catalog.file_name,
    AI_PARSE_DOCUMENT(
        '@DOCUMENT_STAGE',              -- Stage name (with @)
        'invoices/invoice_001.pdf',     -- File path within stage
        {'mode': 'LAYOUT'}              -- 'OCR' (text only) or 'LAYOUT' (with structure)
    ) AS parsed_document
FROM SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG catalog
WHERE catalog.document_type = 'INVOICE'
LIMIT 5;

-- View already parsed results
SELECT 
    document_id,
    extraction_mode,
    page_count,
    confidence_score,
    parsed_content:text::STRING AS extracted_text
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
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
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS parsed
JOIN SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
WHERE catalog.original_language <> 'en'
LIMIT 5;

-- View translation results
SELECT 
    source_language,
    target_language,
    SUBSTR(source_text, 1, 100) AS source_preview,
    SUBSTR(translated_text, 1, 100) AS translated_preview,
    translation_confidence
FROM SFE_STG_ENTERTAINMENT.STG_TRANSLATED_CONTENT
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
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
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
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
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
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
WHERE document_id IN (SELECT document_id FROM SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG WHERE document_type = 'INVOICE')
LIMIT 5;

-- View extracted entities (flattened)
SELECT 
    catalog.document_type,
    entity.entity_type,
    entity.entity_value,
    entity.extraction_confidence
FROM SFE_STG_ENTERTAINMENT.STG_EXTRACTED_ENTITIES entity
JOIN SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS parsed ON entity.parsed_id = parsed.parsed_id
JOIN SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
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
DROP DATABASE IF EXISTS SNOWFLAKE_EXAMPLE CASCADE;
DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;
DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;
```

**Time:** < 1 minute  
**Verification:** Run `SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE'` - should return no results

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

**Demo Expiration:** This repository will be archived and made private on 2025-12-24

