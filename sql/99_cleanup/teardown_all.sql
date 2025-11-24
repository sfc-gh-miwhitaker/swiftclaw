/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Complete Teardown
 * 
 * ⚠️  THIS WILL DELETE ALL DEMO OBJECTS - USE WITH CAUTION
 * 
 * PURPOSE:
 *   Remove all objects created by this demo, including:
 *   - All SFE_* schemas and their contents
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
 * 🗑️  DESIGNED FOR "RUN ALL" EXECUTION:
 *   1. Copy this ENTIRE script (Ctrl+A or Cmd+A to select all)
 *   2. Open Snowsight → https://app.snowflake.com
 *   3. Create new worksheet: Click "+" → "SQL Worksheet"
 *   4. Paste the entire script (Ctrl+V or Cmd+V)
 *   5. REVIEW the warning summary below (lines 47-62)
 *   6. Click "Run All" button (▶️ dropdown → "Run All")
 *   7. All demo objects will be deleted immediately
 *   8. No undo available - objects are permanently removed
 * 
 * OR run from command line:
 *   snowsql -f sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Switch to ACCOUNTADMIN for cleanup
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- PRE-CLEANUP CHECKS (Optional but Recommended)
-- ============================================================================
-- Run these queries BEFORE cleanup to see what will be removed:

-- Check current schemas
-- SHOW SCHEMAS LIKE 'SFE_%' IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check if API integration is used by other demos
-- SHOW GIT REPOSITORIES; -- If multiple repos use SFE_GIT_API_INTEGRATION, consider keeping it

-- Check warehouse usage
-- SHOW WAREHOUSES LIKE 'SFE_%';

-- ============================================================================
-- ⚠️  WARNING SUMMARY (Review before executing)
-- ============================================================================
--
-- When you click "Run All", these objects will be IMMEDIATELY deleted:
--   - Streamlit app: SFE_DOCUMENT_DASHBOARD
--   - 3 schemas: SFE_RAW_ENTERTAINMENT, SFE_STG_ENTERTAINMENT, SFE_ANALYTICS_ENTERTAINMENT
--   - 7 tables + 1 view across all schemas
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
--   1. Streamlit apps (depend on schemas/tables)
--   2. Views (depend on tables)
--   3. Tables (depend on schemas)
--   4. Schemas (depend on database)
--   5. Git repositories (can be dropped anytime)
--   6. Warehouses (can be dropped anytime)
--   7. API integrations (can be dropped anytime, but check if shared)
--   8. Roles (should be dropped last)
-- ============================================================================

-- ============================================================================
-- STEP 1: DROP STREAMLIT APP
-- ============================================================================

DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD;

-- Streamlit app has been dropped

-- ============================================================================
-- STEP 2: DROP VIEWS
-- ============================================================================

DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.V_PROCESSING_METRICS;

-- View has been dropped

-- ============================================================================
-- STEP 3: DROP TABLES (in dependency order)
-- ============================================================================

-- Analytics layer
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS;

-- Staging layer
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT.STG_TRANSLATED_CONTENT;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS;

-- Raw layer
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_CONTRACTS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_ROYALTY_STATEMENTS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_INVOICES;

-- All tables have been dropped (7 total)

-- ============================================================================
-- STEP 4: DROP SCHEMAS
-- ============================================================================
-- NOTE: Schemas are dropped without CASCADE to ensure we've explicitly
--       cleaned up all contained objects in previous steps. This provides
--       a safety check - if a schema drop fails, we know objects remain.

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT;

-- All schemas have been dropped (3 total)

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

-- Check for remaining SFE_* schemas
SHOW SCHEMAS LIKE 'SFE_%' IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check for remaining SFE_* warehouses
SHOW WAREHOUSES LIKE 'SFE_%';

-- Check for remaining SFE_* API integrations
SHOW API INTEGRATIONS LIKE 'SFE_%';

-- Check for remaining SFE_* roles
SHOW ROLES LIKE 'SFE_%';

-- Check for remaining git repositories in GIT_REPOS schema
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;

-- ============================================================================
-- ✅ CLEANUP COMPLETE
-- ============================================================================
--
-- Removed Objects:
--   ✓ Streamlit app: SFE_DOCUMENT_DASHBOARD
--   ✓ 3 schemas: SFE_RAW_ENTERTAINMENT, SFE_STG_ENTERTAINMENT, SFE_ANALYTICS_ENTERTAINMENT
--   ✓ 7 tables + 1 view
--   ✓ Warehouse: SFE_DOCUMENT_AI_WH
--   ✓ Git repository: sfe_swiftclaw_repo
--   ✓ API Integration: SFE_GIT_API_INTEGRATION (if not shared)
--   ✓ Role: SFE_DEMO_ROLE
--
-- Preserved Objects (Shared Infrastructure):
--   • SNOWFLAKE_EXAMPLE database (may contain other demos)
--   • SNOWFLAKE_EXAMPLE.GIT_REPOS schema (may contain other repos)
--
-- Verification Commands:
--   Run the SHOW commands above to confirm cleanup
--   All should return 0 results for SFE_* objects
-- ============================================================================

