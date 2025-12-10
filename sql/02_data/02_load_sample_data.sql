/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Load Sample Data
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Generate realistic sample documents and upload metadata to catalog.
 *   Documents are created as text files to demonstrate AI Functions workflow.
 *
 * APPROACH:
 *   1. Generate sample document content as text
 *   2. PUT files to internal stage (via SQL)
 *   3. Catalog document metadata
 *
 * NOTE: For production demos with real PDFs, use PUT command or Snowsight UI:
 *   PUT file:///*.pdf @SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE AUTO_COMPRESS=FALSE;
 *
 * DATA GENERATED:
 *   - 10 sample invoices (mixed English/Spanish)
 *   - 5 sample royalty statements (multi-territory)
 *   - 5 sample contracts
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
-- SAMPLE DOCUMENT GENERATION: Invoices
-- ============================================================================

-- Generate 10 sample invoices with realistic content
INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
SELECT
    'INV_' || LPAD(seq, 6, '0') AS document_id,
    'INVOICE' AS document_type,
    '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE' AS stage_name,
    'invoices/invoice_' || LPAD(seq, 6, '0') || '.txt' AS file_path,
    'invoice_' || LPAD(seq, 6, '0') || '.txt' AS file_name,
    'TXT' AS file_format,  -- Using TXT for demo; production would use PDF
    UNIFORM(2048, 8192, rnd) AS file_size_bytes,
    CASE WHEN seq <= 8 THEN 'en' ELSE 'es' END AS original_language,
    'PENDING' AS processing_status,
    OBJECT_CONSTRUCT(
        'vendor_name', ARRAY_CONSTRUCT('Acme Production Services', 'Global Studios Inc', 'MediaTech Solutions', 'Film Finance Co', 'Post House LLC')[UNIFORM(0, 4, RANDOM())],
        'invoice_number', 'INV-2024-' || LPAD(seq, 6, '0'),
        'invoice_date', DATEADD(day, -UNIFORM(0, 180, rnd), CURRENT_DATE()),
        'amount', UNIFORM(5000, 150000, rnd),
        'currency', 'USD',
        'payment_terms', 'Net 30',
        'generated_for_demo', TRUE
    ) AS metadata
FROM (
    SELECT
        SEQ4() AS seq,
        RANDOM() AS rnd
    FROM TABLE(GENERATOR(ROWCOUNT => 10))
) invoice_gen;

-- Create sample invoice content files
-- NOTE: In production, you would PUT actual PDF files here
-- For demo purposes, we'll create the metadata and let AI functions work with stage paths

SELECT '10 invoice documents cataloged' AS status;

-- ============================================================================
-- SAMPLE DOCUMENT GENERATION: Royalty Statements
-- ============================================================================

INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
SELECT
    'ROY_' || LPAD(seq, 6, '0') AS document_id,
    'ROYALTY_STATEMENT' AS document_type,
    '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE' AS stage_name,
    'royalty/royalty_' || LPAD(seq, 6, '0') || '.txt' AS file_path,
    'royalty_' || LPAD(seq, 6, '0') || '.txt' AS file_name,
    'TXT' AS file_format,
    UNIFORM(4096, 16384, rnd) AS file_size_bytes,
    'en' AS original_language,
    'PENDING' AS processing_status,
    OBJECT_CONSTRUCT(
        'territory', ARRAY_CONSTRUCT('North America', 'Europe', 'Asia Pacific', 'Latin America', 'United Kingdom')[UNIFORM(0, 4, rnd)],
        'period_start', CASE WHEN seq <= 3 THEN '2024-07-01'::DATE ELSE '2024-10-01'::DATE END,
        'period_end', CASE WHEN seq <= 3 THEN '2024-09-30'::DATE ELSE '2024-12-31'::DATE END,
        'total_royalties', UNIFORM(25000, 500000, rnd),
        'title_count', UNIFORM(50, 500, rnd),
        'currency', 'USD',
        'generated_for_demo', TRUE
    ) AS metadata
FROM (
    SELECT
        SEQ4() AS seq,
        RANDOM() AS rnd
    FROM TABLE(GENERATOR(ROWCOUNT => 5))
) royalty_gen;

SELECT '5 royalty statement documents cataloged' AS status;

-- ============================================================================
-- SAMPLE DOCUMENT GENERATION: Contracts
-- ============================================================================

INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
SELECT
    'CON_' || LPAD(seq, 6, '0') AS document_id,
    'CONTRACT' AS document_type,
    '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE' AS stage_name,
    'contracts/contract_' || LPAD(seq, 6, '0') || '.txt' AS file_path,
    'contract_' || LPAD(seq, 6, '0') || '.txt' AS file_name,
    'TXT' AS file_format,
    UNIFORM(8192, 32768, rnd) AS file_size_bytes,
    'en' AS original_language,
    'PENDING' AS processing_status,
    OBJECT_CONSTRUCT(
        'contract_type', ARRAY_CONSTRUCT('Production Agreement', 'Distribution License', 'Talent Agreement', 'Music Licensing', 'Merchandising Rights')[UNIFORM(0, 4, rnd)],
        'effective_date', DATEADD(month, -UNIFORM(0, 36, rnd), CURRENT_DATE()),
        'party_b', ARRAY_CONSTRUCT('Acme Studios', 'Star Talent Agency', 'Distribution Partners LLC', 'Music Rights Corp', 'Global Licensing Inc')[UNIFORM(0, 4, rnd)],
        'contract_value', UNIFORM(50000, 5000000, rnd),
        'term_years', UNIFORM(1, 5, rnd),
        'territory', ARRAY_CONSTRUCT('Worldwide', 'North America', 'Europe', 'Asia', 'Latin America')[UNIFORM(0, 4, rnd)],
        'generated_for_demo', TRUE
    ) AS metadata
FROM (
    SELECT
        SEQ4() AS seq,
        RANDOM() AS rnd
    FROM TABLE(GENERATOR(ROWCOUNT => 5))
) contract_gen;

SELECT '5 contract documents cataloged' AS status;

-- ============================================================================
-- CREATE SAMPLE DOCUMENT CONTENT FILES
-- ============================================================================

-- For this demo, we'll create inline sample content
-- In production, you would upload real PDF/DOCX files to the stage

-- Sample Invoice Content Template
CREATE OR REPLACE TEMPORARY TABLE sample_invoice_content AS
SELECT
    document_id,
    metadata:invoice_number::STRING AS invoice_number,
    metadata:vendor_name::STRING AS vendor_name,
    metadata:invoice_date::DATE AS invoice_date,
    metadata:amount::NUMBER AS amount,
    -- Generate realistic invoice text
    'INVOICE\n\n' ||
    'Vendor: ' || metadata:vendor_name::STRING || '\n' ||
    'Invoice Number: ' || metadata:invoice_number::STRING || '\n' ||
    'Date: ' || metadata:invoice_date::STRING || '\n' ||
    'Amount Due: $' || metadata:amount::STRING || ' USD\n' ||
    'Payment Terms: Net 30\n\n' ||
    'LINE ITEMS:\n' ||
    '1. Production Services - $' || (metadata:amount::NUMBER * 0.60)::STRING || '\n' ||
    '2. Post-Production - $' || (metadata:amount::NUMBER * 0.30)::STRING || '\n' ||
    '3. Miscellaneous Fees - $' || (metadata:amount::NUMBER * 0.10)::STRING || '\n\n' ||
    'TOTAL: $' || metadata:amount::STRING || ' USD\n\n' ||
    'Please remit payment to:\n' ||
    'Global Media Corp\n' ||
    'Account: 1234567890\n' ||
    'Due Date: ' || DATEADD(day, 30, metadata:invoice_date::DATE)::STRING AS document_content
FROM RAW_DOCUMENT_CATALOG
WHERE document_type = 'INVOICE';

-- Note: In a real implementation, you would PUT these files to the stage:
-- PUT 'file://path/to/invoice.pdf' @DOCUMENT_STAGE/invoices/ AUTO_COMPRESS=FALSE;

-- For this demo, the document content is available in the temp table
-- AI functions will be called with stage paths once files are uploaded

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check catalog summary
SELECT
    document_type,
    COUNT(*) AS document_count,
    COUNT(DISTINCT original_language) AS language_count,
    AVG(file_size_bytes) AS avg_file_size_bytes,
    processing_status
FROM RAW_DOCUMENT_CATALOG
GROUP BY document_type, processing_status
ORDER BY document_type;

-- Sample document details
SELECT
    document_id,
    document_type,
    file_name,
    original_language,
    processing_status,
    metadata:vendor_name::STRING AS vendor_or_party,
    metadata:amount::NUMBER AS amount
FROM RAW_DOCUMENT_CATALOG
LIMIT 10;

SELECT 'Sample data loading complete - 20 documents cataloged' AS final_status;

-- ============================================================================
-- INSTRUCTIONS FOR REAL PDF UPLOAD
-- ============================================================================

/*
TO USE WITH REAL PDF DOCUMENTS:

1. Prepare your PDF files locally in this structure:
   documents/
     invoices/
       invoice_001.pdf
       invoice_002.pdf
     royalty/
       royalty_001.pdf
     contracts/
       contract_001.pdf

2. Upload to Snowflake stage using SnowSQL:
   PUT file://documents/invoices/*.pdf @SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE/invoices/ AUTO_COMPRESS=FALSE;
   PUT file://documents/royalty/*.pdf @SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE/royalty/ AUTO_COMPRESS=FALSE;
   PUT file://documents/contracts/*.pdf @SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE/contracts/ AUTO_COMPRESS=FALSE;

3. Verify upload:
   LS @SNOWFLAKE_EXAMPLE.SFE_RAW_ENTERTAINMENT.DOCUMENT_STAGE;

4. Update catalog with real file paths:
   UPDATE RAW_DOCUMENT_CATALOG
   SET file_format = 'PDF',
       file_path = 'invoices/' || file_name
   WHERE document_type = 'INVOICE';

5. Proceed to AI processing scripts to parse documents
*/
