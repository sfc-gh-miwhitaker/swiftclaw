/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Extract Entities with AI_EXTRACT
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Use Snowflake Cortex AI_EXTRACT to intelligently extract specific entities
 *   from documents without regex patterns. Demonstrates semantic entity
 *   extraction for invoices, contracts, and royalty statements.
 *
 * REQUIREMENTS:
 *   - Parsed documents in STG_PARSED_DOCUMENTS
 *   - SNOWFLAKE.CORTEX_USER database role granted
 *
 * AI FUNCTION: AI_EXTRACT
 *   Syntax: AI_EXTRACT(text, entity_definitions)
 *   Benefits: No regex maintenance, handles format variations, semantic understanding
 *
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * Author: SE Community
 * Created: 2025-12-09 | Updated: 2025-12-10 | Expires: 2026-01-09
 ******************************************************************************/

-- Set context
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SWIFTCLAW;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- EXTRACT ENTITIES FROM INVOICES
-- ============================================================================

-- Extract structured data from invoice documents
INSERT INTO SWIFTCLAW.STG_EXTRACTED_ENTITIES (
    extraction_id,
    parsed_id,
    entity_type,
    entity_value,
    extraction_confidence,
    extracted_at
)
SELECT
    UUID_STRING() AS extraction_id,
    extractions.parsed_id,
    entity.key::STRING AS entity_type,
    entity.value::STRING AS entity_value,
    UNIFORM(0.85, 0.98, RANDOM()) AS extraction_confidence,  -- Simulated for demo
    CURRENT_TIMESTAMP() AS extracted_at
FROM (
    SELECT
        parsed.parsed_id,
        -- Extract multiple invoice fields in one call
        AI_EXTRACT(
            COALESCE(trans.translated_text, parsed.parsed_content:text::STRING),
            {
                'invoice_number': 'The unique identifier or invoice number for this billing document',
                'total_amount': 'The total amount due or payable in US dollars',
                'vendor_name': 'The name of the vendor, supplier, or company issuing the invoice',
                'invoice_date': 'The date when the invoice was issued',
                'due_date': 'The date when payment is due or expected',
                'payment_terms': 'The payment terms such as Net 30, Net 60, or Due Upon Receipt',
                'currency': 'The currency code for the amounts (USD, EUR, etc.)'
            }
        ) AS extracted_fields
    FROM SWIFTCLAW.STG_PARSED_DOCUMENTS parsed
    LEFT JOIN SWIFTCLAW.STG_TRANSLATED_CONTENT trans ON parsed.parsed_id = trans.parsed_id
    JOIN SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
    WHERE catalog.document_type = 'INVOICE'
    AND parsed.parsed_content:text::STRING IS NOT NULL
    LIMIT 50
) extractions,
LATERAL FLATTEN(input => extractions.extracted_fields) entity;

-- ============================================================================
-- EXTRACT ENTITIES FROM ROYALTY STATEMENTS
-- ============================================================================

-- Extract financial data from royalty statements
INSERT INTO SWIFTCLAW.STG_EXTRACTED_ENTITIES (
    extraction_id,
    parsed_id,
    entity_type,
    entity_value,
    extraction_confidence,
    extracted_at
)
SELECT
    UUID_STRING() AS extraction_id,
    extractions.parsed_id,
    entity.key::STRING AS entity_type,
    entity.value::STRING AS entity_value,
    UNIFORM(0.80, 0.95, RANDOM()) AS extraction_confidence,
    CURRENT_TIMESTAMP() AS extracted_at
FROM (
    SELECT
        parsed.parsed_id,
        AI_EXTRACT(
            COALESCE(trans.translated_text, parsed.parsed_content:text::STRING),
            {
                'territory': 'The geographic territory or region covered by this royalty statement',
                'period_start': 'The start date of the reporting period',
                'period_end': 'The end date of the reporting period',
                'total_royalties': 'The total royalty amount payable for this period',
                'currency': 'The currency for royalty payments',
                'title_count': 'The number of titles or products included in this statement',
                'payment_due_date': 'The date when royalty payment is due'
            }
        ) AS extracted_fields
    FROM SWIFTCLAW.STG_PARSED_DOCUMENTS parsed
    LEFT JOIN SWIFTCLAW.STG_TRANSLATED_CONTENT trans ON parsed.parsed_id = trans.parsed_id
    JOIN SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
    WHERE catalog.document_type = 'ROYALTY_STATEMENT'
    AND parsed.parsed_content:text::STRING IS NOT NULL
    LIMIT 50
) extractions,
LATERAL FLATTEN(input => extractions.extracted_fields) entity;

-- ============================================================================
-- EXTRACT ENTITIES FROM CONTRACTS
-- ============================================================================

-- Extract key contract terms and parties
INSERT INTO SWIFTCLAW.STG_EXTRACTED_ENTITIES (
    extraction_id,
    parsed_id,
    entity_type,
    entity_value,
    extraction_confidence,
    extracted_at
)
SELECT
    UUID_STRING() AS extraction_id,
    extractions.parsed_id,
    entity.key::STRING AS entity_type,
    entity.value::STRING AS entity_value,
    UNIFORM(0.85, 0.98, RANDOM()) AS extraction_confidence,
    CURRENT_TIMESTAMP() AS extracted_at
FROM (
    SELECT
        parsed.parsed_id,
        AI_EXTRACT(
            COALESCE(trans.translated_text, parsed.parsed_content:text::STRING),
            {
                'contract_type': 'The type or category of this contract (e.g., Production Agreement, Distribution License)',
                'effective_date': 'The date when this contract becomes effective or valid',
                'expiration_date': 'The date when this contract expires or terminates',
                'party_a': 'The name of the first party entering into this agreement',
                'party_b': 'The name of the second party entering into this agreement',
                'contract_value': 'The total monetary value or consideration of this contract',
                'territory': 'The geographic territory or region covered by this contract',
                'term_years': 'The duration or term of the contract in years'
            }
        ) AS extracted_fields
    FROM SWIFTCLAW.STG_PARSED_DOCUMENTS parsed
    LEFT JOIN SWIFTCLAW.STG_TRANSLATED_CONTENT trans ON parsed.parsed_id = trans.parsed_id
    JOIN SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
    WHERE catalog.document_type = 'CONTRACT'
    AND parsed.parsed_content:text::STRING IS NOT NULL
    LIMIT 50
) extractions,
LATERAL FLATTEN(input => extractions.extracted_fields) entity;

-- Log extraction attempts
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
    'EXTRACT' AS processing_step,
    extracted.extracted_at AS started_at,
    extracted.extracted_at AS completed_at,
    UNIFORM(2, 8, RANDOM()) AS duration_seconds,
    CASE
        WHEN extracted.entity_value IS NOT NULL THEN 'SUCCESS'
        ELSE 'FAILED'
    END AS status
FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES extracted
JOIN SWIFTCLAW.STG_PARSED_DOCUMENTS parsed ON extracted.parsed_id = parsed.parsed_id;

-- ============================================================================
-- VERIFICATION & ANALYTICS
-- ============================================================================

-- Entity extraction summary by type
SELECT
    entity_type,
    COUNT(*) AS extractions_count,
    COUNT(DISTINCT parsed_id) AS documents_processed,
    AVG(extraction_confidence) AS avg_confidence,
    MIN(extraction_confidence) AS min_confidence
FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES
GROUP BY entity_type
ORDER BY extractions_count DESC;

-- Sample extracted entities
SELECT
    catalog.document_type,
    entity.entity_type,
    entity.entity_value,
    entity.extraction_confidence
FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES entity
JOIN SWIFTCLAW.STG_PARSED_DOCUMENTS parsed ON entity.parsed_id = parsed.parsed_id
JOIN SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog ON parsed.document_id = catalog.document_id
LIMIT 20;

-- Invoice-specific entity analysis
SELECT
    parsed_id,
    MAX(CASE WHEN entity_type = 'invoice_number' THEN entity_value END) AS invoice_number,
    MAX(CASE WHEN entity_type = 'vendor_name' THEN entity_value END) AS vendor_name,
    MAX(CASE WHEN entity_type = 'total_amount' THEN entity_value END) AS total_amount,
    MAX(CASE WHEN entity_type = 'invoice_date' THEN entity_value END) AS invoice_date,
    MAX(CASE WHEN entity_type = 'payment_terms' THEN entity_value END) AS payment_terms
FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES
WHERE entity_type IN ('invoice_number', 'vendor_name', 'total_amount', 'invoice_date', 'payment_terms')
GROUP BY parsed_id
LIMIT 10;

-- Check extraction failures
SELECT
    COUNT(DISTINCT parsed_id) AS documents_processed,
    COUNT(DISTINCT CASE WHEN entity_value IS NULL THEN parsed_id END) AS failed_extractions
FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES;

-- ============================================================================
-- PRODUCTION NOTES
-- ============================================================================

/*
FOR PRODUCTION DEPLOYMENT:

1. **Entity Definitions:**
   - Provide clear, descriptive definitions for each entity
   - Be specific about formats (e.g., "in US dollars", "in YYYY-MM-DD format")
   - Test definitions with representative samples
   - Iterate on descriptions if extraction quality is low

2. **Advantages Over Regex:**
   - Handles format variations automatically
   - No pattern maintenance as document formats change
   - Extracts semantic meaning, not just pattern matching
   - Multi-field extraction in single API call
   - Works across different document layouts

3. **Performance Optimization:**
   - Batch extractions by document type (consistent entity definitions)
   - Extract only needed entities (don't over-extract)
   - Use parallel processing with multiple warehouses
   - Cache extraction results

4. **Error Handling:**
   - Wrap AI_EXTRACT in TRY_CAST for graceful failures
   - Log extraction failures
   - Implement fallback to regex patterns if needed
   - Set timeout limits for very long documents

5. **Quality Assurance:**
   - Validate extracted values (e.g., dates, amounts)
   - Flag low-confidence extractions for review
   - Compare AI_EXTRACT vs regex for your specific documents
   - Manual review of random sample

6. **Cost Management:**
   - AI_EXTRACT costs per extraction request
   - Extract once, store results (don't re-extract)
   - Combine related entities in single call
   - Consider rule-based extraction for simple, consistent patterns

7. **Post-Processing:**
   - Normalize extracted values (dates, amounts, names)
   - Validate against business rules
   - Aggregate entities for analytics
   - Flag anomalies (e.g., negative amounts, future dates)

8. **Integration:**
   - Join extracted entities back to source documents
   - Use extracted data to populate structured tables
   - Feed entities into downstream analytics
   - Export entities to ERP/CRM systems
*/
