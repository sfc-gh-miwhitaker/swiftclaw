/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Load Sample Data
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Generate realistic sample documents for demo purposes using Snowflake's
 *   GENERATOR function. Creates synthetic invoices, royalty statements, and
 *   contracts for Global Media Corp (fictional entertainment company).
 * 
 * DATA GENERATED:
 *   - 500 sample invoices (mixed languages: English, Spanish)
 *   - 300 sample royalty statements (multi-territory, Q3-Q4 2024)
 *   - 50 sample contracts (various types)
 * 
 * NOTE: Binary PDF content is simulated as text strings since we're generating
 *       synthetic data. In production, these would be actual binary PDFs loaded
 *       from external storage (S3, Azure Blob, GCS).
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SFE_RAW_ENTERTAINMENT;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- SAMPLE INVOICES (500 rows)
-- ============================================================================

INSERT INTO RAW_INVOICES (
    document_id,
    pdf_content,
    vendor_name,
    upload_date,
    original_language,
    file_format,
    file_size_bytes,
    processed_flag,
    metadata
)
SELECT
    'INV_' || UUID_STRING() AS document_id,
    TO_BINARY(
        'INVOICE\n' ||
        'Vendor: ' || vendor_name || '\n' ||
        'Invoice #: ' || invoice_number || '\n' ||
        'Date: ' || invoice_date || '\n' ||
        'Amount: $' || amount || ' USD\n' ||
        'Payment Terms: Net 30\n' ||
        '---\n' ||
        'Items:\n' ||
        '- Production Services: $' || (amount * 0.60) || '\n' ||
        '- Post-Production: $' || (amount * 0.30) || '\n' ||
        '- Miscellaneous: $' || (amount * 0.10) || '\n' ||
        '---\n' ||
        'Please remit payment to: Global Media Corp\n' ||
        'Account: 1234567890\n'
    ) AS pdf_content,
    vendor_name,
    invoice_date AS upload_date,
    original_language,
    'PDF' AS file_format,
    UNIFORM(1024, 102400, RANDOM()) AS file_size_bytes,
    FALSE AS processed_flag,
    OBJECT_CONSTRUCT(
        'invoice_number', invoice_number,
        'amount', amount,
        'currency', 'USD',
        'payment_terms', 'Net 30',
        'generated_for_demo', TRUE
    ) AS metadata
FROM (
    SELECT
        CASE 
            WHEN seq <= 400 THEN ARRAY_CONSTRUCT('Acme Production Services', 'Global Studios Inc', 'MediaTech Solutions', 'Film Finance Co', 'Post House LLC', 'Sound Design Group', 'VFX Masters', 'Lighting Specialists', 'Equipment Rentals Inc', 'Catering Services Corp')[UNIFORM(0, 9, RANDOM())]
            ELSE ARRAY_CONSTRUCT('Servicios de Producción SA', 'Estudios Globales', 'Soluciones MediaTech', 'Finanzas Cinematográficas', 'Casa de Post-Producción')[UNIFORM(0, 4, RANDOM())]
        END AS vendor_name,
        'INV-2024-' || LPAD(seq, 6, '0') AS invoice_number,
        DATEADD(day, -UNIFORM(0, 180, RANDOM()), CURRENT_DATE()) AS invoice_date,
        CASE WHEN seq <= 400 THEN 'en' ELSE 'es' END AS original_language,
        UNIFORM(5000, 150000, RANDOM()) AS amount,
        seq
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
);

SELECT '500 sample invoices loaded' AS status;

-- ============================================================================
-- SAMPLE ROYALTY STATEMENTS (300 rows)
-- ============================================================================

INSERT INTO RAW_ROYALTY_STATEMENTS (
    document_id,
    pdf_content,
    territory,
    period_start_date,
    period_end_date,
    upload_date,
    original_language,
    file_format,
    processed_flag,
    metadata
)
SELECT
    'ROY_' || UUID_STRING() AS document_id,
    TO_BINARY(
        'ROYALTY STATEMENT\n' ||
        'Territory: ' || territory || '\n' ||
        'Period: ' || period_start_date || ' to ' || period_end_date || '\n' ||
        'Total Royalties: $' || total_royalties || ' USD\n' ||
        '---\n' ||
        'Title Performance:\n' ||
        '- Title A: ' || title_count || ' units, $' || (total_royalties * 0.40) || '\n' ||
        '- Title B: ' || (title_count * 0.8) || ' units, $' || (total_royalties * 0.35) || '\n' ||
        '- Title C: ' || (title_count * 0.5) || ' units, $' || (total_royalties * 0.25) || '\n' ||
        '---\n' ||
        'Payment Due: ' || payment_due_date || '\n' ||
        'Remit to: Global Media Corp Rights Management\n'
    ) AS pdf_content,
    territory,
    period_start_date,
    period_end_date,
    CURRENT_TIMESTAMP() AS upload_date,
    'en' AS original_language,
    'PDF' AS file_format,
    FALSE AS processed_flag,
    OBJECT_CONSTRUCT(
        'total_royalties', total_royalties,
        'title_count', title_count,
        'currency', 'USD',
        'payment_due_date', payment_due_date,
        'generated_for_demo', TRUE
    ) AS metadata
FROM (
    SELECT
        ARRAY_CONSTRUCT('North America', 'Europe', 'Asia Pacific', 'Latin America', 'Middle East', 'Africa', 'United Kingdom', 'Australia', 'Japan', 'China')[UNIFORM(0, 9, RANDOM())] AS territory,
        CASE 
            WHEN seq <= 150 THEN '2024-07-01'::DATE
            ELSE '2024-10-01'::DATE
        END AS period_start_date,
        CASE 
            WHEN seq <= 150 THEN '2024-09-30'::DATE
            ELSE '2024-12-31'::DATE
        END AS period_end_date,
        UNIFORM(25000, 500000, RANDOM()) AS total_royalties,
        UNIFORM(100, 10000, RANDOM()) AS title_count,
        DATEADD(day, 30, period_end_date) AS payment_due_date,
        seq
    FROM TABLE(GENERATOR(ROWCOUNT => 300))
);

SELECT '300 sample royalty statements loaded' AS status;

-- ============================================================================
-- SAMPLE CONTRACTS (50 rows)
-- ============================================================================

INSERT INTO RAW_CONTRACTS (
    document_id,
    pdf_content,
    contract_type,
    effective_date,
    upload_date,
    original_language,
    file_format,
    contains_sensitive_info,
    processed_flag,
    metadata
)
SELECT
    'CON_' || UUID_STRING() AS document_id,
    TO_BINARY(
        'ENTERTAINMENT SERVICES CONTRACT\n' ||
        'Contract Type: ' || contract_type || '\n' ||
        'Effective Date: ' || effective_date || '\n' ||
        'Term: ' || term_years || ' years\n' ||
        'Party A: Global Media Corp\n' ||
        'Party B: ' || party_b_name || '\n' ||
        '---\n' ||
        'TERMS AND CONDITIONS\n' ||
        '1. Services to be provided as outlined in Exhibit A\n' ||
        '2. Compensation: $' || contract_value || ' USD\n' ||
        '3. Payment Schedule: ' || payment_schedule || '\n' ||
        '4. Confidentiality provisions apply\n' ||
        '5. Territory: ' || territory || '\n' ||
        '---\n' ||
        '[Additional terms and conditions would appear here]\n' ||
        '[Signature pages would follow]\n'
    ) AS pdf_content,
    contract_type,
    effective_date,
    CURRENT_TIMESTAMP() AS upload_date,
    'en' AS original_language,
    'PDF' AS file_format,
    TRUE AS contains_sensitive_info,
    FALSE AS processed_flag,
    OBJECT_CONSTRUCT(
        'party_b_name', party_b_name,
        'contract_value', contract_value,
        'term_years', term_years,
        'territory', territory,
        'payment_schedule', payment_schedule,
        'generated_for_demo', TRUE
    ) AS metadata
FROM (
    SELECT
        ARRAY_CONSTRUCT('Production Agreement', 'Distribution License', 'Talent Agreement', 'Music Licensing', 'Merchandising Rights')[UNIFORM(0, 4, RANDOM())] AS contract_type,
        DATEADD(month, -UNIFORM(0, 36, RANDOM()), CURRENT_DATE()) AS effective_date,
        ARRAY_CONSTRUCT('Acme Studios', 'Star Talent Agency', 'Distribution Partners LLC', 'Music Rights Corp', 'Global Licensing Inc', 'Production House SA', 'Talent Management Group', 'Rights Acquisition Co')[UNIFORM(0, 7, RANDOM())] AS party_b_name,
        UNIFORM(50000, 5000000, RANDOM()) AS contract_value,
        UNIFORM(1, 5, RANDOM()) AS term_years,
        ARRAY_CONSTRUCT('Worldwide', 'North America', 'Europe', 'Asia', 'Latin America')[UNIFORM(0, 4, RANDOM())] AS territory,
        ARRAY_CONSTRUCT('Monthly', 'Quarterly', 'Annual', 'Milestone-based', 'Net 30')[UNIFORM(0, 4, RANDOM())] AS payment_schedule,
        seq
    FROM TABLE(GENERATOR(ROWCOUNT => 50))
);

SELECT '50 sample contracts loaded' AS status;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check row counts
SELECT 'RAW_INVOICES' AS table_name, COUNT(*) AS row_count FROM RAW_INVOICES
UNION ALL
SELECT 'RAW_ROYALTY_STATEMENTS' AS table_name, COUNT(*) AS row_count FROM RAW_ROYALTY_STATEMENTS
UNION ALL
SELECT 'RAW_CONTRACTS' AS table_name, COUNT(*) AS row_count FROM RAW_CONTRACTS;

-- Sample data preview
SELECT 
    'Sample Invoice' AS document_type,
    document_id,
    vendor_name,
    original_language,
    file_size_bytes,
    upload_date
FROM RAW_INVOICES
LIMIT 5;

SELECT 
    'Sample Royalty Statement' AS document_type,
    document_id,
    territory,
    period_start_date,
    period_end_date
FROM RAW_ROYALTY_STATEMENTS
LIMIT 5;

SELECT 
    'Sample Contract' AS document_type,
    document_id,
    contract_type,
    effective_date,
    contains_sensitive_info
FROM RAW_CONTRACTS
LIMIT 5;

SELECT 'Sample data loading complete - 850 total documents' AS final_status;

