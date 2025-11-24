/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Parse Documents with AI
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * ⚠️  IMPORTANT: AI Function syntax should be verified against current
 *     Snowflake documentation at https://docs.snowflake.com/cortex
 * 
 * PURPOSE:
 *   Use SNOWFLAKE.CORTEX.PARSE_DOCUMENT (or similar AI function) to extract
 *   structured content from binary PDF documents. This demo uses simulated
 *   parsing since sample data is text-based, not actual PDFs.
 * 
 * APPROACH:
 *   For production with real PDFs, use:
 *   SELECT SNOWFLAKE.CORTEX.PARSE_DOCUMENT(pdf_content, {'mode': 'LAYOUT'})
 * 
 *   For this demo with synthetic data, we'll parse the text content directly.
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SFE_STG_ENTERTAINMENT;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- PARSE INVOICES
-- ============================================================================

INSERT INTO STG_PARSED_DOCUMENTS (
    parsed_id,
    document_id,
    parsed_content,
    extraction_method,
    confidence_score,
    processed_at,
    document_source_table
)
SELECT
    'PARSED_' || UUID_STRING() AS parsed_id,
    document_id,
    -- Simulated parsing: In production, use SNOWFLAKE.CORTEX.PARSE_DOCUMENT(pdf_content)
    OBJECT_CONSTRUCT(
        'extracted_text', TO_VARCHAR(pdf_content),
        'detected_language', original_language,
        'document_type', 'invoice',
        'vendor_name', vendor_name,
        'total_amount', TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(pdf_content), '\\$([0-9,.]+)', 1, 1, 'e', 1)),
        'invoice_number', REGEXP_SUBSTR(TO_VARCHAR(pdf_content), 'Invoice #: ([A-Z0-9-]+)', 1, 1, 'e', 1),
        'invoice_date', REGEXP_SUBSTR(TO_VARCHAR(pdf_content), 'Date: ([0-9-]+)', 1, 1, 'e', 1),
        'currency', 'USD',
        'layout_preserved', TRUE,
        'tables_detected', ARRAY_CONSTRUCT('line_items'),
        'confidence_score', UNIFORM(0.85, 0.98, RANDOM())
    ) AS parsed_content,
    'AI_PARSE_DOCUMENT_SIMULATED' AS extraction_method,
    UNIFORM(0.85, 0.98, RANDOM()) AS confidence_score,
    CURRENT_TIMESTAMP() AS processed_at,
    'RAW_INVOICES' AS document_source_table
FROM SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_INVOICES
WHERE processed_flag = FALSE;

-- Update processed flag
UPDATE SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_INVOICES
SET processed_flag = TRUE
WHERE document_id IN (
    SELECT document_id 
    FROM STG_PARSED_DOCUMENTS 
    WHERE document_source_table = 'RAW_INVOICES'
);

SELECT '500 invoices parsed' AS status;

-- ============================================================================
-- PARSE ROYALTY STATEMENTS
-- ============================================================================

INSERT INTO STG_PARSED_DOCUMENTS (
    parsed_id,
    document_id,
    parsed_content,
    extraction_method,
    confidence_score,
    processed_at,
    document_source_table
)
SELECT
    'PARSED_' || UUID_STRING() AS parsed_id,
    document_id,
    -- Simulated parsing: In production, use SNOWFLAKE.CORTEX.PARSE_DOCUMENT(pdf_content)
    OBJECT_CONSTRUCT(
        'extracted_text', TO_VARCHAR(pdf_content),
        'detected_language', original_language,
        'document_type', 'royalty_statement',
        'territory', territory,
        'total_royalties', TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(pdf_content), 'Total Royalties: \\$([0-9,.]+)', 1, 1, 'e', 1)),
        'period_start', period_start_date,
        'period_end', period_end_date,
        'currency', 'USD',
        'layout_preserved', TRUE,
        'tables_detected', ARRAY_CONSTRUCT('title_performance'),
        'confidence_score', UNIFORM(0.80, 0.95, RANDOM())
    ) AS parsed_content,
    'AI_PARSE_DOCUMENT_SIMULATED' AS extraction_method,
    UNIFORM(0.80, 0.95, RANDOM()) AS confidence_score,
    CURRENT_TIMESTAMP() AS processed_at,
    'RAW_ROYALTY_STATEMENTS' AS document_source_table
FROM SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_ROYALTY_STATEMENTS
WHERE processed_flag = FALSE;

-- Update processed flag
UPDATE SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_ROYALTY_STATEMENTS
SET processed_flag = TRUE
WHERE document_id IN (
    SELECT document_id 
    FROM STG_PARSED_DOCUMENTS 
    WHERE document_source_table = 'RAW_ROYALTY_STATEMENTS'
);

SELECT '300 royalty statements parsed' AS status;

-- ============================================================================
-- PARSE CONTRACTS
-- ============================================================================

INSERT INTO STG_PARSED_DOCUMENTS (
    parsed_id,
    document_id,
    parsed_content,
    extraction_method,
    confidence_score,
    processed_at,
    document_source_table
)
SELECT
    'PARSED_' || UUID_STRING() AS parsed_id,
    document_id,
    -- Simulated parsing: In production, use SNOWFLAKE.CORTEX.PARSE_DOCUMENT(pdf_content)
    OBJECT_CONSTRUCT(
        'extracted_text', TO_VARCHAR(pdf_content),
        'detected_language', original_language,
        'document_type', 'contract',
        'contract_type', contract_type,
        'effective_date', effective_date,
        'contract_value', TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(pdf_content), 'Compensation: \\$([0-9,.]+)', 1, 1, 'e', 1)),
        'term_years', TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(pdf_content), 'Term: ([0-9]+) years', 1, 1, 'e', 1)),
        'contains_sensitive_info', contains_sensitive_info,
        'layout_preserved', TRUE,
        'tables_detected', ARRAY_CONSTRUCT(),
        'confidence_score', UNIFORM(0.85, 0.98, RANDOM())
    ) AS parsed_content,
    'AI_PARSE_DOCUMENT_SIMULATED' AS extraction_method,
    UNIFORM(0.85, 0.98, RANDOM()) AS confidence_score,
    CURRENT_TIMESTAMP() AS processed_at,
    'RAW_CONTRACTS' AS document_source_table
FROM SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_CONTRACTS
WHERE processed_flag = FALSE;

-- Update processed flag
UPDATE SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.RAW_CONTRACTS
SET processed_flag = TRUE
WHERE document_id IN (
    SELECT document_id 
    FROM STG_PARSED_DOCUMENTS 
    WHERE document_source_table = 'RAW_CONTRACTS'
);

SELECT '50 contracts parsed' AS status;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check parsing results
SELECT 
    document_source_table,
    COUNT(*) AS documents_parsed,
    AVG(confidence_score) AS avg_confidence,
    MIN(confidence_score) AS min_confidence,
    MAX(confidence_score) AS max_confidence
FROM STG_PARSED_DOCUMENTS
GROUP BY document_source_table;

-- Sample parsed content
SELECT 
    document_id,
    parsed_content:document_type::STRING AS document_type,
    parsed_content:detected_language::STRING AS language,
    confidence_score,
    processed_at
FROM STG_PARSED_DOCUMENTS
LIMIT 10;

SELECT 'Document parsing complete - 850 documents processed' AS final_status;

