/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Dynamic Table Pipeline
 *
 * PURPOSE:
 *   Create a simplified AI document pipeline using Dynamic Tables for
 *   automated orchestration, AI_EXTRACT for entity extraction, and AI_CLASSIFY
 *   for document type classification.
 *
 * OBJECTS CREATED:
 *   - RAW_DOCUMENT_CATALOG (table): Stage directory metadata
 *   - REFRESH_DOCUMENT_CATALOG (procedure)
 *   - REFRESH_DOCUMENT_CATALOG_TASK (task)
 *   - STG_PARSED_DOCUMENTS (dynamic table, incremental, extract_images)
 *   - STG_TRANSLATED_CONTENT (dynamic table, incremental)
 *   - STG_ENRICHED_DOCUMENTS (dynamic table, AI_EXTRACT + AI_CLASSIFY)
 *   - FCT_DOCUMENT_INSIGHTS (dynamic table, incremental)
 *   - V_PROCESSING_METRICS (view, optimized)
 *
 * MODERNIZATION (2026-02-17):
 *   - AI_EXTRACT (GA Oct 2025): Replaced AI_COMPLETE for structured extraction
 *   - AI_CLASSIFY (GA Jun 2025): Purpose-built document type classification
 *   - AI_PARSE_DOCUMENT extract_images: Image extraction enabled (Preview)
 *   - REFRESH_MODE = INCREMENTAL on all Dynamic Tables (cost optimization)
 *   - STG_ENRICHED_DOCUMENTS converted from Task+Procedure to Dynamic Table
 *   - V_PROCESSING_METRICS: 14 subqueries -> 5 scans (conditional aggregation)
 *   - OBJECT_CONSTRUCT replaced with object literal syntax
 *
 * REQUIREMENTS:
 *   - Documents uploaded to @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE
 *   - SNOWFLAKE.CORTEX_USER database role granted
 *
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2026-02-17 | Expires: 2026-02-20
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SWIFTCLAW;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- DOCUMENT CATALOG (TABLE + REFRESH PROCEDURE)
-- ============================================================================

CREATE OR REPLACE TABLE RAW_DOCUMENT_CATALOG (
    document_id STRING,
    document_type STRING,
    stage_name STRING,
    file_path STRING,
    file_name STRING,
    file_format STRING,
    file_size_bytes NUMBER,
    original_language STRING,
    upload_date TIMESTAMP_NTZ,
    metadata VARIANT
)
COMMENT = 'DEMO: swiftclaw - Stage directory catalog table | Expires: 2026-02-20 | Author: SE Community';

CREATE OR REPLACE PROCEDURE REFRESH_DOCUMENT_CATALOG()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO RAW_DOCUMENT_CATALOG AS tgt
    USING (
        SELECT
            'DOC_' || UPPER(MD5_HEX(relative_path)) AS document_id,
            CASE
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'invoices' THEN 'INVOICE'
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'royalty' THEN 'ROYALTY_STATEMENT'
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'contracts' THEN 'CONTRACT'
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'other' THEN 'OTHER'
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'generated'
                     AND REGEXP_LIKE(relative_path, 'invoice_') THEN 'INVOICE'
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'generated'
                     AND REGEXP_LIKE(relative_path, 'royalty_') THEN 'ROYALTY_STATEMENT'
                WHEN SPLIT_PART(relative_path, '/', 1) ILIKE 'generated'
                     AND REGEXP_LIKE(relative_path, 'contract_') THEN 'CONTRACT'
                WHEN REGEXP_LIKE(relative_path, '^bridge_') THEN 'CONTRACT'
                ELSE 'OTHER'
            END AS document_type,
            '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE' AS stage_name,
            relative_path AS file_path,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS file_name,
            COALESCE(
                UPPER(REGEXP_SUBSTR(relative_path, '\\.([^.]+)$', 1, 1, 'e', 1)),
                'PDF'
            ) AS file_format,
            size AS file_size_bytes,
            COALESCE(
                REGEXP_SUBSTR(
                    relative_path,
                    '_(en|es|de|pt|ru|zh|fr|ja|ko)(_|\\.)',
                    1,
                    1,
                    'e',
                    1
                ),
                'en'
            ) AS original_language,
            last_modified::TIMESTAMP_NTZ AS upload_date,
            {
                'source': 'stage_directory',
                'directory': SPLIT_PART(relative_path, '/', 1),
                'file_md5': md5
            } AS metadata
        FROM DIRECTORY(@SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE)
        WHERE LOWER(relative_path) LIKE '%.pdf'
    ) AS src
    ON tgt.file_path = src.file_path
    WHEN MATCHED THEN UPDATE SET
        document_id = src.document_id,
        document_type = src.document_type,
        stage_name = src.stage_name,
        file_name = src.file_name,
        file_format = src.file_format,
        file_size_bytes = src.file_size_bytes,
        original_language = src.original_language,
        upload_date = src.upload_date,
        metadata = src.metadata
    WHEN NOT MATCHED THEN INSERT (
        document_id,
        document_type,
        stage_name,
        file_path,
        file_name,
        file_format,
        file_size_bytes,
        original_language,
        upload_date,
        metadata
    )
    VALUES (
        src.document_id,
        src.document_type,
        src.stage_name,
        src.file_path,
        src.file_name,
        src.file_format,
        src.file_size_bytes,
        src.original_language,
        src.upload_date,
        src.metadata
    );

    RETURN 'RAW_DOCUMENT_CATALOG refreshed';
END;
$$;

CALL REFRESH_DOCUMENT_CATALOG();

CREATE OR REPLACE TASK REFRESH_DOCUMENT_CATALOG_TASK
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    SCHEDULE = '10 MINUTE'
AS
    CALL REFRESH_DOCUMENT_CATALOG();

ALTER TASK REFRESH_DOCUMENT_CATALOG_TASK RESUME;

-- ============================================================================
-- STAGE 1: PARSE DOCUMENTS
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE STG_PARSED_DOCUMENTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
    COMMENT = 'DEMO: swiftclaw - AI_PARSE_DOCUMENT results | Expires: 2026-02-20 | Author: SE Community'
AS
SELECT
    base.document_id,
    base.document_type,
    base.original_language,
    base.stage_name,
    base.file_path,
    base.parsed_content,
    'LAYOUT' AS extraction_mode,
    TRY_TO_NUMBER(base.parsed_content:metadata:pageCount::STRING) AS page_count,
    base.upload_date AS processed_at
FROM (
    SELECT
        catalog.document_id,
        catalog.document_type,
        catalog.original_language,
        catalog.stage_name,
        catalog.file_path,
        catalog.upload_date,
        AI_PARSE_DOCUMENT(
            TO_FILE(catalog.stage_name, catalog.file_path),
            {'mode': 'LAYOUT', 'page_split': FALSE, 'extract_images': TRUE}
        ) AS parsed_content
    FROM RAW_DOCUMENT_CATALOG catalog
    WHERE catalog.file_format = 'PDF'
) base;

-- ============================================================================
-- STAGE 2: TRANSLATE NON-ENGLISH CONTENT
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE STG_TRANSLATED_CONTENT
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
    COMMENT = 'DEMO: swiftclaw - AI_TRANSLATE results | Expires: 2026-02-20 | Author: SE Community'
AS
SELECT
    parsed.document_id,
    parsed.document_id AS parsed_id,
    parsed.original_language AS source_language,
    'en' AS target_language,
    parsed.parsed_text AS source_text,
    AI_TRANSLATE(parsed.parsed_text, parsed.original_language, 'en') AS translated_text,
    parsed.processed_at AS translated_at
FROM (
    SELECT
        document_id,
        original_language,
        processed_at,
        parsed_content:content::STRING AS parsed_text
    FROM STG_PARSED_DOCUMENTS
    WHERE parsed_content:content::STRING IS NOT NULL
      AND original_language <> 'en'
) parsed;

-- ============================================================================
-- STAGE 3: ENRICH DOCUMENTS (AI_EXTRACT + AI_CLASSIFY VIA DYNAMIC TABLE)
-- ============================================================================
-- MODERNIZED (2026-02-17): Replaced AI_COMPLETE with purpose-built functions:
--   AI_EXTRACT (GA Oct 2025): Structured entity extraction directly from file.
--     Handles parsing + multilingual extraction in one call (29 languages).
--     Arctic-Extract model benchmarks 81.18 ANLS (beats Claude 4 Sonnet).
--   AI_CLASSIFY (GA Jun 2025): Purpose-built classification with label descriptions.
--     Supports up to 500 labels, multi-label, and few-shot examples.
-- Confidence score derived from field extraction completeness (more meaningful
-- than LLM self-assessment).

CREATE OR REPLACE DYNAMIC TABLE STG_ENRICHED_DOCUMENTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
    COMMENT = 'DEMO: swiftclaw - AI_EXTRACT + AI_CLASSIFY enrichment | Expires: 2026-02-20 | Author: SE Community'
AS
SELECT
    base.document_id,
    -- AI_CLASSIFY validates/overrides catalog classification
    COALESCE(base.ai_document_type, base.catalog_document_type) AS document_type,
    base.extraction_result:response:priority_level::STRING AS priority_level,
    base.extraction_result:response:business_category::STRING AS business_category,
    TRY_TO_NUMBER(base.extraction_result:response:total_amount::STRING) AS total_amount,
    COALESCE(base.extraction_result:response:currency::STRING, 'USD') AS currency,
    TRY_TO_DATE(base.extraction_result:response:document_date::STRING) AS document_date,
    base.extraction_result:response:vendor_territory::STRING AS vendor_territory,
    -- Derived confidence: proportion of non-null extracted fields (6 fields)
    ROUND((
        IFF(base.extraction_result:response:priority_level IS NOT NULL, 1, 0) +
        IFF(base.extraction_result:response:business_category IS NOT NULL, 1, 0) +
        IFF(base.extraction_result:response:total_amount IS NOT NULL, 1, 0) +
        IFF(base.extraction_result:response:currency IS NOT NULL, 1, 0) +
        IFF(base.extraction_result:response:document_date IS NOT NULL, 1, 0) +
        IFF(base.extraction_result:response:vendor_territory IS NOT NULL, 1, 0)
    ) / 6.0, 2) AS confidence_score,
    base.extraction_result AS enrichment_details,
    base.processed_at AS enriched_at
FROM (
    SELECT
        catalog.document_id,
        catalog.document_type AS catalog_document_type,
        catalog.stage_name,
        catalog.file_path,
        parsed.processed_at,
        -- AI_CLASSIFY: Purpose-built document type classification from text
        AI_CLASSIFY(
            SUBSTR(
                COALESCE(trans.translated_text, parsed.parsed_content:content::STRING),
                1, 4000
            ),
            [
                {'label': 'INVOICE', 'description': 'Billing document with line items, amounts, and payment terms'},
                {'label': 'ROYALTY_STATEMENT', 'description': 'Entertainment royalty payment or distribution report'},
                {'label': 'CONTRACT', 'description': 'Legal agreement, license, or contract between parties'},
                {'label': 'OTHER', 'description': 'Document not matching invoice, royalty, or contract'}
            ]
        ) AS ai_document_type,
        -- AI_EXTRACT: Purpose-built entity extraction directly from file
        AI_EXTRACT(
            file => TO_FILE(catalog.stage_name, catalog.file_path),
            responseFormat => {
                'priority_level': 'What is the urgency level? Answer exactly: HIGH, MEDIUM, or LOW',
                'business_category': 'What business category? Answer exactly: ACCOUNTS_PAYABLE, RIGHTS_MANAGEMENT, LEGAL_COMPLIANCE, or GENERAL',
                'total_amount': 'What is the total monetary amount? Return only the number',
                'currency': 'What currency is used? Return the ISO code like USD, EUR, GBP',
                'document_date': 'What is the primary date? Use format YYYY-MM-DD',
                'vendor_territory': 'What is the vendor name, payee, or territory?'
            }
        ) AS extraction_result
    FROM RAW_DOCUMENT_CATALOG catalog
    JOIN STG_PARSED_DOCUMENTS parsed
        ON catalog.document_id = parsed.document_id
    LEFT JOIN STG_TRANSLATED_CONTENT trans
        ON parsed.document_id = trans.document_id
    WHERE catalog.file_format = 'PDF'
      AND parsed.parsed_content:content::STRING IS NOT NULL
) base;

-- ============================================================================
-- STAGE 4: AGGREGATE BUSINESS INSIGHTS
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE FCT_DOCUMENT_INSIGHTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
    COMMENT = 'DEMO: swiftclaw - Aggregated document insights | Expires: 2026-02-20 | Author: SE Community'
AS
SELECT
    'INS_' || catalog.document_id AS insight_id,
    catalog.document_id,
    COALESCE(enriched.document_type, catalog.document_type) AS document_type,
    enriched.total_amount,
    enriched.currency,
    enriched.document_date,
    enriched.vendor_territory,
    enriched.confidence_score AS overall_confidence_score,
    CASE
        WHEN enriched.document_type IS NULL THEN TRUE
        WHEN enriched.confidence_score IS NULL THEN TRUE
        WHEN enriched.confidence_score < 0.80 THEN TRUE
        WHEN enriched.total_amount > 100000 THEN TRUE
        ELSE FALSE
    END AS requires_manual_review,
    CASE
        WHEN enriched.document_type IS NULL THEN 'Missing classification'
        WHEN enriched.confidence_score IS NULL THEN 'Missing confidence score'
        WHEN enriched.confidence_score < 0.80 THEN 'Low confidence score'
        WHEN enriched.total_amount > 100000 THEN 'High value document'
        ELSE NULL
    END AS manual_review_reason,
    catalog.upload_date AS insight_created_at,
    {
        'priority_level': enriched.priority_level,
        'business_category': enriched.business_category,
        'source_language': catalog.original_language,
        'extraction_mode': parsed.extraction_mode,
        'page_count': parsed.page_count,
        'catalog_metadata': catalog.metadata
    } AS metadata
FROM RAW_DOCUMENT_CATALOG catalog
LEFT JOIN STG_PARSED_DOCUMENTS parsed
    ON catalog.document_id = parsed.document_id
LEFT JOIN STG_ENRICHED_DOCUMENTS enriched
    ON catalog.document_id = enriched.document_id;

-- ============================================================================
-- MONITORING VIEW
-- ============================================================================
-- OPTIMIZED (2026-02-17): Consolidated 14 scalar subqueries into 5 table scans
-- using conditional aggregation. Each source table is scanned exactly once.

CREATE OR REPLACE VIEW V_PROCESSING_METRICS
COMMENT = 'DEMO: swiftclaw - Real-time pipeline monitoring metrics | Expires: 2026-02-20 | Author: SE Community'
AS
WITH catalog_stats AS (
    SELECT COUNT(*) AS total_catalog_documents
    FROM RAW_DOCUMENT_CATALOG
),
parsed_stats AS (
    SELECT
        COUNT(*) AS total_parsed,
        MAX(processed_at) AS last_parsing_timestamp
    FROM STG_PARSED_DOCUMENTS
),
translated_stats AS (
    SELECT
        COUNT(*) AS total_translated,
        MAX(translated_at) AS last_translation_timestamp
    FROM STG_TRANSLATED_CONTENT
),
enriched_stats AS (
    SELECT
        COUNT(*) AS total_enriched,
        MAX(enriched_at) AS last_enrichment_timestamp
    FROM STG_ENRICHED_DOCUMENTS
),
insight_stats AS (
    SELECT
        COUNT(*) AS total_insights,
        AVG(overall_confidence_score) AS avg_overall_confidence,
        COUNT_IF(requires_manual_review) AS documents_needing_review,
        SUM(IFF(document_type = 'INVOICE', total_amount, 0)) AS total_invoice_value,
        SUM(IFF(document_type = 'ROYALTY_STATEMENT', total_amount, 0)) AS total_royalty_value,
        SUM(IFF(document_type = 'CONTRACT', total_amount, 0)) AS total_contract_value,
        MAX(insight_created_at) AS last_insight_timestamp
    FROM FCT_DOCUMENT_INSIGHTS
),
metrics AS (
    SELECT
        c.total_catalog_documents,
        p.total_parsed,
        t.total_translated,
        e.total_enriched,
        i.total_insights,
        i.avg_overall_confidence,
        i.documents_needing_review,
        i.total_invoice_value,
        i.total_royalty_value,
        i.total_contract_value,
        p.last_parsing_timestamp,
        t.last_translation_timestamp,
        e.last_enrichment_timestamp,
        i.last_insight_timestamp,
        ROUND((i.total_insights::FLOAT / NULLIF(c.total_catalog_documents, 0)) * 100, 2)
            AS completion_percentage,
        ROUND((i.documents_needing_review::FLOAT / NULLIF(i.total_insights, 0)) * 100, 2)
            AS manual_review_percentage,
        ROUND(COALESCE(i.total_invoice_value, 0) + COALESCE(i.total_royalty_value, 0)
            + COALESCE(i.total_contract_value, 0), 2) AS total_value_processed_usd
    FROM catalog_stats c, parsed_stats p, translated_stats t, enriched_stats e, insight_stats i
)
SELECT
    total_catalog_documents AS catalog_documents,
    GREATEST(total_catalog_documents - total_insights, 0) AS pending_documents,
    total_insights AS completed_documents,
    0 AS failed_documents,
    total_parsed AS parsed_documents,
    total_translated AS translated_documents,
    total_enriched AS enriched_documents,
    total_insights AS insight_documents,
    completion_percentage,
    ROUND(avg_overall_confidence, 4) AS avg_overall_confidence,
    documents_needing_review,
    manual_review_percentage,
    total_value_processed_usd,
    last_parsing_timestamp,
    last_translation_timestamp,
    last_enrichment_timestamp,
    last_insight_timestamp,
    DATEDIFF('minute', last_insight_timestamp, CURRENT_TIMESTAMP()) AS minutes_since_last_insight,
    CASE
        WHEN completion_percentage >= 95
             AND avg_overall_confidence >= 0.85
             AND manual_review_percentage < 5 THEN 'Healthy'
        WHEN completion_percentage >= 80
             AND avg_overall_confidence >= 0.75
             AND manual_review_percentage < 10 THEN 'Warning'
        ELSE 'Attention Required'
    END AS pipeline_health_status
FROM metrics;

