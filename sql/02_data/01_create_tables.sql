/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Database Tables
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create tables for storing raw documents, AI processing results, and
 *   business insights across all three schema layers.
 * 
 * OBJECTS CREATED:
 *   RAW LAYER (3 tables):
 *   - RAW_INVOICES: Vendor invoice PDFs
 *   - RAW_ROYALTY_STATEMENTS: Royalty payment statements
 *   - RAW_CONTRACTS: Entertainment industry contracts
 * 
 *   STAGING LAYER (3 tables):
 *   - STG_PARSED_DOCUMENTS: AI_PARSE_DOCUMENT results
 *   - STG_TRANSLATED_CONTENT: AI_TRANSLATE results
 *   - STG_CLASSIFIED_DOCS: AI_FILTER results
 * 
 *   ANALYTICS LAYER (1 table):
 *   - FCT_DOCUMENT_INSIGHTS: Aggregated business metrics
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- RAW LAYER: Binary Document Storage
-- ============================================================================

-- Raw Invoices Table
CREATE OR REPLACE TABLE SFE_RAW_ENTERTAINMENT.RAW_INVOICES (
    document_id STRING PRIMARY KEY,
    pdf_content BINARY,
    vendor_name STRING,
    upload_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    original_language STRING DEFAULT 'en',
    file_format STRING DEFAULT 'PDF',
    file_size_bytes NUMBER,
    processed_flag BOOLEAN DEFAULT FALSE,
    metadata VARIANT
) COMMENT = 'DEMO: swiftclaw - Raw vendor invoice documents | Expires: 2025-12-24 | Author: SE Community';

-- Raw Royalty Statements Table
CREATE OR REPLACE TABLE SFE_RAW_ENTERTAINMENT.RAW_ROYALTY_STATEMENTS (
    document_id STRING PRIMARY KEY,
    pdf_content BINARY,
    territory STRING,
    period_start_date DATE,
    period_end_date DATE,
    upload_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    original_language STRING DEFAULT 'en',
    file_format STRING DEFAULT 'PDF',
    processed_flag BOOLEAN DEFAULT FALSE,
    metadata VARIANT
) COMMENT = 'DEMO: swiftclaw - Raw royalty payment statements | Expires: 2025-12-24 | Author: SE Community';

-- Raw Contracts Table
CREATE OR REPLACE TABLE SFE_RAW_ENTERTAINMENT.RAW_CONTRACTS (
    document_id STRING PRIMARY KEY,
    pdf_content BINARY,
    contract_type STRING,
    effective_date DATE,
    upload_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    original_language STRING DEFAULT 'en',
    file_format STRING DEFAULT 'PDF',
    contains_sensitive_info BOOLEAN DEFAULT TRUE,
    processed_flag BOOLEAN DEFAULT FALSE,
    metadata VARIANT
) COMMENT = 'DEMO: swiftclaw - Raw entertainment industry contracts | Expires: 2025-12-24 | Author: SE Community';

SELECT 'Raw layer tables created: 3 tables' AS status;

-- ============================================================================
-- STAGING LAYER: AI Processing Results
-- ============================================================================

-- Parsed Documents Table (AI_PARSE_DOCUMENT results)
CREATE OR REPLACE TRANSIENT TABLE SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS (
    parsed_id STRING PRIMARY KEY,
    document_id STRING NOT NULL,
    parsed_content VARIANT,  -- JSON output from AI_PARSE_DOCUMENT
    extraction_method STRING DEFAULT 'AI_PARSE_DOCUMENT',
    confidence_score FLOAT,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    document_source_table STRING  -- 'RAW_INVOICES', 'RAW_ROYALTY_STATEMENTS', etc.
) COMMENT = 'DEMO: swiftclaw - AI parsed document content | Expires: 2025-12-24 | Author: SE Community';

-- Translated Content Table (AI_TRANSLATE results)
CREATE OR REPLACE TRANSIENT TABLE SFE_STG_ENTERTAINMENT.STG_TRANSLATED_CONTENT (
    translation_id STRING PRIMARY KEY,
    parsed_id STRING NOT NULL,
    source_language STRING,
    target_language STRING DEFAULT 'en',
    translated_content VARIANT,  -- JSON with translated text
    translation_confidence FLOAT,
    translated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'DEMO: swiftclaw - AI translated content | Expires: 2025-12-24 | Author: SE Community';

-- Classified Documents Table (AI_FILTER results)
CREATE OR REPLACE TRANSIENT TABLE SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS (
    classification_id STRING PRIMARY KEY,
    parsed_id STRING NOT NULL,
    document_type STRING,  -- 'Invoice', 'Royalty Statement', 'Contract', 'Other'
    priority_level STRING,  -- 'High', 'Medium', 'Low'
    business_category STRING,
    classification_confidence FLOAT,
    classified_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'DEMO: swiftclaw - AI classified documents | Expires: 2025-12-24 | Author: SE Community';

SELECT 'Staging layer tables created: 3 transient tables' AS status;

-- ============================================================================
-- ANALYTICS LAYER: Business Insights
-- ============================================================================

-- Document Insights Fact Table
CREATE OR REPLACE TABLE SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS (
    insight_id STRING PRIMARY KEY,
    document_id STRING NOT NULL,
    document_type STRING,
    total_amount FLOAT,
    currency STRING DEFAULT 'USD',
    document_date DATE,
    vendor_territory STRING,
    processing_time_seconds NUMBER,
    confidence_score FLOAT,
    requires_manual_review BOOLEAN DEFAULT FALSE,
    insight_created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    metadata VARIANT
) COMMENT = 'DEMO: swiftclaw - Aggregated document insights | Expires: 2025-12-24 | Author: SE Community';

SELECT 'Analytics layer tables created: 1 fact table' AS status;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant SELECT on raw tables
GRANT SELECT ON ALL TABLES IN SCHEMA SFE_RAW_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;

-- Grant SELECT, INSERT, UPDATE on staging tables
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA SFE_STG_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;

-- Grant SELECT on analytics tables
GRANT SELECT ON ALL TABLES IN SCHEMA SFE_ANALYTICS_ENTERTAINMENT TO ROLE SFE_DEMO_ROLE;

SELECT 'Permissions granted to SFE_DEMO_ROLE' AS status;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- List all tables created
SHOW TABLES IN SCHEMA SFE_RAW_ENTERTAINMENT;
SHOW TABLES IN SCHEMA SFE_STG_ENTERTAINMENT;
SHOW TABLES IN SCHEMA SFE_ANALYTICS_ENTERTAINMENT;

SELECT 'Table creation complete - 7 tables created' AS final_status;

