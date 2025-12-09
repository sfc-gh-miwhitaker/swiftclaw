/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * DEMONSTRATION PROJECT - EXPIRES: 2025-12-24
 * This demo uses Snowflake AI Functions validated as of December 2025.
 * After expiration, this repository will be archived.
 * 
 * 🚀 DESIGNED FOR "RUN ALL" EXECUTION:
 *   1. Copy this ENTIRE script (Ctrl+A or Cmd+A to select all)
 *   2. Open Snowsight → https://app.snowflake.com
 *   3. Create new worksheet: Click "+" → "SQL Worksheet"
 *   4. Paste the entire script (Ctrl+V or Cmd+V)
 *   5. Click "Run All" button (▶️ dropdown → "Run All")
 *   6. Wait ~10 minutes - script executes all steps automatically
 *   7. No manual intervention required - fully automated deployment
 * 
 * WHAT THIS SCRIPT DOES:
 *   - Creates API integration for GitHub repository access
 *   - Creates Git repository stage with demo SQL scripts
 *   - Creates dedicated XSMALL warehouse for AI processing
 *   - Creates internal stage for document files (PDF, DOCX, etc.)
 *   - Executes setup, data, and REAL AI processing scripts from Git
 *   - Deploys Streamlit dashboard for document processing UI
 * 
 * AI FUNCTIONS USED (All GA/Production-Ready):
 *   - AI_PARSE_DOCUMENT: Extract text and layout from documents
 *   - AI_TRANSLATE: Translate multilingual content
 *   - AI_CLASSIFY: Categorize documents with enhanced descriptions
 *   - AI_EXTRACT: Extract entities without regex patterns
 * 
 * REQUIREMENTS:
 *   - ACCOUNTADMIN role (for API integration creation)
 *   - Internet access (to pull from GitHub)
 *   - ~10 minutes of execution time
 * 
 * ESTIMATED COST:
 *   - One-time: ~1.5 credits (~$3 on Standard edition)
 *   - Monthly: < 0.5 credits if left running (~$1/month)
 * 
 * CLEANUP:
 *   - Run sql/99_cleanup/teardown_all.sql to remove all objects
 *   - Or: DROP DATABASE SNOWFLAKE_EXAMPLE CASCADE;
 *   - Or: DROP WAREHOUSE SFE_DOCUMENT_AI_WH;
 *   - Or: DROP API INTEGRATION SFE_GIT_API_INTEGRATION;
 * 
 * GitHub Repository: https://github.com/sfc-gh-miwhitaker/swiftclaw
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24 (30 days)
 ******************************************************************************/

-- ============================================================================
-- SECTION 0: EXPIRATION CHECK
-- ============================================================================

-- CRITICAL: Check if demo has expired (30 days from creation)
-- This will display a warning/error message but allow execution to continue
SELECT 
    CASE 
        WHEN CURRENT_DATE() > '2025-12-24'::DATE THEN
            '❌ ERROR: This demo expired on 2025-12-24. ' ||
            'Demo projects are maintained for 30 days only. ' ||
            'Contact your Snowflake account team for updated versions.'
        WHEN DATEDIFF('day', CURRENT_DATE(), '2025-12-24'::DATE) <= 7 THEN
            '⚠️  WARNING: This demo expires in ' || 
            DATEDIFF('day', CURRENT_DATE(), '2025-12-24'::DATE) || 
            ' days (2025-12-24). Plan accordingly.'
        ELSE
            '✅ Demo is active. Expires: 2025-12-24 (' || 
            DATEDIFF('day', CURRENT_DATE(), '2025-12-24'::DATE) || 
            ' days remaining)'
    END AS EXPIRATION_STATUS;

-- ============================================================================
-- SECTION 1: ROLE & CONTEXT SETUP
-- ============================================================================

-- Switch to ACCOUNTADMIN (required for API integration creation)
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- SECTION 2: API INTEGRATION FOR GITHUB ACCESS
-- ============================================================================

-- Create or replace API integration for Git HTTPS access
-- NOTE: Using CREATE OR REPLACE to ensure allowed prefixes are updated
--       if integration already exists with different settings
CREATE OR REPLACE API INTEGRATION SFE_GIT_API_INTEGRATION
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
    ENABLED = TRUE
    COMMENT = 'DEMO: swiftclaw - Git integration for AI document processing demo | Expires: 2025-12-24 | Author: SE Community';

-- Verify API integration created successfully
SHOW API INTEGRATIONS LIKE 'SFE_GIT%';

-- ============================================================================
-- SECTION 3: DATABASE & GIT REPOSITORY
-- ============================================================================

-- Create demo database (if not exists)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Repository for example/demo projects - NOT FOR PRODUCTION | Author: SE Community';

-- Create schema for Git repositories
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
    COMMENT = 'DEMO: Git repository stages for code deployment | Author: SE Community';

-- Create Git repository stage
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo
    API_INTEGRATION = SFE_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/swiftclaw'
    COMMENT = 'DEMO: swiftclaw - AI Document Processing demo repository | Expires: 2025-12-24 | Author: SE Community';

-- Fetch latest code from GitHub
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo FETCH;

-- List files in repository (verification)
LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/;

-- ============================================================================
-- SECTION 4: VIRTUAL WAREHOUSE
-- ============================================================================

-- Create dedicated warehouse for AI document processing
CREATE WAREHOUSE IF NOT EXISTS SFE_DOCUMENT_AI_WH WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60                    -- Suspend after 1 minute idle
    AUTO_RESUME = TRUE                   -- Auto-resume on query
    INITIALLY_SUSPENDED = FALSE          -- Start immediately for deployment
    MAX_CLUSTER_COUNT = 1                -- No multi-cluster (demo only)
    MIN_CLUSTER_COUNT = 1
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'DEMO: swiftclaw - Dedicated warehouse for AI document processing | Expires: 2025-12-24 | Author: SE Community';

-- Set warehouse context for subsequent operations
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- Verify warehouse is running
SHOW WAREHOUSES LIKE 'SFE_DOCUMENT_AI_WH';

-- ============================================================================
-- SECTION 5: DEMO ROLE CREATION (Required for script grants)
-- ============================================================================

-- Create demo application role BEFORE executing scripts
-- (Scripts will grant permissions to this role)
CREATE ROLE IF NOT EXISTS SFE_DEMO_ROLE
    COMMENT = 'DEMO: Application role for AI document processing demo | Author: SE Community';

-- Grant warehouse usage (needed for script execution)
GRANT USAGE ON WAREHOUSE SFE_DOCUMENT_AI_WH TO ROLE SFE_DEMO_ROLE;

-- Grant database usage (needed for schema access)
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SFE_DEMO_ROLE;

-- ============================================================================
-- SECTION 6: SETUP SCRIPTS (from Git Repository)
-- ============================================================================

-- Execute: Create schemas for raw, staging, analytics layers
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/01_setup/01_create_schemas.sql;

-- ============================================================================
-- SECTION 7: DATA SCRIPTS (from Git Repository)
-- ============================================================================

-- Execute: Create tables for raw documents
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/02_data/01_create_tables.sql;

-- Execute: Load sample documents
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/02_data/02_load_sample_data.sql;

-- ============================================================================
-- SECTION 8: AI PROCESSING SCRIPTS (from Git Repository)
-- ============================================================================
-- NOTE: These scripts use REAL Snowflake Cortex AI Functions
--       Requires documents to be uploaded to stage for processing

-- Execute: AI_PARSE_DOCUMENT - Extract text and layout from documents
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/01_parse_documents.sql;

-- Execute: AI_TRANSLATE - Translate non-English content to English
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/02_translate_content.sql;

-- Execute: AI_CLASSIFY - Classify documents by type and priority
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/03_classify_documents.sql;

-- Execute: AI_EXTRACT - Extract entities from documents
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/04_extract_entities.sql;

-- Execute: Aggregate insights - Combine all AI results
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/05_aggregate_insights.sql;

-- Execute: Create monitoring view - Real-time metrics
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/06_create_monitoring_view.sql;

-- ============================================================================
-- SECTION 9: STREAMLIT DASHBOARD
-- ============================================================================

-- Create Streamlit app from Git repository
-- NOTE: Using FROM clause (modern syntax) instead of legacy ROOT_LOCATION
--       FROM syntax supports multi-file editing and Git integration
CREATE OR REPLACE STREAMLIT SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD
    FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_DOCUMENT_AI_WH
    COMMENT = 'DEMO: swiftclaw - Interactive dashboard for document processing | Expires: 2025-12-24 | Author: SE Community';

-- Verify Streamlit app created successfully
SHOW STREAMLITS IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT;

-- ============================================================================
-- SECTION 10: FINALIZE ROLE PERMISSIONS
-- ============================================================================

-- Grant schema usage (schemas created by setup scripts)
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;

-- Grant table access
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;

-- Grant view access
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;

-- Grant Streamlit usage
GRANT USAGE ON STREAMLIT SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT.SFE_DOCUMENT_DASHBOARD TO ROLE SFE_DEMO_ROLE;

-- Grant role to SYSADMIN (for easier management)
GRANT ROLE SFE_DEMO_ROLE TO ROLE SYSADMIN;

-- ============================================================================
-- SECTION 11: DEPLOYMENT COMPLETE
-- ============================================================================

SELECT '========================================' AS message
UNION ALL
SELECT 'DEPLOYMENT COMPLETE!' AS message
UNION ALL
SELECT '========================================' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Objects Created:' AS message
UNION ALL
SELECT '  - API Integration: SFE_GIT_API_INTEGRATION' AS message
UNION ALL
SELECT '  - Database: SNOWFLAKE_EXAMPLE' AS message
UNION ALL
SELECT '  - Warehouse: SFE_DOCUMENT_AI_WH (XSMALL)' AS message
UNION ALL
SELECT '  - Git Repository: sfe_swiftclaw_repo' AS message
UNION ALL
SELECT '  - Schemas: SFE_RAW_ENTERTAINMENT, SFE_STG_ENTERTAINMENT, SFE_ANALYTICS_ENTERTAINMENT' AS message
UNION ALL
SELECT '  - Stage: DOCUMENT_STAGE (for file uploads)' AS message
UNION ALL
SELECT '  - Tables: 8 tables (catalog, logs, staging, analytics)' AS message
UNION ALL
SELECT '  - AI Processing: PARSE → TRANSLATE → CLASSIFY → EXTRACT pipeline' AS message
UNION ALL
SELECT '  - Streamlit: SFE_DOCUMENT_DASHBOARD' AS message
UNION ALL
SELECT '  - Role: SFE_DEMO_ROLE' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Next Steps:' AS message
UNION ALL
SELECT '  1. Upload documents (optional): PUT file:///*.pdf @SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE AUTO_COMPRESS=FALSE;' AS message
UNION ALL
SELECT '  2. Switch role: USE ROLE SFE_DEMO_ROLE;' AS message
UNION ALL
SELECT '  3. Open Streamlit: Home → Streamlit → SFE_DOCUMENT_DASHBOARD' AS message
UNION ALL
SELECT '  4. View insights: SELECT * FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS LIMIT 10;' AS message
UNION ALL
SELECT '  5. View metrics: SELECT * FROM SFE_ANALYTICS_ENTERTAINMENT.V_PROCESSING_METRICS;' AS message
UNION ALL
SELECT '  6. Check document catalog: SELECT * FROM SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG;' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Documentation:' AS message
UNION ALL
SELECT '  - README: https://github.com/sfc-gh-miwhitaker/swiftclaw/blob/main/README.md' AS message
UNION ALL
SELECT '  - Usage Guide: docs/02-USAGE.md' AS message
UNION ALL
SELECT '  - Troubleshooting: docs/04-TROUBLESHOOTING.md' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Cleanup (when finished):' AS message
UNION ALL
SELECT '  - Run: @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/99_cleanup/teardown_all.sql' AS message
UNION ALL
SELECT '  - Or manual: DROP DATABASE SNOWFLAKE_EXAMPLE CASCADE; DROP WAREHOUSE SFE_DOCUMENT_AI_WH;' AS message
UNION ALL
SELECT '' AS message
UNION ALL
SELECT 'Demo Expires: 2025-12-24 (30 days from creation)' AS message
UNION ALL
SELECT '========================================' AS message;

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

/*
Common Issues and Solutions:

1. ERROR: "API_INTEGRATION not found"
   - CAUSE: API integration failed to create
   - FIX: Run: SHOW API INTEGRATIONS LIKE 'SFE_GIT%'; 
          Verify integration exists and ENABLED = TRUE

2. ERROR: "Git repository not accessible"
   - CAUSE: GitHub repository is private or URL is incorrect
   - FIX: Verify repository is public: https://github.com/sfc-gh-miwhitaker/swiftclaw
          Check API integration ALLOWED_PREFIXES includes full URL

3. ERROR: "Insufficient privileges"
   - CAUSE: Current role lacks necessary permissions
   - FIX: Ensure using ACCOUNTADMIN role for deployment
          Run: USE ROLE ACCOUNTADMIN;

4. ERROR: "Warehouse suspended during execution"
   - CAUSE: Warehouse auto-suspended due to inactivity
   - FIX: Increase AUTO_SUSPEND to 600 seconds (10 minutes)
          Run: ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SET AUTO_SUSPEND = 600;

5. ERROR: "File not found in Git repository"
   - CAUSE: Git repository not fetched or branch incorrect
   - FIX: Re-fetch repository:
          ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo FETCH;
          Verify files: LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/;

6. ERROR: "Streamlit app won't load"
   - CAUSE: streamlit_app.py file not found or has errors
   - FIX: Verify file exists in Git repo
          Check app logs: SELECT * FROM TABLE(INFORMATION_SCHEMA.STREAMLIT_LOGS('SFE_DOCUMENT_DASHBOARD')) LIMIT 100;

For additional help:
- Review docs/04-TROUBLESHOOTING.md in the Git repository
- Check Snowflake documentation: https://docs.snowflake.com
- Contact your Snowflake account team

GitHub Repository: https://github.com/sfc-gh-miwhitaker/swiftclaw
*/

