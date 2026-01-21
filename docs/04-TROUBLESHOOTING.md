# Troubleshooting Guide - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Expires:** 2026-02-20

---

## Common Issues and Solutions

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
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SET AUTO_SUSPEND = 600;
```

---

### Streamlit Dashboard Issues

#### 4. "Streamlit app won't load" or shows blank page

**Causes:**
- Streamlit app not deployed correctly
- `streamlit_app.py` not found in Git repository
- Insufficient permissions

**Solutions:**

**Check Streamlit exists:**
```sql
SHOW STREAMLITS IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW;
```

**Recreate Streamlit app:**
```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE STREAMLIT SNOWFLAKE_EXAMPLE.SWIFTCLAW.SFE_DOCUMENT_DASHBOARD
    FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_DOCUMENT_AI_WH;
```

**Check Streamlit logs:**
```sql
SELECT *
FROM TABLE(INFORMATION_SCHEMA.STREAMLIT_LOGS('SFE_DOCUMENT_DASHBOARD'))
ORDER BY TIMESTAMP DESC
LIMIT 100;
```

---

#### 5. "Streamlit shows connection error or session expired"

**Cause:** User lacks permissions on warehouse or database

**Solution:**
```sql
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON WAREHOUSE SFE_DOCUMENT_AI_WH TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
```

---

### Data and Pipeline Issues

#### 6. "No data appears in tables" or "Dashboard shows no data"

**Cause:** Documents were not uploaded to the stage

**Solution:**
```sql
LS @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE PATTERN = '.*\\.pdf';
```

If no files are listed, upload PDFs to the stage. Dynamic Tables refresh automatically within the target lag window.

---

#### 7. "Insights are empty" or "Confidence scores are NULL"

**Causes:**
- AI functions did not return valid output
- Document text could not be extracted

**Solutions:**
```sql
SELECT
    document_id,
    SUBSTR(parsed_content:text::STRING, 1, 200) AS parsed_preview
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_PARSED_DOCUMENTS
LIMIT 10;
```

If parsed content is empty, confirm the file is a valid PDF and that the stage path is correct.

---

### Performance Issues

#### 8. "Queries are slow" or "Dashboard takes long to load"

**Causes:**
- Warehouse is too small
- Warehouse is suspended and resuming
- Large result sets

**Solutions:**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SET WAREHOUSE_SIZE = 'SMALL';
```

Add filters or `LIMIT` clauses for interactive queries.

---

### Cleanup Issues

#### 9. "Cannot drop schema - dependencies exist"

**Solution:**
```sql
DROP SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;
```

---

#### 10. "Warehouse still consuming credits after cleanup"

**Solution:**
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SUSPEND;
```

---

## Diagnostic Queries

### Check Deployment Status

```sql
SHOW SCHEMAS LIKE 'SWIFTCLAW' IN DATABASE SNOWFLAKE_EXAMPLE;
SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;
SHOW WAREHOUSES LIKE 'SFE_DOCUMENT_AI_WH';
```

### Check Pipeline Health

```sql
SELECT
    pipeline_health_status,
    completion_percentage,
    avg_overall_confidence,
    documents_needing_review
FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.V_PROCESSING_METRICS;
```

---

## Getting Additional Help

### Snowflake Documentation
- Cortex AI Functions: https://docs.snowflake.com/en/user-guide/snowflake-cortex  
- Streamlit in Snowflake: https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit  
- Git Integration: https://docs.snowflake.com/en/developer-guide/git/git-overview  

### Demo-Specific Help
- GitHub Repository: https://github.com/sfc-gh-miwhitaker/swiftclaw  
- Architecture Diagrams: See `diagrams/` directory  
- SQL Scripts: See `sql/` directory  

---

**Demo Expires:** 2026-02-20

