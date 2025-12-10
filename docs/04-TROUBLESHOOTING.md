# Troubleshooting Guide - AI Document Processing Demo

**Author:** SE Community
**Last Updated:** 2025-11-24
**Expires:** 2026-01-09

---

## Common Issues & Solutions

### Deployment Issues

#### 1. "API_INTEGRATION not found" or "Git repository not accessible"

**Symptoms:**
- Error during `deploy_all.sql` execution
- Cannot fetch from GitHub repository

**Causes:**
- API integration failed to create
- GitHub repository is private or inaccessible
- Corporate firewall blocking GitHub

**Solutions:**

**Check API integration status:**
```sql
SHOW API INTEGRATIONS LIKE 'SFE_GIT%';
```

**Expected output:**
- `ENABLED = TRUE`
- `API_ALLOWED_PREFIXES` includes `https://github.com/sfc-gh-miwhitaker/`

**If integration is missing, recreate:**
```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION SFE_GIT_API_INTEGRATION
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE;
```

**Test GitHub access:**
```sql
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo FETCH;
LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/;
```

---

#### 2. "Insufficient privileges to perform operation"

**Symptoms:**
- Error during deployment
- Cannot create API integration or warehouse

**Cause:** Not using ACCOUNTADMIN role

**Solution:**
```sql
USE ROLE ACCOUNTADMIN;
-- Then re-run deploy_all.sql
```

---

#### 3. "Warehouse suspended during execution"

**Symptoms:**
- Deployment stops mid-execution
- Timeout errors

**Cause:** Warehouse auto-suspended due to inactivity

**Solution:**

**Resume warehouse:**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH RESUME;
```

**Increase auto-suspend timeout (for long deployments):**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH
SET AUTO_SUSPEND = 600;  -- 10 minutes
```

---

### Streamlit Dashboard Issues

#### 4. "Streamlit app won't load" or shows blank page

**Symptoms:**
- Dashboard URL shows loading spinner indefinitely
- Blank white page
- Error: "Streamlit not found"

**Causes:**
- Streamlit app not deployed correctly
- streamlit_app.py file not found in Git repository
- Insufficient permissions

**Solutions:**

**Check if Streamlit exists:**
```sql
SHOW STREAMLITS IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT;
```

**Recreate Streamlit app:**
```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE STREAMLIT SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD
    ROOT_LOCATION = '@SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_DOCUMENT_AI_WH;
```

**Check Streamlit logs for errors:**
```sql
SELECT *
FROM TABLE(INFORMATION_SCHEMA.STREAMLIT_LOGS('SFE_DOCUMENT_DASHBOARD'))
ORDER BY TIMESTAMP DESC
LIMIT 100;
```

**Verify file exists in Git:**
```sql
LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/streamlit/;
```

---

#### 5. "Streamlit shows 'Connection error' or 'Session expired'"

**Cause:** User lacks permissions on warehouse or database

**Solution:**

**Grant required permissions:**
```sql
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON WAREHOUSE SFE_DOCUMENT_AI_WH TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON SCHEMA SFE_ANALYTICS_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA SFE_ANALYTICS_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;
```

**Switch to demo role:**
```sql
USE ROLE SFE_DEMO_ROLE;
```

---

### Data & Query Issues

#### 6. "No data appears in tables" or "Tables are empty"

**Symptoms:**
- Queries return 0 rows
- Streamlit dashboard shows "No data"

**Cause:** Sample data not loaded

**Solution:**

**Check row counts:**
```sql
SELECT 'RAW_INVOICES' AS table_name, COUNT(*) FROM SFE_RAW_ENTERTAINMENT.RAW_INVOICES
UNION ALL
SELECT 'RAW_ROYALTY_STATEMENTS', COUNT(*) FROM SFE_RAW_ENTERTAINMENT.RAW_ROYALTY_STATEMENTS
UNION ALL
SELECT 'RAW_CONTRACTS', COUNT(*) FROM SFE_RAW_ENTERTAINMENT.RAW_CONTRACTS;
```

**Expected:** 500 invoices, 300 royalty statements, 50 contracts

**If counts are 0, reload sample data:**
```sql
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/02_data/02_load_sample_data.sql;
```

---

#### 7. "Confidence scores are all NULL" or "Processing incomplete"

**Symptoms:**
- `STG_PARSED_DOCUMENTS` table is empty
- `FCT_DOCUMENT_INSIGHTS` has NULL confidence scores

**Cause:** AI processing scripts not run

**Solution:**

**Re-run AI processing pipeline:**
```sql
-- Parse documents
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/01_parse_documents.sql;

-- Translate content
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/02_translate_content.sql;

-- Classify documents
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/03_classify_documents.sql;

-- Aggregate insights
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/04_aggregate_insights.sql;
```

---

### Performance Issues

#### 8. "Queries are slow" or "Dashboard takes long to load"

**Symptoms:**
- Streamlit dashboard loads for >30 seconds
- SQL queries timeout

**Causes:**
- Warehouse is too small
- Warehouse auto-suspended and resuming
- Large result sets

**Solutions:**

**Check warehouse status:**
```sql
SHOW WAREHOUSES LIKE 'SFE_DOCUMENT_AI_WH';
```

**Resume suspended warehouse:**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH RESUME;
```

**Upsize warehouse (if needed for large datasets):**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH
SET WAREHOUSE_SIZE = 'SMALL';  -- Or 'MEDIUM'
```

**Add query filters to reduce result set:**
```sql
-- Instead of:
SELECT * FROM FCT_DOCUMENT_INSIGHTS;

-- Use:
SELECT * FROM FCT_DOCUMENT_INSIGHTS
WHERE document_type = 'Invoice'
LIMIT 1000;
```

---

### Cleanup Issues

#### 9. "Cannot drop schema - dependencies exist"

**Symptoms:**
- Error when running cleanup script
- "Object has dependencies" message

**Solution:**

**Use CASCADE to force deletion:**
```sql
DROP SCHEMA SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT CASCADE;
DROP SCHEMA SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT CASCADE;
DROP SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT CASCADE;
```

---

#### 10. "Warehouse still consuming credits after cleanup"

**Cause:** Warehouse not dropped or suspended

**Solution:**

**Suspend immediately:**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SUSPEND;
```

**Or drop completely:**
```sql
DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;
```

---

## Diagnostic Queries

### Check Deployment Status

```sql
-- Verify all schemas exist
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE 'SFE_%';
-- Expected: 3 schemas

-- Verify tables exist
SELECT table_schema, table_name
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.TABLES
WHERE table_schema LIKE 'SFE_%';
-- Expected: 7 tables

-- Verify Streamlit exists
SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;
-- Expected: SFE_DOCUMENT_DASHBOARD

-- Verify warehouse exists and is running
SHOW WAREHOUSES LIKE 'SFE_DOCUMENT_AI_WH';
-- Expected: ENABLED = TRUE
```

### Check Data Pipeline Health

```sql
-- View processing metrics
SELECT * FROM SFE_ANALYTICS_ENTERTAINMENT.V_PROCESSING_METRICS;

-- Check for errors in processing
SELECT
    document_id,
    confidence_score,
    requires_manual_review
FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS
WHERE confidence_score < 0.80;
```

---

## Getting Additional Help

### Snowflake Documentation
- **Cortex AI Functions:** https://docs.snowflake.com/en/user-guide/snowflake-cortex
- **Streamlit in Snowflake:** https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit
- **Git Integration:** https://docs.snowflake.com/en/developer-guide/git/git-overview

### Demo-Specific Help
- **GitHub Repository:** https://github.com/sfc-gh-miwhitaker/swiftclaw
- **Architecture Diagrams:** See `diagrams/` directory
- **SQL Scripts:** See `sql/` directory for implementation details

---

## Error Code Reference

| Error Code | Meaning | Solution |
|------------|---------|----------|
| 002003 | Syntax error in SQL | Check for typos in script |
| 000904 | Object does not exist | Verify object name and schema |
| 091130 | API integration not found | Recreate API integration |
| 002024 | Insufficient privileges | Switch to ACCOUNTADMIN role |
| 003001 | Session expired | Re-login to Snowsight |

---

**Still stuck?**
Contact your Snowflake account team or check the [GitHub repository issues](https://github.com/sfc-gh-miwhitaker/swiftclaw/issues).

---

**Demo Expires:** 2026-01-09
