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

This demo showcases Snowflake's AI Functions for automating document processing workflows common in the entertainment industry:

- **Invoice Processing**: Extract structured data from vendor invoices
- **Royalty Statement Analysis**: Parse complex multi-territory royalty documents
- **Contract Review**: Classify and analyze entertainment contracts
- **Multilingual Support**: Translate content while preserving industry-specific terminology
- **Business Intelligence**: Interactive Streamlit dashboard for document insights

**Key Features:**
- 🤖 **AI_PARSE_DOCUMENT** - Extract text and preserve table layouts from PDFs
- 🌐 **AI_TRANSLATE** - Context-aware translation for entertainment terms
  - 🔬 **Quality Test Included**: Russian names validation (addresses real-world issue with occupation-based surnames)
- 🔍 **AI_FILTER** - Natural language document classification
- 📊 **AI_AGG** - Aggregate insights across document collections
- 📱 **Streamlit UI** - Business-user friendly dashboard

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

### Data Flow

```
Raw Documents (PDF/Images)
    ↓
AI_PARSE_DOCUMENT (Extract & Structure)
    ↓
AI_TRANSLATE (Multilingual Processing)
    ↓
AI_FILTER (Classify & Route)
    ↓
AI_AGG (Aggregate Insights)
    ↓
Streamlit Dashboard (Business Users)
```

### Database Schema

- **SFE_RAW_ENTERTAINMENT** - Raw document storage (binary files, metadata)
- **SFE_STG_ENTERTAINMENT** - Parsed and translated content
- **SFE_ANALYTICS_ENTERTAINMENT** - Aggregated business insights

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

- **Snowflake AI Functions**: AI_PARSE_DOCUMENT, AI_TRANSLATE, AI_FILTER, AI_AGG
- **Snowflake Streamlit**: Interactive dashboard
- **Snowflake Git Integration**: GitRepository for code deployment
- **Standard SQL**: Data transformations and aggregations

**100% Native Snowflake** - No external services required

---

## Sample Queries

### 1. Parse Invoice Document
```sql
SELECT 
    invoice_id,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        pdf_content, 
        {'mode': 'LAYOUT'}
    ) AS parsed_invoice
FROM SFE_RAW_ENTERTAINMENT.RAW_INVOICES
LIMIT 5;
```

### 2. Translate Royalty Terms
```sql
SELECT 
    statement_id,
    original_language,
    SNOWFLAKE.CORTEX.TRANSLATE(
        royalty_text, 
        original_language, 
        'en'
    ) AS translated_text
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
WHERE document_type = 'ROYALTY_STATEMENT';
```

### 3. Classify Documents by Type
```sql
SELECT 
    document_id,
    SNOWFLAKE.CORTEX.CLASSIFY(
        document_content,
        ['Invoice', 'Royalty Statement', 'Contract', 'Other']
    ) AS document_classification
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS;
```

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

## License

Apache 2.0 - See LICENSE file for details

---

**Demo Expiration:** This repository will be archived and made private on 2025-12-24

