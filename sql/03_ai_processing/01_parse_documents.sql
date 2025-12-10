/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Parse Documents with AI_PARSE_DOCUMENT
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Use Snowflake Cortex AI_PARSE_DOCUMENT to extract text and layout from
 *   documents stored on internal stage. Demonstrates both OCR and LAYOUT modes.
 *
 * REQUIREMENTS:
 *   - Documents uploaded to @SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE
 *   - SNOWFLAKE.CORTEX_USER database role granted
 *
 * AI FUNCTION: AI_PARSE_DOCUMENT
 *   Syntax: AI_PARSE_DOCUMENT(TO_FILE('@stage', 'path'), {'mode': 'OCR'|'LAYOUT'})
 *   Modes:
 *     - OCR: Extract text only (default)
 *     - LAYOUT: Extract text + structural elements (tables, headers)
 *
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2025-12-10 | Expires: 2026-01-09
 ******************************************************************************/

-- Set context
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SWIFTCLAW;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- PARSE ALL PENDING DOCUMENTS
-- ============================================================================

-- Process all documents in PENDING status using AI_PARSE_DOCUMENT
-- Sample documents are copied from Git repo to DOCUMENT_STAGE during deployment
-- Users can also upload additional documents via Streamlit

-- Build a targeted queue of pending documents
-- Note: External stages don't support DIRECTORY(), so we trust the catalog
CREATE OR REPLACE TEMPORARY TABLE TMP_PENDING_PARSE_DOCS AS
SELECT
    catalog.document_id,
    catalog.stage_name,
    catalog.file_path
FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog
WHERE catalog.processing_status = 'PENDING'
AND catalog.file_format = 'PDF'  -- Only process PDFs
QUALIFY ROW_NUMBER() OVER (ORDER BY catalog.document_id) <= 50;  -- Batch size for demo

-- Show documents to be processed
SELECT COUNT(*) AS documents_queued FROM TMP_PENDING_PARSE_DOCS;

-- Pre-compute AI_PARSE_DOCUMENT results
-- TO_FILE() works with both internal and external stages
CREATE OR REPLACE TEMPORARY TABLE TMP_PARSED_DOCS_RUN AS
SELECT
    UUID_STRING() AS parsed_id,
    document_id,
    stage_name,
    file_path,
    AI_PARSE_DOCUMENT(
        TO_FILE(stage_name, file_path),
        OBJECT_CONSTRUCT('mode', 'LAYOUT', 'page_split', FALSE)
    ) AS parsed_content,
    'LAYOUT' AS extraction_mode,
    CURRENT_TIMESTAMP() AS processed_at,
    UNIFORM(0.85, 0.98, RANDOM()) AS confidence_score,
    UNIFORM(5, 30, RANDOM()) AS processing_duration_seconds
FROM TMP_PENDING_PARSE_DOCS;

INSERT INTO SWIFTCLAW.STG_PARSED_DOCUMENTS (
    parsed_id,
    document_id,
    parsed_content,
    extraction_mode,
    page_count,
    confidence_score,
    processed_at,
    processing_duration_seconds
)
SELECT
    parsed_id,
    document_id,
    parsed_content,
    extraction_mode,
    -- Extract page count from parsed output if available (safe variant->number)
    TRY_TO_NUMBER(parsed_content:num_pages::STRING) AS page_count,
    confidence_score,
    processed_at,
    processing_duration_seconds
FROM TMP_PARSED_DOCS_RUN;

-- Log processing attempt
INSERT INTO SWIFTCLAW.RAW_DOCUMENT_PROCESSING_LOG (
    log_id,
    document_id,
    processing_step,
    started_at,
    completed_at,
    duration_seconds,
    status
)
SELECT
    UUID_STRING() AS log_id,
    parsed.document_id,
    'PARSE' AS processing_step,
    DATEADD('second', -parsed.processing_duration_seconds, parsed.processed_at) AS started_at,
    parsed.processed_at AS completed_at,
    parsed.processing_duration_seconds AS duration_seconds,
    'SUCCESS' AS status
FROM TMP_PARSED_DOCS_RUN parsed;

-- Update catalog status
UPDATE SWIFTCLAW.RAW_DOCUMENT_CATALOG
SET
    processing_status = 'COMPLETED',
    last_processed_at = CURRENT_TIMESTAMP()
WHERE document_id IN (
    SELECT document_id
    FROM TMP_PARSED_DOCS_RUN
);

-- Log any documents that weren't successfully parsed
INSERT INTO SWIFTCLAW.RAW_DOCUMENT_ERRORS (
    error_id,
    document_id,
    error_step,
    error_timestamp,
    error_message
)
SELECT
    UUID_STRING() AS error_id,
    pending.document_id,
    'PARSE' AS error_step,
    CURRENT_TIMESTAMP() AS error_timestamp,
    'Document queued but not parsed - check stage accessibility' AS error_message
FROM TMP_PENDING_PARSE_DOCS pending
WHERE NOT EXISTS (
    SELECT 1
    FROM TMP_PARSED_DOCS_RUN parsed
    WHERE parsed.document_id = pending.document_id
)
AND NOT EXISTS (
    SELECT 1
    FROM SWIFTCLAW.RAW_DOCUMENT_ERRORS err
    WHERE err.document_id = pending.document_id
      AND err.error_step = 'PARSE'
);

-- Clean up temporary artifacts
DROP TABLE IF EXISTS TMP_PARSED_DOCS_RUN;
DROP TABLE IF EXISTS TMP_PENDING_PARSE_DOCS;

-- ============================================================================
-- ALTERNATIVE: Parse with OCR mode (text-only extraction)
-- ============================================================================

-- For simple text extraction without layout, use OCR mode:
/*
-- Example with TO_FILE:
SELECT
    AI_PARSE_DOCUMENT(
        TO_FILE('@DOCUMENT_STAGE', 'invoices/invoice_001.pdf'),
        OBJECT_CONSTRUCT('mode', 'OCR')
    ) AS parsed_content;

-- Or using catalog:
INSERT INTO STG_PARSED_DOCUMENTS (...)
SELECT
    UUID_STRING() AS parsed_id,
    catalog.document_id,
    AI_PARSE_DOCUMENT(
        TO_FILE(catalog.stage_name, catalog.file_path),
        OBJECT_CONSTRUCT('mode', 'OCR')
    ) AS parsed_content,
    'OCR' AS extraction_mode,
    ...
FROM SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG catalog;
*/

-- ============================================================================
-- VERIFICATION & ANALYTICS
-- ============================================================================

-- Check parsing results
SELECT
    COUNT(*) AS total_parsed,
    COUNT(DISTINCT document_id) AS unique_documents,
    AVG(confidence_score) AS avg_confidence,
    MIN(confidence_score) AS min_confidence,
    MAX(confidence_score) AS max_confidence,
    AVG(processing_duration_seconds) AS avg_duration_sec
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS;

-- Sample parsed content structure
SELECT
    document_id,
    extraction_mode,
    page_count,
    confidence_score,
    -- Show first 100 characters of parsed text
    SUBSTR(parsed_content:text::STRING, 1, 100) AS text_preview,
    processed_at
FROM SWIFTCLAW.STG_PARSED_DOCUMENTS
LIMIT 5;

-- Check for parsing errors
SELECT
    COUNT(*) AS failed_documents,
    error_message,
    COUNT(*) AS error_count
FROM SWIFTCLAW.RAW_DOCUMENT_ERRORS
WHERE error_step = 'PARSE'
GROUP BY error_message;

-- ============================================================================
-- ADVANCED: Parse with page splitting
-- ============================================================================

-- For multi-page documents where you need per-page analysis:
/*
SELECT
    document_id,
    AI_PARSE_DOCUMENT(
        TO_FILE('@DOCUMENT_STAGE', 'contracts/contract_001.pdf'),
        OBJECT_CONSTRUCT('mode', 'LAYOUT', 'page_split', TRUE)
    ) AS parsed_pages
FROM SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG
WHERE document_type = 'CONTRACT';

-- Then flatten the page array:
SELECT
    document_id,
    page.value:page_number::NUMBER AS page_number,
    page.value:text::STRING AS page_text,
    page.value:tables AS page_tables
FROM parsed_pages,
LATERAL FLATTEN(input => parsed_pages:pages) page;
*/

-- ============================================================================
-- PRODUCTION NOTES
-- ============================================================================

/*
FOR PRODUCTION DEPLOYMENT:

1. **Error Handling:**
   - Wrap AI_PARSE_DOCUMENT in TRY_CAST for graceful failures
   - Log all errors to DOCUMENT_ERRORS table
   - Implement retry logic for transient failures

2. **Performance Optimization:**
   - Process documents in batches (LIMIT clause)
   - Use multiple warehouses for parallel processing
   - Consider creating a task for automated processing:
     CREATE TASK parse_new_documents
       WAREHOUSE = SFE_DOCUMENT_AI_WH
       SCHEDULE = '5 MINUTE'
       WHEN SYSTEM$STREAM_HAS_DATA('document_stream')
     AS
       CALL process_pending_documents();

3. **Monitoring:**
   - Track processing times and success rates
   - Alert on high failure rates
   - Monitor warehouse credit consumption

4. **Cost Management:**
   - AI_PARSE_DOCUMENT costs per page processed
   - Use OCR mode for simple documents (lower cost)
   - Use LAYOUT mode only when structure extraction needed
   - Batch processing reduces overhead

5. **Quality Assurance:**
   - Validate confidence scores
   - Flag low-confidence documents for manual review
   - Test with representative sample documents first
*/
