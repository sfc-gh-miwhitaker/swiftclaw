/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Complete Teardown
 *
 * THIS WILL DELETE ALL DEMO OBJECTS - USE WITH CAUTION
 *
 * PURPOSE:
 *   Remove all objects created by this demo, including:
 *   - Project schema: SWIFTCLAW (dynamic tables, views, stage, Streamlit)
 *   - Git repository stage
 *   - Dedicated warehouse
 *   - API integration
 *   - Demo role
 *
 * PROTECTED OBJECTS (NOT DELETED):
 *   - SNOWFLAKE_EXAMPLE database (may contain other demos)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared across demos)
 *   - Shared API integrations (if used by other demos)
 *
 * DESIGNED FOR "RUN ALL" EXECUTION:
 *   1. Copy this ENTIRE script (Ctrl+A or Cmd+A to select all)
 *   2. Open Snowsight: https://app.snowflake.com
 *   3. Create new worksheet: Click "+" then "SQL Worksheet"
 *   4. Paste the entire script (Ctrl+V or Cmd+V)
 *   5. REVIEW the warning summary below (lines 47-62)
 *   6. Click "Run All"
 *   7. All demo objects will be deleted immediately
 *   8. No undo available - objects are permanently removed
 *
 * OR run from command line:
 *   snowsql -f sql/99_cleanup/teardown_all.sql
 *
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2026-01-21 | Expires: 2026-02-20
 ******************************************************************************/

-- Switch to ACCOUNTADMIN for cleanup
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- PRE-CLEANUP CHECKS (Optional but Recommended)
-- ============================================================================
-- Run these queries BEFORE cleanup to see what will be removed:

-- Check current schemas
-- SHOW SCHEMAS LIKE 'SWIFTCLAW' IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check if API integration is used by other demos
-- SHOW GIT REPOSITORIES; -- If multiple repos use SFE_GIT_API_INTEGRATION, consider keeping it

-- Check warehouse usage
-- SHOW WAREHOUSES LIKE 'SFE_%';

-- ============================================================================
-- WARNING SUMMARY (Review before executing)
-- ============================================================================
--
-- When you click "Run All", these objects will be IMMEDIATELY deleted:
--   - Streamlit app: SFE_DOCUMENT_DASHBOARD
--   - Schema: SWIFTCLAW (dynamic tables, views, stage)
--   - Dynamic tables: 4
--   - Views: 2
--   - Warehouse: SFE_DOCUMENT_AI_WH
--   - Git repository: sfe_swiftclaw_repo
--   - API Integration: SFE_GIT_API_INTEGRATION
--   - Role: SFE_DEMO_ROLE
--
-- Protected (will NOT be deleted):
--   - SNOWFLAKE_EXAMPLE database (may contain other demos)
--   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (may contain other repos)
--
-- IF YOU'RE SURE: Click "Run All" button to execute cleanup
-- IF NOT SURE: Close this worksheet without executing
-- ============================================================================

-- ============================================================================
-- CLEANUP EXECUTION ORDER
-- ============================================================================
-- Objects are dropped in dependency order:
--   1. Streamlit apps (depend on schemas)
--   2. Views (depend on dynamic tables)
--   3. Dynamic tables (depend on schemas)
--   4. Schemas (depend on database)
--   5. Git repositories (can be dropped anytime)
--   6. Warehouses (can be dropped anytime)
--   7. API integrations (can be dropped anytime, but check if shared)
--   8. Roles (should be dropped last)
-- ============================================================================

-- ============================================================================
-- STEP 1: DROP STREAMLIT APP
-- ============================================================================

DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.SFE_DOCUMENT_DASHBOARD;

-- Streamlit app has been dropped

-- ============================================================================
-- STEP 2: DROP VIEWS
-- ============================================================================

DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.V_PROCESSING_METRICS;
-- ============================================================================
-- STEP 2b: DROP TASKS AND PROCEDURES
-- ============================================================================

DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.REFRESH_DOCUMENT_CATALOG_TASK;
DROP PROCEDURE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.REFRESH_DOCUMENT_CATALOG();
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.REFRESH_ENRICHED_DOCUMENTS_TASK;
DROP PROCEDURE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.REFRESH_ENRICHED_DOCUMENTS();

-- View has been dropped

-- ============================================================================
-- STEP 3: DROP DYNAMIC TABLES (in dependency order)
-- ============================================================================

DROP DYNAMIC TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS;
DROP DYNAMIC TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_ENRICHED_DOCUMENTS;
DROP DYNAMIC TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_TRANSLATED_CONTENT;
DROP DYNAMIC TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.STG_PARSED_DOCUMENTS;

DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_ERRORS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_PROCESSING_LOG;

-- Dynamic tables have been dropped

-- ============================================================================
-- STEP 4: DROP SCHEMAS
-- ============================================================================
-- NOTE: Schemas are dropped without CASCADE to ensure we've explicitly
--       cleaned up all contained objects in previous steps. This provides
--       a safety check - if a schema drop fails, we know objects remain.

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;

-- Project schema has been dropped

-- ============================================================================
-- STEP 5: DROP GIT REPOSITORY
-- ============================================================================
-- NOTE: We drop ONLY this demo's Git repository (sfe_swiftclaw_repo) from
--       the shared GIT_REPOS schema. The GIT_REPOS schema itself is preserved
--       as it may contain repositories from other demo projects.

DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo;

-- Git repository has been dropped (sfe_swiftclaw_repo only - GIT_REPOS schema preserved)

-- ============================================================================
-- STEP 6: DROP WAREHOUSE
-- ============================================================================

DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;

-- Warehouse has been dropped

-- ============================================================================
-- STEP 7: DROP API INTEGRATION
-- ============================================================================
-- NOTE: SFE_GIT_API_INTEGRATION may be shared by multiple demo projects.
--       If other demos are using it, you may want to keep it and skip this step.
--       To check: SHOW API INTEGRATIONS LIKE 'SFE_GIT%';

DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;

-- API integration has been dropped (SFE_GIT_API_INTEGRATION)
-- WARNING: If other demos use this API integration, they will be affected

-- ============================================================================
-- STEP 8: DROP DEMO ROLE
-- ============================================================================

DROP ROLE IF EXISTS SFE_DEMO_ROLE;

-- Demo role has been dropped

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify all demo objects are gone
-- Note: These should return empty result sets if cleanup was successful

-- Check for remaining project schema
SHOW SCHEMAS LIKE 'SWIFTCLAW' IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check for remaining SFE_* warehouses
SHOW WAREHOUSES LIKE 'SFE_%';

-- Check for remaining SFE_* API integrations
SHOW API INTEGRATIONS LIKE 'SFE_%';

-- Check for remaining SFE_* roles
SHOW ROLES LIKE 'SFE_%';

-- Check for remaining git repositories in GIT_REPOS schema
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;

-- ============================================================================
-- CLEANUP COMPLETE
-- ============================================================================
--
-- Removed Objects:
--   - Streamlit app: SFE_DOCUMENT_DASHBOARD
--   - Schema: SWIFTCLAW (dynamic tables, views, stage)
--   - Dynamic tables: 4
--   - Views: 2
--   - Warehouse: SFE_DOCUMENT_AI_WH
--   - Git repository: sfe_swiftclaw_repo
--   - API Integration: SFE_GIT_API_INTEGRATION (if not shared)
--   - Role: SFE_DEMO_ROLE
--
-- Preserved Objects (Shared Infrastructure):
--   - SNOWFLAKE_EXAMPLE database (may contain other demos)
--   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (may contain other repos)
--
-- Verification Commands:
--   Run the SHOW commands above to confirm cleanup
--   All should return 0 results for project objects
-- ============================================================================
