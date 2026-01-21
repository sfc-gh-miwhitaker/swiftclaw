/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Database Schemas
 *
 * NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create project schema and internal stage for AI document processing.
 *   Dynamic Tables and views are created by the AI pipeline script.
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SWIFTCLAW (schema)
 *
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2026-01-21 | Expires: 2026-02-08
 ******************************************************************************/

-- Set context (ensure ACCOUNTADMIN role for schema creation)
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- PROJECT SCHEMA
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SWIFTCLAW
    DATA_RETENTION_TIME_IN_DAYS = 7
    COMMENT = 'DEMO: swiftclaw - Project schema (raw/staging/analytics layers) | Expires: 2026-02-08 | Author: SE Community';

-- ============================================================================
-- DOCUMENT STAGE: Storage for AI Processing
-- ============================================================================

-- Create internal stage for document files
-- AI_PARSE_DOCUMENT requires documents to be on a Snowflake stage
CREATE STAGE IF NOT EXISTS SWIFTCLAW.DOCUMENT_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')  -- Server-side encryption
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'DEMO: swiftclaw - Internal stage for document files (PDF, DOCX, etc.) | Expires: 2026-02-08 | Author: SE Community';

-- Verify stage created successfully
SHOW STAGES IN SCHEMA SWIFTCLAW;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify project schema created successfully
SHOW SCHEMAS LIKE 'SWIFTCLAW' IN DATABASE SNOWFLAKE_EXAMPLE;
