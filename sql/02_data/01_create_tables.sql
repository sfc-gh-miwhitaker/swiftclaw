/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Database Tables
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create tables for storing document metadata, AI processing results, and
 *   business insights across all three schema layers.
 *
 * OBJECTS CREATED:
 *   RAW LAYER (3 tables):
 *   - RAW_DOCUMENT_CATALOG: Document metadata and stage paths
 *   - RAW_DOCUMENT_PROCESSING_LOG: Processing status tracking
 *   - RAW_DOCUMENT_ERRORS: Error tracking for failed processing
 *
 *   STAGING LAYER (4 tables):
 *   - STG_PARSED_DOCUMENTS: AI_PARSE_DOCUMENT results
 *   - STG_TRANSLATED_CONTENT: AI_TRANSLATE results
 *   - STG_CLASSIFIED_DOCS: AI_CLASSIFY results
 *   - STG_EXTRACTED_ENTITIES: AI_EXTRACT results
 *
 *   ANALYTICS LAYER (1 table + 1 view):
 *   - FCT_DOCUMENT_INSIGHTS: Aggregated business metrics
 *   - V_PROCESSING_METRICS: Pipeline monitoring view
 *
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2025-12-10 | Expires: 2026-01-09
 ******************************************************************************/

-- Set context (ensure ACCOUNTADMIN role for table creation)
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SWIFTCLAW;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- RAW LAYER: Document Catalog and Tracking
-- ============================================================================

-- Document Catalog: Metadata for all documents
CREATE OR REPLACE TABLE SWIFTCLAW.RAW_DOCUMENT_CATALOG (
    document_id STRING PRIMARY KEY,
    document_type STRING NOT NULL,  -- 'INVOICE', 'ROYALTY_STATEMENT', 'CONTRACT'
    stage_name STRING DEFAULT '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE',  -- Qualified stage
    file_path STRING NOT NULL,      -- Relative path within stage (e.g., 'invoices/invoice_001.pdf')
    file_name STRING NOT NULL,      -- Just the filename (e.g., 'invoice_001.pdf')
    file_format STRING DEFAULT 'PDF',
    file_size_bytes NUMBER,
    original_language STRING DEFAULT 'en',
    upload_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    processing_status STRING DEFAULT 'PENDING',  -- 'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'
    last_processed_at TIMESTAMP_NTZ,
    metadata VARIANT  -- Additional business metadata
)
COMMENT = 'DEMO: swiftclaw - Document catalog with stage paths | Expires: 2026-01-09 | Author: SE Community';

-- Processing Log: Track processing attempts and timing
CREATE OR REPLACE TABLE SWIFTCLAW.RAW_DOCUMENT_PROCESSING_LOG (
    log_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    document_id STRING NOT NULL,
    processing_step STRING NOT NULL,  -- 'PARSE', 'TRANSLATE', 'CLASSIFY', 'EXTRACT'
    started_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    completed_at TIMESTAMP_NTZ,
    duration_seconds NUMBER,
    status STRING,  -- 'SUCCESS', 'FAILED'
    error_message STRING
)
COMMENT = 'DEMO: swiftclaw - Processing audit log | Expires: 2026-01-09 | Author: SE Community';

-- Error Tracking: Detailed error information
CREATE OR REPLACE TABLE SWIFTCLAW.RAW_DOCUMENT_ERRORS (
    error_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    document_id STRING NOT NULL,
    error_step STRING NOT NULL,
    error_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    error_code STRING,
    error_message STRING,
    error_details VARIANT,
    retry_count NUMBER DEFAULT 0
)
COMMENT = 'DEMO: swiftclaw - Error tracking for failed processing | Expires: 2026-01-09 | Author: SE Community';

-- ============================================================================
-- STAGING LAYER: AI Processing Results
-- ============================================================================

-- Parsed Documents Table (AI_PARSE_DOCUMENT results)
CREATE OR REPLACE TRANSIENT TABLE SWIFTCLAW.STG_PARSED_DOCUMENTS (
    parsed_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    document_id STRING NOT NULL,
    parsed_content VARIANT NOT NULL,  -- Full JSON output from AI_PARSE_DOCUMENT
    extraction_mode STRING,  -- 'OCR' or 'LAYOUT'
    page_count NUMBER,
    confidence_score FLOAT,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    processing_duration_seconds NUMBER
)
COMMENT = 'DEMO: swiftclaw - AI_PARSE_DOCUMENT results | Expires: 2026-01-09 | Author: SE Community';

-- Translated Content Table (AI_TRANSLATE results)
CREATE OR REPLACE TRANSIENT TABLE SWIFTCLAW.STG_TRANSLATED_CONTENT (
    translation_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    parsed_id STRING NOT NULL,
    source_language STRING NOT NULL,
    target_language STRING DEFAULT 'en',
    source_text STRING,
    translated_text STRING NOT NULL,
    translation_confidence FLOAT,
    translated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: swiftclaw - AI_TRANSLATE results | Expires: 2026-01-09 | Author: SE Community';

-- Classified Documents Table (AI_CLASSIFY results)
CREATE OR REPLACE TRANSIENT TABLE SWIFTCLAW.STG_CLASSIFIED_DOCS (
    classification_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    parsed_id STRING NOT NULL,
    document_type STRING NOT NULL,  -- Predicted type
    priority_level STRING,  -- 'High', 'Medium', 'Low'
    business_category STRING,
    classification_confidence FLOAT,
    classification_details VARIANT,  -- Full AI_CLASSIFY response
    classified_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: swiftclaw - AI_CLASSIFY results | Expires: 2026-01-09 | Author: SE Community';

-- Extracted Entities Table (AI_EXTRACT results)
CREATE OR REPLACE TRANSIENT TABLE SWIFTCLAW.STG_EXTRACTED_ENTITIES (
    extraction_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    parsed_id STRING NOT NULL,
    entity_type STRING NOT NULL,  -- 'invoice_number', 'amount', 'vendor', etc.
    entity_value STRING NOT NULL,
    extraction_confidence FLOAT,
    extracted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: swiftclaw - AI_EXTRACT results | Expires: 2026-01-09 | Author: SE Community';

-- ============================================================================
-- ANALYTICS LAYER: Business Insights
-- ============================================================================

-- Document Insights Fact Table
CREATE OR REPLACE TABLE SWIFTCLAW.FCT_DOCUMENT_INSIGHTS (
    insight_id STRING PRIMARY KEY DEFAULT UUID_STRING(),
    document_id STRING NOT NULL,
    document_type STRING,
    total_amount FLOAT,
    currency STRING DEFAULT 'USD',
    document_date DATE,
    vendor_territory STRING,
    processing_time_seconds NUMBER,
    overall_confidence_score FLOAT,
    requires_manual_review BOOLEAN DEFAULT FALSE,
    manual_review_reason STRING,
    insight_created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    metadata VARIANT
)
COMMENT = 'DEMO: swiftclaw - Aggregated document insights | Expires: 2026-01-09 | Author: SE Community';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify all tables created (8 expected)
SHOW TABLES IN SCHEMA SWIFTCLAW;
