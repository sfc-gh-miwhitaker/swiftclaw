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
 * USAGE:
 *   Copy this entire script into Snowsight and click "Run All"
 *   OR run from command line:
 *   snowsql -f sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Switch to ACCOUNTADMIN for cleanup
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- CONFIRMATION PROMPT
-- ============================================================================

SELECT '⚠️  WARNING: This will delete all demo objects!' AS message
UNION ALL
SELECT 'Objects to be deleted:' AS message
UNION ALL
SELECT '  - Streamlit app: SFE_DOCUMENT_DASHBOARD' AS message
UNION ALL
SELECT '  - 3 schemas: SFE_RAW_ENTERTAINMENT, SFE_STG_ENTERTAINMENT, SFE_ANALYTICS_ENTERTAINMENT' AS message
UNION ALL
SELECT '  - 7 tables + 1 view across all schemas' AS message
UNION ALL
SELECT '  - Warehouse: SFE_DOCUMENT_AI_WH' AS message
UNION ALL
SELECT '  - Git repository: sfe_swiftclaw_repo' AS message
UNION ALL
SELECT '  - API Integration: SFE_GIT_API_INTEGRATION' AS message
UNION ALL
SELECT '  - Role: SFE_DEMO_ROLE' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Protected (NOT deleted):' AS message
UNION ALL
SELECT '  - SNOWFLAKE_EXAMPLE database' AS message
UNION ALL
SELECT '  - SNOWFLAKE_EXAMPLE.GIT_REPOS schema' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'To proceed, run the DROP commands below.' AS message;

-- ============================================================================
-- STEP 1: DROP STREAMLIT APP
-- ============================================================================

DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD;

SELECT 'Step 1: Streamlit app dropped' AS status;

-- ============================================================================
-- STEP 2: DROP VIEWS
-- ============================================================================

DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.V_PROCESSING_METRICS;

SELECT 'Step 2: Views dropped' AS status;

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

SELECT 'Step 3: Tables dropped (7 tables)' AS status;

-- ============================================================================
-- STEP 4: DROP SCHEMAS
-- ============================================================================

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT;

SELECT 'Step 4: Schemas dropped (3 schemas)' AS status;

-- ============================================================================
-- STEP 5: DROP GIT REPOSITORY
-- ============================================================================

DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo;

SELECT 'Step 5: Git repository dropped' AS status;

-- ============================================================================
-- STEP 6: DROP WAREHOUSE
-- ============================================================================

DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;

SELECT 'Step 6: Warehouse dropped' AS status;

-- ============================================================================
-- STEP 7: DROP API INTEGRATION
-- ============================================================================

DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;

SELECT 'Step 7: API integration dropped' AS status;

-- ============================================================================
-- STEP 8: DROP DEMO ROLE
-- ============================================================================

DROP ROLE IF EXISTS SFE_DEMO_ROLE;

SELECT 'Step 8: Demo role dropped' AS status;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify all demo objects are gone
SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE 'SFE_%';
SHOW WAREHOUSES LIKE 'SFE_%';
SHOW API INTEGRATIONS LIKE 'SFE_%';
SHOW ROLES LIKE 'SFE_%';

SELECT '========================================' AS message
UNION ALL
SELECT 'CLEANUP COMPLETE' AS message
UNION ALL
SELECT '========================================' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'All demo objects have been removed.' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Preserved objects:' AS message
UNION ALL
SELECT '  - SNOWFLAKE_EXAMPLE database' AS message
UNION ALL
SELECT '  - SNOWFLAKE_EXAMPLE.GIT_REPOS schema' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'To verify cleanup:' AS message
UNION ALL
SELECT '  SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE ''SFE_%'';' AS message
UNION ALL
SELECT '  (Should return 0 results)' AS message
UNION ALL
SELECT '========================================' AS message;

