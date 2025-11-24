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

-- Use ACCOUNTADMIN for schema creation (already set in deploy_all.sql)
-- USE ROLE ACCOUNTADMIN;

-- Set database context
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
-- VERIFICATION
-- ============================================================================

-- Verify all SFE_* schemas created successfully
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE LIKE 'SFE_%';

