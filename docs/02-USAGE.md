# Usage Guide - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Expires:** 2026-02-20

---

## Quick Start

After deployment completes (see `docs/01-PREREQUISITES.md`), you have three ways to interact with the demo:

1. **Streamlit Dashboard** (recommended for business users)  
2. **SQL Queries** (for analysts and engineers)  
3. **Architecture Exploration** (for learning Snowflake patterns)  

---

## Option 1: Streamlit Dashboard

### Access the Dashboard

1. Log into Snowsight: https://app.snowflake.com  
2. Switch to `SFE_DEMO_ROLE`:
   ```sql
   USE ROLE SFE_DEMO_ROLE;
   ```
3. Navigate: **Home** -> **Streamlit Apps**  
4. Click: **SFE_DOCUMENT_DASHBOARD**

### Dashboard Features

**Pipeline Health**
- Processing completeness and confidence trends
- Manual review queue size
- Total value processed

**Document Insights**
- Searchable table of processed documents
- Filters: document type, priority, review status

**Analytics**
- Value by document type
- Priority distribution
- Confidence score histogram

**Manual Review Queue**
- Documents flagged for human verification
- Sorted by priority and confidence

---

## Option 2: SQL Queries

### Connect to Database

```sql
USE ROLE SFE_DEMO_ROLE;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;
```

### Sample Queries

**View Document Insights:**
```sql
SELECT
    document_type,
    vendor_territory,
    total_amount,
    overall_confidence_score,
    requires_manual_review
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
ORDER BY total_amount DESC
LIMIT 100;
```

**High-Value Invoices Needing Review:**
```sql
SELECT
    document_id,
    total_amount,
    vendor_territory,
    overall_confidence_score
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
WHERE document_type = 'INVOICE'
  AND total_amount > 50000
  AND requires_manual_review = TRUE
ORDER BY total_amount DESC;
```

**Pipeline Monitoring Metrics:**
```sql
SELECT
    pipeline_health_status,
    completion_percentage,
    avg_overall_confidence,
    documents_needing_review,
    total_value_processed_usd
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.V_PROCESSING_METRICS;
```

**Documents by Language:**
```sql
SELECT
    original_language,
    COUNT(*) AS document_count
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG
GROUP BY original_language
ORDER BY document_count DESC;
```

**Top Vendors by Value:**
```sql
SELECT
    vendor_territory AS vendor,
    COUNT(*) AS invoice_count,
    SUM(total_amount) AS total_invoiced,
    AVG(overall_confidence_score) AS avg_confidence
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
WHERE document_type = 'INVOICE'
GROUP BY vendor
ORDER BY total_invoiced DESC
LIMIT 10;
```

---

## Option 3: Architecture Exploration

### Explore Catalog Metadata

```sql
SELECT
    document_id,
    document_type,
    original_language,
    file_size_bytes,
    upload_date
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG
ORDER BY upload_date DESC
LIMIT 10;
```

### Explore Parsed Results

```sql
SELECT
    document_id,
    extraction_mode,
    page_count,
    SUBSTR(parsed_content:content::STRING, 1, 200) AS parsed_preview
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_PARSED_DOCUMENTS
ORDER BY processed_at DESC
LIMIT 10;
```

### Explore Enrichment Results

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
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_ENRICHED_DOCUMENTS
LIMIT 10;
```

### Trace a Single Document

```sql
WITH document_trace AS (
    SELECT 'DOC_123' AS doc_id  -- Replace with actual document_id
)
SELECT 'Catalog' AS stage, document_id, NULL AS confidence
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG, document_trace
WHERE RAW_DOCUMENT_CATALOG.document_id = doc_id

UNION ALL

SELECT 'Parsed', document_id, NULL AS confidence
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_PARSED_DOCUMENTS, document_trace
WHERE STG_PARSED_DOCUMENTS.document_id = doc_id

UNION ALL

SELECT 'Enriched', document_id, confidence_score
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_ENRICHED_DOCUMENTS, document_trace
WHERE STG_ENRICHED_DOCUMENTS.document_id = doc_id

UNION ALL

SELECT 'Insights', document_id, overall_confidence_score AS confidence
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS, document_trace
WHERE FCT_DOCUMENT_INSIGHTS.document_id = doc_id;
```

---

## Understanding the Data

### Document Types

- **INVOICE:** Vendor payment requests with amounts and line items  
- **ROYALTY_STATEMENT:** Territory-based royalty payments for titles  
- **CONTRACT:** Legal agreements with effective dates and terms  
- **OTHER:** Uncategorized documents  

### Priority Levels

- **HIGH:** Urgent or high value documents  
- **MEDIUM:** Standard business priority  
- **LOW:** Routine or informational content  

### Confidence Scores

- **0.90-1.00:** Excellent quality, auto-process  
- **0.85-0.89:** Good quality, spot-check recommended  
- **0.80-0.84:** Fair quality, manual review recommended  
- **< 0.80:** Low confidence, requires manual verification  

---

## Tips and Best Practices

### Performance Tips
- Use filters in Streamlit dashboard for large result sets  
- Add `LIMIT` clauses to SQL queries for exploratory analysis  
- Warehouse auto-suspends after 60 seconds to save costs  

### Data Refresh
- Dynamic Tables refresh automatically within the target lag window  
- Upload new PDFs to the stage to trigger processing  

### Security Note
- All data stays in Snowflake and is encrypted at rest  
- Sample documents are synthetic and safe for demos  

---

## Next Steps

- **Customize:** Modify Streamlit dashboard (`streamlit/streamlit_app.py`)  
- **Extend:** Adjust AI pipeline (`sql/03_ai_processing/01_create_dynamic_tables.sql`)  
- **Learn:** Review architecture diagrams (`diagrams/`)  
- **Cleanup:** When finished, run `docs/03-CLEANUP.md`  

---

**Questions?**  
See `docs/04-TROUBLESHOOTING.md` for help.

