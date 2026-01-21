# Cleanup Guide - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Expires:** 2026-02-08

---

## Overview

This demo automatically expires on **2026-02-08** (30 days from creation). This guide explains how to manually remove all demo objects before expiration if needed.

---

## Quick Cleanup (Recommended)

### Option 1: Run Teardown Script

1. Log into Snowsight: https://app.snowflake.com  
2. Switch to ACCOUNTADMIN:
   ```sql
   USE ROLE ACCOUNTADMIN;
   ```
3. Open a new SQL worksheet  
4. Copy and paste the entire contents of `sql/99_cleanup/teardown_all.sql`  
5. Click **Run All**  
6. Wait ~30 seconds for completion  

**What gets deleted:**
- Schema `SWIFTCLAW` (dynamic tables, views, stage, Streamlit)
- Git repository `sfe_swiftclaw_repo`
- Warehouse `SFE_DOCUMENT_AI_WH`
- API integration `SFE_GIT_API_INTEGRATION`
- Demo role `SFE_DEMO_ROLE`

**What stays (protected):**
- `SNOWFLAKE_EXAMPLE` database (may be used by other demos)
- `SNOWFLAKE_EXAMPLE.GIT_REPOS` schema (shared across demos)

---

### Option 2: Manual Cleanup Commands

```sql
USE ROLE ACCOUNTADMIN;

DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.SFE_DOCUMENT_DASHBOARD;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo;
DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;
DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;
DROP ROLE IF EXISTS SFE_DEMO_ROLE;
```

---

## Verification

After cleanup, verify all demo objects are removed:

```sql
SHOW SCHEMAS LIKE 'SWIFTCLAW' IN DATABASE SNOWFLAKE_EXAMPLE;
SHOW WAREHOUSES LIKE 'SFE_%';
SHOW API INTEGRATIONS LIKE 'SFE_%';
SHOW ROLES LIKE 'SFE_%';
```

---

## Troubleshooting Cleanup

### Error: "Insufficient privileges"

**Cause:** Not using ACCOUNTADMIN role  
**Fix:**
```sql
USE ROLE ACCOUNTADMIN;
```

### Error: "Cannot drop schema with dependencies"

**Cause:** External references to schema objects  
**Fix:**
```sql
DROP SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;
```

---

## Re-Deployment

To redeploy the demo after cleanup:

1. Go to https://github.com/sfc-gh-miwhitaker/swiftclaw  
2. Copy `deploy_all.sql`  
3. Paste into Snowsight and run  
4. Wait ~10 minutes for fresh deployment  

---

**Demo Expiration:** 2026-02-08  
After this date, this repository will be archived automatically.

