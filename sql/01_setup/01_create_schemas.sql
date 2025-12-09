/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Database Schemas
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create three-layered schema architecture for AI document processing:
 *   - SFE_RAW_ENTERTAINMENT: Raw binary document storage
 *   - SFE_STG_ENTERTAINMENT: AI processing results (parsed, translated, classified)
 *   - SFE_ANALYTICS_ENTERTAINMENT: Business insights and metrics
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT (schema)
 *   - SNOWFLAKE_EXAMPLE.SFE_STG_ENTERTAINMENT (schema)
 *   - SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_ENTERTAINMENT (schema)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context (ensure ACCOUNTADMIN role for schema creation)
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

-- ============================================================================
-- RAW LAYER: Binary Document Storage
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SFE_RAW_ENTERTAINMENT
    DATA_RETENTION_TIME_IN_DAYS = 7  -- 7-day Time Travel for recovery
    COMMENT = 'DEMO: swiftclaw - Raw binary document storage layer | Expires: 2025-12-24 | Author: SE Community';

-- ============================================================================
-- STAGING LAYER: AI Processing Results
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SFE_STG_ENTERTAINMENT
    DATA_RETENTION_TIME_IN_DAYS = 1  -- 1-day Time Travel (transient data)
    COMMENT = 'DEMO: swiftclaw - AI processing results layer (parsed, translated, classified) | Expires: 2025-12-24 | Author: SE Community';

-- ============================================================================
-- ANALYTICS LAYER: Business Insights
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SFE_ANALYTICS_ENTERTAINMENT
    DATA_RETENTION_TIME_IN_DAYS = 7  -- 7-day Time Travel for business data
    COMMENT = 'DEMO: swiftclaw - Analytics layer for business insights and metrics | Expires: 2025-12-24 | Author: SE Community';

-- ============================================================================
-- DOCUMENT STAGE: Storage for AI Processing
-- ============================================================================

-- Create internal stage for document files
-- AI_PARSE_DOCUMENT requires documents to be on a Snowflake stage
CREATE STAGE IF NOT EXISTS SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')  -- Server-side encryption
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'DEMO: swiftclaw - Internal stage for document files (PDF, DOCX, etc.) | Expires: 2025-12-24 | Author: SE Community';

-- Verify stage created successfully
SHOW STAGES IN SCHEMA SFE_RAW_ENTERTAINMENT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify all SFE_* schemas created successfully
SHOW SCHEMAS LIKE 'SFE_%' IN DATABASE SNOWFLAKE_EXAMPLE;

