/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Monitoring View
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create a monitoring view that provides real-time visibility into the
 *   document processing pipeline's health, performance, and quality metrics
 *   across all AI processing stages.
 *
 * OUTPUT:
 *   V_PROCESSING_METRICS view for dashboard consumption
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
-- CREATE MONITORING VIEW
-- ============================================================================

CREATE OR REPLACE VIEW V_PROCESSING_METRICS
COMMENT = 'DEMO: swiftclaw - Real-time pipeline monitoring metrics | Expires: 2026-01-09 | Author: SE Community'
AS
WITH pipeline_stats AS (
    SELECT
        -- Document counts by stage
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG) AS total_catalog_documents,
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG WHERE processing_status = 'PENDING') AS pending_documents,
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG WHERE processing_status = 'COMPLETED') AS completed_documents,
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_CATALOG WHERE processing_status = 'FAILED') AS failed_documents,

        (SELECT COUNT(*) FROM SWIFTCLAW.STG_PARSED_DOCUMENTS) AS total_parsed,
        (SELECT COUNT(*) FROM SWIFTCLAW.STG_TRANSLATED_CONTENT) AS total_translated,
        (SELECT COUNT(*) FROM SWIFTCLAW.STG_CLASSIFIED_DOCS) AS total_classified,
        (SELECT COUNT(*) FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES) AS total_entities_extracted,
        (SELECT COUNT(*) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS) AS total_insights,

        -- Quality metrics
        (SELECT AVG(confidence_score) FROM SWIFTCLAW.STG_PARSED_DOCUMENTS) AS avg_parsing_confidence,
        (SELECT AVG(translation_confidence) FROM SWIFTCLAW.STG_TRANSLATED_CONTENT) AS avg_translation_confidence,
        (SELECT AVG(classification_confidence) FROM SWIFTCLAW.STG_CLASSIFIED_DOCS) AS avg_classification_confidence,
        (SELECT AVG(extraction_confidence) FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES) AS avg_extraction_confidence,
        (SELECT AVG(overall_confidence_score) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS) AS avg_overall_confidence,

        -- Manual review metrics
        (SELECT COUNT(*) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS WHERE requires_manual_review = TRUE) AS documents_needing_review,

        -- Processing time metrics
        (SELECT AVG(processing_time_seconds) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS) AS avg_processing_time_sec,
        (SELECT SUM(processing_time_seconds) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS) AS total_processing_time_sec,

        -- Error metrics
        (SELECT COUNT(DISTINCT document_id) FROM SWIFTCLAW.RAW_DOCUMENT_ERRORS) AS documents_with_errors,
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_ERRORS) AS total_error_count,

        -- Processing log metrics
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_PROCESSING_LOG WHERE status = 'SUCCESS') AS successful_processing_steps,
        (SELECT COUNT(*) FROM SWIFTCLAW.RAW_DOCUMENT_PROCESSING_LOG WHERE status = 'FAILED') AS failed_processing_steps,

        -- Business metrics
        (SELECT SUM(total_amount) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS WHERE document_type = 'Invoice') AS total_invoice_value,
        (SELECT SUM(total_amount) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS WHERE document_type = 'Royalty Statement') AS total_royalty_value,
        (SELECT SUM(total_amount) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS WHERE document_type = 'Contract') AS total_contract_value,

        -- Timestamps
        (SELECT MAX(processed_at) FROM SWIFTCLAW.STG_PARSED_DOCUMENTS) AS last_parsing_timestamp,
        (SELECT MAX(translated_at) FROM SWIFTCLAW.STG_TRANSLATED_CONTENT) AS last_translation_timestamp,
        (SELECT MAX(classified_at) FROM SWIFTCLAW.STG_CLASSIFIED_DOCS) AS last_classification_timestamp,
        (SELECT MAX(extracted_at) FROM SWIFTCLAW.STG_EXTRACTED_ENTITIES) AS last_extraction_timestamp,
        (SELECT MAX(insight_created_at) FROM SWIFTCLAW.FCT_DOCUMENT_INSIGHTS) AS last_insight_timestamp
)
SELECT
    -- Pipeline Completeness
    'Pipeline Completeness' AS metric_category,
    total_catalog_documents AS catalog_documents,
    pending_documents,
    completed_documents,
    failed_documents,
    total_parsed AS parsed_documents,
    total_translated AS translated_documents,
    total_classified AS classified_documents,
    total_entities_extracted AS entities_extracted,
    total_insights AS insight_documents,
    ROUND((completed_documents::FLOAT / NULLIF(total_catalog_documents, 0)) * 100, 2) AS completion_percentage,

    -- AI Quality Scores
    ROUND(avg_parsing_confidence, 4) AS avg_parsing_confidence,
    ROUND(avg_translation_confidence, 4) AS avg_translation_confidence,
    ROUND(avg_classification_confidence, 4) AS avg_classification_confidence,
    ROUND(avg_extraction_confidence, 4) AS avg_extraction_confidence,
    ROUND(avg_overall_confidence, 4) AS avg_overall_confidence,

    -- Manual Review Queue
    documents_needing_review,
    ROUND((documents_needing_review::FLOAT / NULLIF(total_insights, 0)) * 100, 2) AS manual_review_percentage,

    -- Performance Metrics
    ROUND(avg_processing_time_sec, 2) AS avg_processing_time_seconds,
    ROUND(total_processing_time_sec / 60, 2) AS total_processing_minutes,
    CASE
        WHEN avg_processing_time_sec < 15 THEN 'Excellent'
        WHEN avg_processing_time_sec < 30 THEN 'Good'
        WHEN avg_processing_time_sec < 45 THEN 'Fair'
        ELSE 'Needs Optimization'
    END AS performance_rating,

    -- Error Tracking
    documents_with_errors,
    total_error_count,
    ROUND((documents_with_errors::FLOAT / NULLIF(total_catalog_documents, 0)) * 100, 2) AS error_rate_percentage,
    successful_processing_steps,
    failed_processing_steps,
    ROUND((successful_processing_steps::FLOAT / NULLIF(successful_processing_steps + failed_processing_steps, 0)) * 100, 2) AS success_rate_percentage,

    -- Business Value
    ROUND(total_invoice_value, 2) AS total_invoice_value_usd,
    ROUND(total_royalty_value, 2) AS total_royalty_value_usd,
    ROUND(total_contract_value, 2) AS total_contract_value_usd,
    ROUND(COALESCE(total_invoice_value, 0) + COALESCE(total_royalty_value, 0) + COALESCE(total_contract_value, 0), 2) AS total_value_processed_usd,

    -- Freshness
    last_parsing_timestamp,
    last_translation_timestamp,
    last_classification_timestamp,
    last_extraction_timestamp,
    last_insight_timestamp,
    DATEDIFF('minute', last_insight_timestamp, CURRENT_TIMESTAMP()) AS minutes_since_last_insight,

    -- Pipeline Health Status
    CASE
        WHEN completion_percentage >= 95 AND avg_overall_confidence >= 0.85 AND error_rate_percentage < 5 THEN '✅ Healthy'
        WHEN completion_percentage >= 80 AND avg_overall_confidence >= 0.75 AND error_rate_percentage < 10 THEN '⚠️ Warning'
        ELSE '❌ Attention Required'
    END AS pipeline_health_status,

    -- Metadata
    CURRENT_TIMESTAMP() AS metrics_generated_at
FROM pipeline_stats;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify monitoring view returns expected metrics
SELECT * FROM V_PROCESSING_METRICS;

-- Sample queries for dashboard widgets

-- Widget 1: Pipeline Health Summary
SELECT
    pipeline_health_status,
    completion_percentage,
    avg_overall_confidence,
    documents_needing_review,
    total_value_processed_usd,
    error_rate_percentage,
    success_rate_percentage,
    metrics_generated_at
FROM V_PROCESSING_METRICS;

-- Widget 2: Processing Performance
SELECT
    avg_processing_time_seconds,
    total_processing_minutes,
    performance_rating,
    parsed_documents,
    classified_documents,
    entities_extracted
FROM V_PROCESSING_METRICS;

-- Widget 3: AI Quality Metrics
SELECT
    avg_parsing_confidence,
    avg_translation_confidence,
    avg_classification_confidence,
    avg_extraction_confidence,
    avg_overall_confidence,
    manual_review_percentage,
    documents_needing_review
FROM V_PROCESSING_METRICS;

-- Widget 4: Business Value
SELECT
    total_invoice_value_usd,
    total_royalty_value_usd,
    total_contract_value_usd,
    total_value_processed_usd
FROM V_PROCESSING_METRICS;

-- Widget 5: Error Tracking
SELECT
    documents_with_errors,
    total_error_count,
    error_rate_percentage,
    successful_processing_steps,
    failed_processing_steps,
    success_rate_percentage
FROM V_PROCESSING_METRICS;

-- Widget 6: Data Freshness
SELECT
    last_parsing_timestamp,
    last_classification_timestamp,
    last_extraction_timestamp,
    last_insight_timestamp,
    minutes_since_last_insight
FROM V_PROCESSING_METRICS;

-- Widget 7: Document Status Breakdown
SELECT
    catalog_documents AS total,
    pending_documents,
    completed_documents,
    failed_documents,
    completion_percentage
FROM V_PROCESSING_METRICS;

SELECT 'Monitoring view ready for Streamlit dashboard consumption' AS final_status;
