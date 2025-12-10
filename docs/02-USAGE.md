# Usage Guide - AI Document Processing Demo

**Author:** SE Community
**Last Updated:** 2025-11-24
**Expires:** 2026-01-09

---

## Quick Start

After deployment completes (see [01-PREREQUISITES.md](01-PREREQUISITES.md)), you have three ways to interact with the demo:

1. **Streamlit Dashboard** (Recommended for business users)
2. **SQL Queries** (For data analysts and engineers)
3. **Architecture Exploration** (For learning Snowflake patterns)

---

## Option 1: Streamlit Dashboard 📱

### Access the Dashboard

1. Log into Snowsight: https://app.snowflake.com
2. Switch to `SFE_DEMO_ROLE`:
   ```sql
   USE ROLE SFE_DEMO_ROLE;
   ```
3. Navigate: **Home** → **Streamlit Apps**
4. Click: **SFE_DOCUMENT_DASHBOARD**

### Dashboard Features

**Pipeline Health Tab:**
- Real-time processing status
- Overall confidence scores
- Manual review queue size
- Total value processed

**Document Insights Tab:**
- Searchable table of all processed documents
- Filters: Document type, priority, review status
- Sortable by date, amount, confidence

**Analytics Tab:**
- Value by document type (bar chart)
- Priority distribution (pie chart)
- Confidence score histogram

**Manual Review Queue:**
- Documents flagged for human verification
- Sorted by priority and confidence
- Quick access to low-confidence documents

---

## Option 2: SQL Queries 💻

### Connect to Database

```sql
USE ROLE SFE_DEMO_ROLE;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;
```

### Sample Queries

**View All Document Insights:**
```sql
SELECT
    document_type,
    vendor_territory,
    total_amount,
    confidence_score,
    requires_manual_review
FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS
ORDER BY total_amount DESC
LIMIT 100;
```

**High-Value Invoices Needing Review:**
```sql
SELECT
    document_id,
    total_amount,
    vendor_territory,
    confidence_score
FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS
WHERE document_type = 'Invoice'
  AND total_amount > 50000
  AND requires_manual_review = TRUE
ORDER BY total_amount DESC;
```

**Pipeline Monitoring Metrics:**
```sql
SELECT * FROM SFE_ANALYTICS_ENTERTAINMENT.V_PROCESSING_METRICS;
```

**Documents by Language:**
```sql
SELECT
    parsed_content:detected_language::STRING AS language,
    COUNT(*) AS document_count,
    AVG(confidence_score) AS avg_confidence
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
GROUP BY language;
```

**Top 10 Vendors by Value:**
```sql
SELECT
    vendor_territory AS vendor,
    COUNT(*) AS invoice_count,
    SUM(total_amount) AS total_invoiced,
    AVG(confidence_score) AS avg_confidence
FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS
WHERE document_type = 'Invoice'
GROUP BY vendor
ORDER BY total_invoiced DESC
LIMIT 10;
```

---

## Option 3: Architecture Exploration 🏗️

### Explore Raw Documents

```sql
-- View raw invoice metadata
SELECT
    document_id,
    vendor_name,
    original_language,
    file_size_bytes,
    upload_date
FROM SFE_RAW_ENTERTAINMENT.RAW_INVOICES
LIMIT 10;
```

### Explore AI Processing Results

```sql
-- View parsed document structure
SELECT
    document_id,
    parsed_content:document_type::STRING AS doc_type,
    parsed_content:total_amount::FLOAT AS amount,
    confidence_score
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS
LIMIT 10;
```

### Explore Data Flow

```sql
-- Trace a single document through the pipeline
WITH document_trace AS (
    SELECT 'INV_...' AS doc_id  -- Replace with actual document_id
)
SELECT 'Raw Document' AS stage, document_id, NULL AS confidence
FROM SFE_RAW_ENTERTAINMENT.RAW_INVOICES, document_trace
WHERE RAW_INVOICES.document_id = doc_id

UNION ALL

SELECT 'Parsed', document_id, confidence_score
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS, document_trace
WHERE STG_PARSED_DOCUMENTS.document_id = doc_id

UNION ALL

SELECT 'Classified', document_id, classification_confidence
FROM SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS c
JOIN SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS p ON c.parsed_id = p.parsed_id, document_trace
WHERE p.document_id = doc_id

UNION ALL

SELECT 'Insights', document_id, confidence_score
FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS, document_trace
WHERE FCT_DOCUMENT_INSIGHTS.document_id = doc_id;
```

---

## Understanding the Data

### Document Types

- **Invoice:** Vendor payment requests, contains amounts and line items
- **Royalty Statement:** Territory-based royalty payments for titles
- **Contract:** Legal agreements with effective dates and terms

### Priority Levels

- **High:** Invoices > $50K, Royalty Statements > $100K, Contracts > $1M
- **Medium:** Invoices $10K-$50K, Royalty $25K-$100K, Contracts $250K-$1M
- **Low:** Below medium thresholds

### Confidence Scores

- **0.90-1.00:** Excellent quality, auto-process
- **0.85-0.89:** Good quality, spot-check recommended
- **0.80-0.84:** Fair quality, manual review recommended
- **< 0.80:** Low confidence, requires manual verification

---

## Tips & Best Practices

### Performance Tips
- Use filters in Streamlit dashboard for large result sets
- Add `LIMIT` clauses to SQL queries for exploratory analysis
- Warehouse auto-suspends after 60 seconds to save costs

### Data Refresh
- Sample data is static (generated at deployment time)
- To simulate new documents, run `sql/02_data/02_load_sample_data.sql` again
- Processing pipeline can be re-run with `sql/03_ai_processing/*.sql` scripts

### Security Note
- Demo uses synthetic data only (no real invoices/contracts)
- All vendor names and amounts are randomly generated
- Safe for demos, presentations, and training

---

## Next Steps

- **Customize:** Modify Streamlit dashboard ([streamlit/streamlit_app.py](../streamlit/streamlit_app.py))
- **Extend:** Add new AI processing logic ([sql/03_ai_processing/](../sql/03_ai_processing/))
- **Learn:** Review architecture diagrams ([diagrams/](../diagrams/))
- **Cleanup:** When finished, run [03-CLEANUP.md](03-CLEANUP.md)

---

**Questions?**
See [04-TROUBLESHOOTING.md](04-TROUBLESHOOTING.md) for help.
