/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 *
 * NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * DEMONSTRATION PROJECT - EXPIRES: 2026-02-20
 * This demo uses Snowflake AI Functions validated as of December 2025.
 * After expiration, this repository will be archived.
 *
 * DESIGNED FOR "RUN ALL" EXECUTION:
 *   1. Copy this entire script (Ctrl+A or Cmd+A to select all)
 *   2. Open Snowsight: https://app.snowflake.com
 *   3. Create new worksheet: Click "+" then "SQL Worksheet"
 *   4. Paste the entire script (Ctrl+V or Cmd+V)
 *   5. Click "Run All"
 *   6. Wait ~10 minutes - script executes all steps automatically
 *   7. No manual steps required
 *
 * WHAT THIS SCRIPT DOES:
 *   - Creates API integration for GitHub repository access
 *   - Creates Git repository stage with demo SQL scripts
 *   - Creates dedicated XSMALL warehouse for AI processing
 *   - Creates internal stage for document files (PDF, DOCX, etc.)
 *   - Copies sample PDFs into the internal stage
 *   - Creates Dynamic Table pipeline (catalog, parse, translate, enrich, insights)
 *   - Deploys Streamlit dashboard for document processing UI
 *
 * AI FUNCTIONS USED (All GA/Production-Ready):
 *   - AI_PARSE_DOCUMENT: Extract text, layout, and images from documents
 *   - AI_TRANSLATE: Translate multilingual content
 *   - AI_EXTRACT: Structured entity extraction directly from files
 *   - AI_CLASSIFY: Purpose-built document type classification
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
 *   - Or: DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;
 *   - Or: DROP WAREHOUSE SFE_DOCUMENT_AI_WH;
 *   - Or: DROP API INTEGRATION SFE_GIT_API_INTEGRATION;
 *
 * GitHub Repository: https://github.com/sfc-gh-miwhitaker/swiftclaw
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2026-02-17 | Expires: 2026-02-20 (30 days)
 ******************************************************************************/

-- ============================================================================
-- SECTION 0: EXPIRATION CHECK
-- ============================================================================

-- CRITICAL: Check if demo has expired (30 days from creation)
-- This raises an exception to halt Snowsight "Run All" when expired.
EXECUTE IMMEDIATE $$
DECLARE
    expires DATE DEFAULT '2026-02-20'::DATE;
    demo_expired EXCEPTION (-20001,
        'ERROR: This demo expired on 2026-02-20. Demo projects are maintained for 30 days only. Contact your Snowflake account team for an updated version.'
    );
BEGIN
    IF (CURRENT_DATE() >= expires) THEN
        RAISE demo_expired;
    END IF;
END;
$$;

-- Status banner for non-expired demos
SELECT
    CASE
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-02-20'::DATE) <= 7 THEN
            'WARNING: This demo expires in ' ||
            DATEDIFF('day', CURRENT_DATE(), '2026-02-20'::DATE) ||
            ' days (2026-02-20). Plan accordingly.'
        ELSE
            'Demo is active. Expires: 2026-02-20 (' ||
            DATEDIFF('day', CURRENT_DATE(), '2026-02-20'::DATE) ||
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
    COMMENT = 'DEMO: swiftclaw - Git integration for AI document processing demo | Expires: 2026-02-20 | Author: SE Community';

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
    COMMENT = 'DEMO: swiftclaw - AI Document Processing demo repository | Expires: 2026-02-20 | Author: SE Community';

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
    COMMENT = 'DEMO: swiftclaw - Dedicated warehouse for AI document processing | Expires: 2026-02-20 | Author: SE Community';

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

-- Set database context for stage grant
USE DATABASE SNOWFLAKE_EXAMPLE;

-- ============================================================================
-- SECTION 6: SETUP SCRIPTS (from Git Repository)
-- ============================================================================

-- Execute: Create schemas for raw, staging, analytics layers
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/01_setup/01_create_schemas.sql;

-- Idempotent guard: Ensure schema and stage exist before granting
-- (handles re-runs where prior cleanup dropped these objects)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW
    DATA_RETENTION_TIME_IN_DAYS = 7
    COMMENT = 'DEMO: swiftclaw - Project schema for dynamic tables | Expires: 2026-02-20 | Author: SE Community';

CREATE STAGE IF NOT EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'DEMO: swiftclaw - Internal stage for document files | Expires: 2026-02-20 | Author: SE Community';

-- Grant stage read/write (now guaranteed to exist)
GRANT READ, WRITE ON STAGE SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE TO ROLE SFE_DEMO_ROLE;

-- ============================================================================
-- SECTION 6b: COPY SAMPLE PDFs FROM GIT REPO TO INTERNAL STAGE
-- ============================================================================
-- COPY FILES transfers PDFs from Git repository to internal stage
-- This enables AI_PARSE_DOCUMENT to process real documents automatically

-- Copy generated sample documents (invoices, royalties, contracts)
-- NOTE: PATTERN matches full path from stage root, so must start with .*
COPY FILES
    INTO @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE/generated/
    FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/pdfs/generated/
    PATTERN = '.*\.pdf'
    DETAILED_OUTPUT = TRUE;

-- Copy bridge translation demo documents
-- NOTE: PATTERN matches full path, so must start with .*
COPY FILES
    INTO @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE/
    FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/pdfs/
    PATTERN = '.*bridge_.*\.pdf'
    DETAILED_OUTPUT = TRUE;

-- Verify files copied to internal stage
LS @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE/ PATTERN = '.*\.pdf';

-- Refresh stage directory table for catalog ingestion
ALTER STAGE SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE REFRESH;

-- ============================================================================
-- SECTION 7: DYNAMIC TABLE PIPELINE (from Git Repository)
-- ============================================================================
-- This script creates the catalog table, Dynamic Tables (all INCREMENTAL),
-- and monitoring view. All AI processing uses Dynamic Tables for automated
-- orchestration. New documents appear automatically once uploaded to the stage.

EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/03_ai_processing/01_create_dynamic_tables.sql;

-- ============================================================================
-- SECTION 8: STREAMLIT DASHBOARD
-- ============================================================================

-- Create Streamlit app from Git repository
-- NOTE: Using FROM clause (modern syntax) instead of legacy ROOT_LOCATION
--       FROM syntax supports multi-file editing and Git integration
CREATE OR REPLACE STREAMLIT SNOWFLAKE_EXAMPLE.SWIFTCLAW.SFE_DOCUMENT_DASHBOARD
    FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_DOCUMENT_AI_WH
    COMMENT = 'DEMO: swiftclaw - Interactive dashboard for document processing | Expires: 2026-02-20 | Author: SE Community';

-- Verify Streamlit app created successfully
SHOW STREAMLITS IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW;

-- ============================================================================
-- SECTION 9: FINALIZE ROLE PERMISSIONS
-- ============================================================================

-- Grant schema usage (single project schema)
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;

-- Grant table access (dynamic tables + views)
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;

-- Grant view access
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;

-- Grant Streamlit usage
GRANT USAGE ON STREAMLIT SNOWFLAKE_EXAMPLE.SWIFTCLAW.SFE_DOCUMENT_DASHBOARD TO ROLE SFE_DEMO_ROLE;

-- Grant role to SYSADMIN (for easier management)
GRANT ROLE SFE_DEMO_ROLE TO ROLE SYSADMIN;

/*******************************************************************************
 * SECTION 10: DEPLOYMENT COMPLETE
 *******************************************************************************
 *
 * Objects Created:
 *   - API Integration: SFE_GIT_API_INTEGRATION
 *   - Database: SNOWFLAKE_EXAMPLE
 *   - Warehouse: SFE_DOCUMENT_AI_WH (XSMALL)
 *   - Git Repository: sfe_swiftclaw_repo
 *   - Schema: SWIFTCLAW
 *   - Stage: DOCUMENT_STAGE (for file uploads)
 *   - Dynamic Tables: STG_PARSED_DOCUMENTS, STG_TRANSLATED_CONTENT,
 *     STG_ENRICHED_DOCUMENTS (AI_EXTRACT + AI_CLASSIFY), FCT_DOCUMENT_INSIGHTS
 *   - Views: RAW_DOCUMENT_CATALOG, V_PROCESSING_METRICS
 *   - All Dynamic Tables use REFRESH_MODE = INCREMENTAL for cost optimization
 *   - Streamlit: SFE_DOCUMENT_DASHBOARD
 *   - Role: SFE_DEMO_ROLE
 *
 * Next Steps:
 *   1. Upload documents to the stage (optional):
 *      PUT file:///*.pdf @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE AUTO_COMPRESS=FALSE;
 *   2. Switch role: USE ROLE SFE_DEMO_ROLE;
 *   3. Open Streamlit: Home -> Streamlit -> SFE_DOCUMENT_DASHBOARD
 *   4. View insights: SELECT * FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS LIMIT 10;
 *   5. View metrics: SELECT * FROM SWIFTCLAW.V_PROCESSING_METRICS;
 *
 * Documentation:
 *   - README: https://github.com/sfc-gh-miwhitaker/swiftclaw/blob/main/README.md
 *   - Usage Guide: docs/02-USAGE.md
 *   - Troubleshooting: docs/04-TROUBLESHOOTING.md
 *
 * Cleanup (when finished):
 *   EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.sfe_swiftclaw_repo/branches/main/sql/99_cleanup/teardown_all.sql;
 *   -- Or manual: DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SWIFTCLAW CASCADE;
 *   --            DROP WAREHOUSE IF EXISTS SFE_DOCUMENT_AI_WH;
 *
 * Demo Expires: 2026-02-20 (30 days from creation)
 ******************************************************************************/

-- Verify deployment: Show created objects
SHOW STREAMLITS LIKE 'SFE_DOCUMENT%' IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW;

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
