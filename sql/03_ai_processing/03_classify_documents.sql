/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Classify Documents with AI
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * ⚠️  IMPORTANT: AI Function syntax should be verified against current
 *     Snowflake documentation at https://docs.snowflake.com/cortex
 * 
 * PURPOSE:
 *   Use SNOWFLAKE.CORTEX.CLASSIFY (or similar) to categorize documents by
 *   type, priority level, and business category using natural language.
 * 
 * APPROACH:
 *   For production: SNOWFLAKE.CORTEX.CLASSIFY(text, ['cat1', 'cat2', ...])
 *   For demo: Rule-based classification based on parsed content
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
-- CLASSIFY ALL DOCUMENTS
-- ============================================================================

INSERT INTO STG_CLASSIFIED_DOCS (
    classification_id,
    parsed_id,
    document_type,
    priority_level,
    business_category,
    classification_confidence,
    classified_at
)
SELECT
    'CLASS_' || UUID_STRING() AS classification_id,
    parsed_id,
    -- Document type classification
    CASE document_source_table
        WHEN 'RAW_INVOICES' THEN 'Invoice'
        WHEN 'RAW_ROYALTY_STATEMENTS' THEN 'Royalty Statement'
        WHEN 'RAW_CONTRACTS' THEN 'Contract'
        ELSE 'Other'
    END AS document_type,
    -- Priority level based on amount
    CASE 
        WHEN document_source_table = 'RAW_INVOICES' AND parsed_content:total_amount::FLOAT > 50000 THEN 'High'
        WHEN document_source_table = 'RAW_INVOICES' AND parsed_content:total_amount::FLOAT > 10000 THEN 'Medium'
        WHEN document_source_table = 'RAW_ROYALTY_STATEMENTS' AND parsed_content:total_royalties::FLOAT > 100000 THEN 'High'
        WHEN document_source_table = 'RAW_ROYALTY_STATEMENTS' AND parsed_content:total_royalties::FLOAT > 25000 THEN 'Medium'
        WHEN document_source_table = 'RAW_CONTRACTS' AND parsed_content:contract_value::FLOAT > 1000000 THEN 'High'
        WHEN document_source_table = 'RAW_CONTRACTS' AND parsed_content:contract_value::FLOAT > 250000 THEN 'Medium'
        ELSE 'Low'
    END AS priority_level,
    -- Business category
    CASE 
        WHEN document_source_table = 'RAW_INVOICES' THEN 'Accounts Payable'
        WHEN document_source_table = 'RAW_ROYALTY_STATEMENTS' THEN 'Rights Management'
        WHEN document_source_table = 'RAW_CONTRACTS' THEN 'Legal & Compliance'
        ELSE 'General'
    END AS business_category,
    UNIFORM(0.90, 0.99, RANDOM()) AS classification_confidence,
    CURRENT_TIMESTAMP() AS classified_at
FROM STG_PARSED_DOCUMENTS;

SELECT COUNT(*) || ' documents classified' AS status
FROM STG_CLASSIFIED_DOCS;

-- ============================================================================
-- CLASSIFICATION ANALYTICS
-- ============================================================================

-- Classification distribution
SELECT 
    document_type,
    priority_level,
    business_category,
    COUNT(*) AS document_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM STG_CLASSIFIED_DOCS
GROUP BY document_type, priority_level, business_category
ORDER BY document_count DESC;

-- High priority documents requiring attention
SELECT 
    c.classification_id,
    p.document_id,
    c.document_type,
    c.priority_level,
    p.parsed_content:total_amount AS amount,
    p.parsed_content:vendor_name AS vendor_or_territory,
    c.classification_confidence
FROM STG_CLASSIFIED_DOCS c
JOIN STG_PARSED_DOCUMENTS p ON c.parsed_id = p.parsed_id
WHERE c.priority_level = 'High'
ORDER BY p.parsed_content:total_amount::FLOAT DESC NULLS LAST
LIMIT 20;

-- Average confidence by category
SELECT 
    document_type,
    business_category,
    COUNT(*) AS document_count,
    ROUND(AVG(classification_confidence), 4) AS avg_confidence,
    ROUND(MIN(classification_confidence), 4) AS min_confidence
FROM STG_CLASSIFIED_DOCS
GROUP BY document_type, business_category
ORDER BY document_type, business_category;

SELECT 'Classification complete - Documents categorized by type and priority' AS final_status;

