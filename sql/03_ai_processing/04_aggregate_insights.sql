/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Aggregate Document Insights
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Combine parsed, translated, and classified document data into a single
 *   analytics fact table for business intelligence and reporting.
 * 
 * OUTPUT:
 *   FCT_DOCUMENT_INSIGHTS table populated with aggregated metrics
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context (ensure ACCOUNTADMIN role for schema object creation)
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SFE_ANALYTICS_ENTERTAINMENT;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- AGGREGATE ALL DOCUMENT INSIGHTS
-- ============================================================================

INSERT INTO FCT_DOCUMENT_INSIGHTS (
    insight_id,
    document_id,
    document_type,
    total_amount,
    currency,
    document_date,
    vendor_territory,
    processing_time_seconds,
    confidence_score,
    requires_manual_review,
    insight_created_at,
    metadata
)
SELECT
    'INSIGHT_' || UUID_STRING() AS insight_id,
    p.document_id,
    c.document_type,
    -- Extract amount based on document type
    CASE 
        WHEN c.document_type = 'Invoice' THEN p.parsed_content:total_amount::FLOAT
        WHEN c.document_type = 'Royalty Statement' THEN p.parsed_content:total_royalties::FLOAT
        WHEN c.document_type = 'Contract' THEN p.parsed_content:contract_value::FLOAT
        ELSE NULL
    END AS total_amount,
    'USD' AS currency,
    -- Extract document date
    CASE 
        WHEN c.document_type = 'Invoice' THEN TRY_TO_DATE(p.parsed_content:invoice_date::STRING)
        WHEN c.document_type = 'Royalty Statement' THEN TRY_TO_DATE(p.parsed_content:period_end::STRING)
        WHEN c.document_type = 'Contract' THEN TRY_TO_DATE(p.parsed_content:effective_date::STRING)
        ELSE NULL
    END AS document_date,
    -- Extract vendor or territory
    CASE 
        WHEN c.document_type = 'Invoice' THEN p.parsed_content:vendor_name::STRING
        WHEN c.document_type = 'Royalty Statement' THEN p.parsed_content:territory::STRING
        WHEN c.document_type = 'Contract' THEN NULL
        ELSE NULL
    END AS vendor_territory,
    -- Simulated processing time (for analytics)
    UNIFORM(5, 45, RANDOM()) AS processing_time_seconds,
    -- Average confidence across all AI processing stages
    ROUND((p.confidence_score + COALESCE(t.translation_confidence, p.confidence_score) + c.classification_confidence) / 3, 4) AS confidence_score,
    -- Flag for manual review (low confidence or high value)
    CASE 
        WHEN p.confidence_score < 0.85 THEN TRUE
        WHEN c.priority_level = 'High' AND p.confidence_score < 0.90 THEN TRUE
        ELSE FALSE
    END AS requires_manual_review,
    CURRENT_TIMESTAMP() AS insight_created_at,
    -- Enriched metadata
    OBJECT_CONSTRUCT(
        'priority_level', c.priority_level,
        'business_category', c.business_category,
        'source_language', p.parsed_content:detected_language::STRING,
        'translation_performed', (t.translation_id IS NOT NULL),
        'document_source', p.document_source_table,
        'extraction_method', p.extraction_method,
        'processing_timestamp', p.processed_at
    ) AS metadata
FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS p
JOIN SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS c ON p.parsed_id = c.parsed_id
LEFT JOIN SFE_STG_ENTERTAINMENT.STG_TRANSLATED_CONTENT t ON p.parsed_id = t.parsed_id;

SELECT COUNT(*) || ' document insights aggregated' AS status
FROM FCT_DOCUMENT_INSIGHTS;

-- ============================================================================
-- BUSINESS INTELLIGENCE QUERIES
-- ============================================================================

-- Total value by document type
SELECT 
    document_type,
    COUNT(*) AS document_count,
    ROUND(SUM(total_amount), 2) AS total_value,
    ROUND(AVG(total_amount), 2) AS avg_value,
    ROUND(MAX(total_amount), 2) AS max_value,
    currency
FROM FCT_DOCUMENT_INSIGHTS
WHERE total_amount IS NOT NULL
GROUP BY document_type, currency
ORDER BY total_value DESC;

-- Documents requiring manual review
SELECT 
    document_type,
    COUNT(*) AS total_documents,
    SUM(CASE WHEN requires_manual_review THEN 1 ELSE 0 END) AS needs_review,
    ROUND(SUM(CASE WHEN requires_manual_review THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS review_percentage,
    ROUND(AVG(confidence_score), 4) AS avg_confidence
FROM FCT_DOCUMENT_INSIGHTS
GROUP BY document_type
ORDER BY review_percentage DESC;

-- Top vendors/territories by value
SELECT 
    COALESCE(vendor_territory, 'N/A') AS vendor_territory,
    document_type,
    COUNT(*) AS document_count,
    ROUND(SUM(total_amount), 2) AS total_value,
    currency
FROM FCT_DOCUMENT_INSIGHTS
WHERE vendor_territory IS NOT NULL
AND total_amount IS NOT NULL
GROUP BY vendor_territory, document_type, currency
ORDER BY total_value DESC
LIMIT 20;

-- Processing efficiency metrics
SELECT 
    document_type,
    COUNT(*) AS documents_processed,
    ROUND(AVG(processing_time_seconds), 2) AS avg_processing_time_sec,
    ROUND(MIN(processing_time_seconds), 2) AS min_time_sec,
    ROUND(MAX(processing_time_seconds), 2) AS max_time_sec,
    ROUND(SUM(processing_time_seconds) / 60, 2) AS total_processing_min
FROM FCT_DOCUMENT_INSIGHTS
GROUP BY document_type
ORDER BY total_processing_min DESC;

-- Recent document trends (last 30 days)
SELECT 
    DATE_TRUNC('day', insight_created_at) AS processing_date,
    document_type,
    COUNT(*) AS documents_processed,
    ROUND(AVG(confidence_score), 4) AS avg_confidence
FROM FCT_DOCUMENT_INSIGHTS
WHERE insight_created_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY processing_date, document_type
ORDER BY processing_date DESC, document_type;

SELECT 'Aggregation complete - Business insights ready for consumption' AS final_status;

