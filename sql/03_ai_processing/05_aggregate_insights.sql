/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Aggregate Document Insights
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Combine parsed, translated, classified, and extracted document data into
 *   a single analytics fact table for business intelligence and reporting.
 *
 * OUTPUT:
 *   FCT_DOCUMENT_INSIGHTS table populated with aggregated metrics from all
 *   AI processing stages.
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
-- AGGREGATE ALL DOCUMENT INSIGHTS
-- ============================================================================

INSERT INTO SWIFTCLAW.FCT_DOCUMENT_INSIGHTS (
    insight_id,
    document_id,
    document_type,
    total_amount,
    currency,
    document_date,
    vendor_territory,
    processing_time_seconds,
    overall_confidence_score,
    requires_manual_review,
    manual_review_reason,
    insight_created_at,
    metadata
)
SELECT
    UUID_STRING() AS insight_id,
    catalog.document_id,
    classified.document_type,
    -- Extract total amount from extracted entities
    TRY_TO_NUMBER(
        MAX(CASE WHEN entities.entity_type IN ('total_amount', 'total_royalties', 'contract_value')
            THEN entities.entity_value END)
    ) AS total_amount,
    -- Extract currency
    COALESCE(
        MAX(CASE WHEN entities.entity_type = 'currency' THEN entities.entity_value END),
        'USD'
    ) AS currency,
    -- Extract document date
    TRY_TO_DATE(
        MAX(CASE WHEN entities.entity_type IN ('invoice_date', 'effective_date', 'period_end')
            THEN entities.entity_value END)
    ) AS document_date,
    -- Extract vendor or territory
    COALESCE(
        MAX(CASE WHEN entities.entity_type IN ('vendor_name', 'territory', 'party_b')
            THEN entities.entity_value END),
        catalog.metadata:vendor_name::STRING,
        catalog.metadata:territory::STRING
    ) AS vendor_territory,
    -- Calculate total processing time from logs
    COALESCE(
        SUM(log.duration_seconds),
        UNIFORM(15, 60, RANDOM())
    ) AS processing_time_seconds,
    -- Calculate overall confidence score (average across all AI stages)
    ROUND(
        (
            COALESCE(parsed.confidence_score, 0.90) +
            COALESCE(trans.translation_confidence, 0.90) +
            COALESCE(classified.classification_confidence, 0.90) +
            COALESCE(AVG(entities.extraction_confidence), 0.90)
        ) / 4,
        4
    ) AS overall_confidence_score,
    -- Determine if manual review required
    CASE
        WHEN parsed.confidence_score < 0.85 THEN TRUE
        WHEN classified.classification_confidence < 0.70 THEN TRUE
        WHEN classified.priority_level = 'High' AND parsed.confidence_score < 0.90 THEN TRUE
        WHEN TRY_TO_NUMBER(MAX(CASE WHEN entities.entity_type IN ('total_amount', 'total_royalties')
            THEN entities.entity_value END)) > 100000 THEN TRUE
        ELSE FALSE
    END AS requires_manual_review,
    -- Explain why manual review is needed
    CASE
        WHEN parsed.confidence_score < 0.85 THEN 'Low parsing confidence'
        WHEN classified.classification_confidence < 0.70 THEN 'Low classification confidence'
        WHEN classified.priority_level = 'High' AND parsed.confidence_score < 0.90 THEN 'High priority with moderate confidence'
        WHEN TRY_TO_NUMBER(MAX(CASE WHEN entities.entity_type IN ('total_amount', 'total_royalties')
            THEN entities.entity_value END)) > 100000 THEN 'High value transaction'
        ELSE NULL
    END AS manual_review_reason,
    CURRENT_TIMESTAMP() AS insight_created_at,
    -- Enriched metadata
    OBJECT_CONSTRUCT(
        'priority_level', classified.priority_level,
        'business_category', classified.business_category,
        'source_language', catalog.original_language,
        'translation_performed', (trans.translation_id IS NOT NULL),
        'extraction_mode', parsed.extraction_mode,
        'page_count', parsed.page_count,
        'processing_stages', ARRAY_CONSTRUCT('PARSE',
            CASE WHEN trans.translation_id IS NOT NULL THEN 'TRANSLATE' END,
            'CLASSIFY', 'EXTRACT'),
        'entity_count', COUNT(DISTINCT entities.entity_type),
        'catalog_metadata', catalog.metadata
    ) AS metadata
FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG catalog
JOIN SWIFTCLAW.STG_PARSED_DOCUMENTS parsed ON catalog.document_id = parsed.document_id
LEFT JOIN SWIFTCLAW.STG_TRANSLATED_CONTENT trans ON parsed.parsed_id = trans.parsed_id
LEFT JOIN SWIFTCLAW.STG_CLASSIFIED_DOCS classified ON parsed.parsed_id = classified.parsed_id
LEFT JOIN SWIFTCLAW.STG_EXTRACTED_ENTITIES entities ON parsed.parsed_id = entities.parsed_id
LEFT JOIN SWIFTCLAW.RAW_DOCUMENT_PROCESSING_LOG log ON catalog.document_id = log.document_id
WHERE catalog.processing_status = 'COMPLETED'
GROUP BY
    catalog.document_id,
    catalog.original_language,
    catalog.metadata,
    classified.document_type,
    classified.priority_level,
    classified.business_category,
    classified.classification_confidence,
    parsed.confidence_score,
    parsed.extraction_mode,
    parsed.page_count,
    trans.translation_id,
    trans.translation_confidence;

SELECT COUNT(*) || ' document insights aggregated' AS status
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS;

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
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
WHERE total_amount IS NOT NULL
GROUP BY document_type, currency
ORDER BY total_value DESC;

-- Documents requiring manual review
SELECT
    document_type,
    manual_review_reason,
    COUNT(*) AS documents_needing_review,
    AVG(overall_confidence_score) AS avg_confidence,
    AVG(total_amount) AS avg_amount
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
WHERE requires_manual_review = TRUE
GROUP BY document_type, manual_review_reason
ORDER BY documents_needing_review DESC;

-- Top vendors/territories by value
SELECT
    COALESCE(vendor_territory, 'N/A') AS vendor_territory,
    document_type,
    COUNT(*) AS document_count,
    ROUND(SUM(total_amount), 2) AS total_value,
    currency
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
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
    ROUND(SUM(processing_time_seconds) / 60, 2) AS total_processing_min,
    ROUND(AVG(overall_confidence_score), 4) AS avg_confidence
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
GROUP BY document_type
ORDER BY total_processing_min DESC;

-- Quality metrics by confidence score
SELECT
    CASE
        WHEN overall_confidence_score >= 0.95 THEN 'Excellent (0.95+)'
        WHEN overall_confidence_score >= 0.90 THEN 'Very Good (0.90-0.95)'
        WHEN overall_confidence_score >= 0.80 THEN 'Good (0.80-0.90)'
        WHEN overall_confidence_score >= 0.70 THEN 'Fair (0.70-0.80)'
        ELSE 'Poor (<0.70)'
    END AS confidence_band,
    COUNT(*) AS document_count,
    ROUND(AVG(total_amount), 2) AS avg_amount,
    SUM(CASE WHEN requires_manual_review THEN 1 ELSE 0 END) AS manual_review_count
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
GROUP BY confidence_band
ORDER BY MIN(overall_confidence_score) DESC;

-- Recent document trends
SELECT
    DATE_TRUNC('day', insight_created_at) AS processing_date,
    document_type,
    COUNT(*) AS documents_processed,
    ROUND(AVG(overall_confidence_score), 4) AS avg_confidence,
    ROUND(AVG(processing_time_seconds), 2) AS avg_time_sec
FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS
WHERE insight_created_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY processing_date, document_type
ORDER BY processing_date DESC, document_type;
