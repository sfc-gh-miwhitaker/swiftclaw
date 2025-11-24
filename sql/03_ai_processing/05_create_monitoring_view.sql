/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Monitoring View
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create a monitoring view that provides real-time visibility into the
 *   document processing pipeline's health, performance, and quality metrics.
 * 
 * OUTPUT:
 *   V_PROCESSING_METRICS view for dashboard consumption
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SFE_ANALYTICS_ENTERTAINMENT;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- CREATE MONITORING VIEW
-- ============================================================================

CREATE OR REPLACE VIEW V_PROCESSING_METRICS
COMMENT = 'DEMO: swiftclaw - Real-time pipeline monitoring metrics | Expires: 2025-12-24 | Author: SE Community'
AS
WITH pipeline_stats AS (
    SELECT
        -- Document counts by stage
        (SELECT COUNT(*) FROM SFE_RAW_ENTERTAINMENT.RAW_INVOICES) +
        (SELECT COUNT(*) FROM SFE_RAW_ENTERTAINMENT.RAW_ROYALTY_STATEMENTS) +
        (SELECT COUNT(*) FROM SFE_RAW_ENTERTAINMENT.RAW_CONTRACTS) AS total_raw_documents,
        
        (SELECT COUNT(*) FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS) AS total_parsed,
        (SELECT COUNT(*) FROM SFE_STG_ENTERTAINMENT.STG_TRANSLATED_CONTENT) AS total_translated,
        (SELECT COUNT(*) FROM SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS) AS total_classified,
        (SELECT COUNT(*) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS) AS total_insights,
        
        -- Quality metrics
        (SELECT AVG(confidence_score) FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS) AS avg_parsing_confidence,
        (SELECT AVG(translation_confidence) FROM SFE_STG_ENTERTAINMENT.STG_TRANSLATED_CONTENT) AS avg_translation_confidence,
        (SELECT AVG(classification_confidence) FROM SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS) AS avg_classification_confidence,
        (SELECT AVG(confidence_score) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS) AS avg_overall_confidence,
        
        -- Manual review metrics
        (SELECT COUNT(*) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS WHERE requires_manual_review = TRUE) AS documents_needing_review,
        
        -- Processing time metrics
        (SELECT AVG(processing_time_seconds) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS) AS avg_processing_time_sec,
        (SELECT SUM(processing_time_seconds) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS) AS total_processing_time_sec,
        
        -- Business metrics
        (SELECT SUM(total_amount) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS WHERE document_type = 'Invoice') AS total_invoice_value,
        (SELECT SUM(total_amount) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS WHERE document_type = 'Royalty Statement') AS total_royalty_value,
        (SELECT SUM(total_amount) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS WHERE document_type = 'Contract') AS total_contract_value,
        
        -- Timestamps
        (SELECT MAX(processed_at) FROM SFE_STG_ENTERTAINMENT.STG_PARSED_DOCUMENTS) AS last_parsing_timestamp,
        (SELECT MAX(classified_at) FROM SFE_STG_ENTERTAINMENT.STG_CLASSIFIED_DOCS) AS last_classification_timestamp,
        (SELECT MAX(insight_created_at) FROM SFE_ANALYTICS_ENTERTAINMENT.FCT_DOCUMENT_INSIGHTS) AS last_insight_timestamp
)
SELECT
    -- Pipeline Completeness
    'Pipeline Completeness' AS metric_category,
    total_raw_documents AS raw_documents,
    total_parsed AS parsed_documents,
    total_classified AS classified_documents,
    total_insights AS insight_documents,
    ROUND((total_insights::FLOAT / NULLIF(total_raw_documents, 0)) * 100, 2) AS completion_percentage,
    
    -- Quality Scores
    ROUND(avg_parsing_confidence, 4) AS avg_parsing_confidence,
    ROUND(avg_classification_confidence, 4) AS avg_classification_confidence,
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
    
    -- Business Value
    ROUND(total_invoice_value, 2) AS total_invoice_value_usd,
    ROUND(total_royalty_value, 2) AS total_royalty_value_usd,
    ROUND(total_contract_value, 2) AS total_contract_value_usd,
    ROUND(total_invoice_value + total_royalty_value + total_contract_value, 2) AS total_value_processed_usd,
    
    -- Freshness
    last_parsing_timestamp,
    last_classification_timestamp,
    last_insight_timestamp,
    DATEDIFF('minute', last_insight_timestamp, CURRENT_TIMESTAMP()) AS minutes_since_last_insight,
    
    -- Pipeline Health Status
    CASE 
        WHEN completion_percentage >= 95 AND avg_overall_confidence >= 0.85 THEN '✅ Healthy'
        WHEN completion_percentage >= 80 AND avg_overall_confidence >= 0.75 THEN '⚠️ Warning'
        ELSE '❌ Attention Required'
    END AS pipeline_health_status,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS metrics_generated_at
FROM pipeline_stats;

-- Grant SELECT permission to demo role
GRANT SELECT ON VIEW V_PROCESSING_METRICS TO ROLE SFE_DEMO_ROLE;

SELECT 'Monitoring view created: V_PROCESSING_METRICS' AS status;

-- ============================================================================
-- TEST MONITORING VIEW
-- ============================================================================

-- Query the monitoring view
SELECT * FROM V_PROCESSING_METRICS;

-- Sample queries for dashboard widgets

-- Widget 1: Pipeline Health Summary
SELECT 
    pipeline_health_status,
    completion_percentage,
    avg_overall_confidence,
    documents_needing_review,
    total_value_processed_usd,
    metrics_generated_at
FROM V_PROCESSING_METRICS;

-- Widget 2: Processing Performance
SELECT 
    avg_processing_time_seconds,
    total_processing_minutes,
    performance_rating,
    parsed_documents,
    classified_documents
FROM V_PROCESSING_METRICS;

-- Widget 3: Quality Metrics
SELECT 
    avg_parsing_confidence,
    avg_classification_confidence,
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

-- Widget 5: Data Freshness
SELECT 
    last_parsing_timestamp,
    last_classification_timestamp,
    last_insight_timestamp,
    minutes_since_last_insight
FROM V_PROCESSING_METRICS;

SELECT 'Monitoring view ready for Streamlit dashboard consumption' AS final_status;

