# Cleanup Guide - AI Document Processing Demo

**Author:** SE Community
**Last Updated:** 2025-11-24
**Expires:** 2026-02-08

---

## Overview

This demo automatically expires on **2026-02-08** (30 days from creation). This guide explains how to manually remove all demo objects before expiration if needed.

---

## Quick Cleanup (Recommended)

### Option 1: Run Teardown Script

**Easiest method** - uses the pre-built cleanup script:

1. Log into Snowsight: https://app.snowflake.com
2. Switch to ACCOUNTADMIN role:
   ```sql
   USE ROLE ACCOUNTADMIN;
   ```
3. Open new SQL worksheet
4. Copy and paste the entire contents of `sql/99_cleanup/teardown_all.sql`
5. Click **"Run All"** (▶️ dropdown)
6. Wait ~30 seconds for completion

**What gets deleted:**
- ✅ All 3 SFE_* schemas and their contents (7 tables, 1 view)
- ✅ Streamlit dashboard
- ✅ Git repository stage
- ✅ Dedicated warehouse (SFE_DOCUMENT_AI_WH)
- ✅ API integration
- ✅ Demo role

**What stays (protected):**
- ✅ SNOWFLAKE_EXAMPLE database (may be used by other demos)
- ✅ SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared across demos)

### Option 2: Manual Cleanup Commands

If you prefer to delete objects selectively:

```sql
USE ROLE ACCOUNTADMIN;

-- Delete Streamlit app
DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD;

-- Delete schemas (CASCADE removes all contents)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT CASCADE;

-- Delete Git repository
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo;

-- Delete warehouse
DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;

-- Delete API integration
DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;

-- Delete demo role
DROP ROLE IF EXISTS SFE_DEMO_ROLE;
```

---

## Verification

After cleanup, verify all demo objects are removed:

```sql
-- Check for SFE_* schemas (should return 0 results)
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE 'SFE_%';

-- Check for SFE_* warehouses (should return 0 results)
SHOW WAREHOUSES LIKE 'SFE_%';

-- Check for SFE_* API integrations (should return 0 results)
SHOW API INTEGRATIONS LIKE 'SFE_%';

-- Check for SFE_* roles (should return 0 results)
SHOW ROLES LIKE 'SFE_%';
```

---

## Partial Cleanup (Keep Some Objects)

If you want to keep certain objects for reference:

### Keep Data, Remove Processing

```sql
-- Keep raw data tables, delete staging and analytics
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT CASCADE;
-- Raw data remains in SFE_RAW_ENTERTAINMENT
```

### Keep Warehouse, Remove Data

```sql
-- Delete data schemas only, keep warehouse for other work
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT CASCADE;
-- SFE_DOCUMENT_AI_WH remains available
```

---

## Cost Implications

### Before Cleanup
- **Warehouse:** ~0.5 credits/month (auto-suspend after 60 sec)
- **Storage:** ~$0.01/month (1GB demo data)
- **Total:** ~$1-2/month if left running

### After Cleanup
- **No ongoing costs** - all compute and storage removed
- **Snowflake account remains active** - no impact on other projects

---

## Troubleshooting Cleanup

### Error: "Insufficient privileges"

**Cause:** Not using ACCOUNTADMIN role
**Fix:**
```sql
USE ROLE ACCOUNTADMIN;
-- Then re-run cleanup script
```

### Error: "Object does not exist"

**Cause:** Object already deleted or never created
**Fix:** This is safe to ignore - cleanup is idempotent

### Error: "Cannot drop schema with dependencies"

**Cause:** External references to schema objects
**Fix:** Use CASCADE to force deletion:
```sql
DROP SCHEMA SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT CASCADE;
```

### Error: "Warehouse is still running"

**Cause:** Active queries on warehouse
**Fix:** Wait for queries to complete, or suspend warehouse:
```sql
ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SUSPEND;
-- Then run: DROP WAREHOUSE SFE_DOCUMENT_AI_WH;
```

---

## Cleanup Checklist

Use this checklist to ensure complete removal:

- [ ] Streamlit dashboard deleted
- [ ] All 3 SFE_* schemas deleted
- [ ] All 7 tables deleted (automatic with schema CASCADE)
- [ ] Monitoring view deleted (automatic with schema CASCADE)
- [ ] Git repository deleted
- [ ] Warehouse deleted
- [ ] API integration deleted
- [ ] Demo role deleted
- [ ] Verified: `SHOW SCHEMAS LIKE 'SFE_%'` returns 0 results
- [ ] Verified: `SHOW WAREHOUSES LIKE 'SFE_%'` returns 0 results

---

## Post-Cleanup

After cleanup completes:

✅ **Demo is fully removed** - no demo objects remain
✅ **Account is clean** - ready for new projects
✅ **No ongoing costs** - compute and storage freed
✅ **SNOWFLAKE_EXAMPLE database intact** - other demos unaffected

---

## Re-Deployment

To re-deploy the demo after cleanup:

1. Go to GitHub: https://github.com/sfc-gh-miwhitaker/swiftclaw
2. Copy `deploy_all.sql` from the repository
3. Paste into Snowsight and run
4. Wait ~10 minutes for fresh deployment

---

**Questions?**
See [04-TROUBLESHOOTING.md](04-TROUBLESHOOTING.md) for additional help.

---

**Demo Expiration:** 2026-02-08
After this date, this repository will be archived automatically.
