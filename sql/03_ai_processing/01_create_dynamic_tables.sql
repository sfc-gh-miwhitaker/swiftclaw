/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Create Dynamic Table Pipeline
 *
 * PURPOSE:
 *   Create a simplified AI document pipeline using Dynamic Tables for
 *   automated orchestration and AI_COMPLETE structured output for enrichment.
 *
 * OBJECTS CREATED:
 *   - RAW_DOCUMENT_CATALOG (table): Stage directory metadata
 *   - REFRESH_DOCUMENT_CATALOG (procedure)
 *   - REFRESH_DOCUMENT_CATALOG_TASK (task)
 *   - STG_PARSED_DOCUMENTS (dynamic table)
 *   - STG_TRANSLATED_CONTENT (dynamic table)
 *   - STG_ENRICHED_DOCUMENTS (dynamic table)
 *   - FCT_DOCUMENT_INSIGHTS (dynamic table)
 *   - V_PROCESSING_METRICS (view)
 *
 * REQUIREMENTS:
 *   - Documents uploaded to @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE
 *   - SNOWFLAKE.CORTEX_USER database role granted
 *
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2026-01-21 | Expires: 2026-02-20
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
            OBJECT_CONSTRUCT(
                'source', 'stage_directory',
                'directory', SPLIT_PART(relative_path, '/', 1),
                'file_md5', md5
            ) AS metadata
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
            OBJECT_CONSTRUCT('mode', 'LAYOUT', 'page_split', FALSE)
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
-- STAGE 3: ENRICH DOCUMENTS (AI_COMPLETE VIA TASK)
-- ============================================================================

CREATE OR REPLACE TABLE STG_ENRICHED_DOCUMENTS (
    document_id STRING,
    document_type STRING,
    priority_level STRING,
    business_category STRING,
    total_amount NUMBER,
    currency STRING,
    document_date DATE,
    vendor_territory STRING,
    confidence_score NUMBER,
    enrichment_details VARIANT,
    enriched_at TIMESTAMP_NTZ
)
COMMENT = 'DEMO: swiftclaw - AI_COMPLETE structured enrichment | Expires: 2026-02-20 | Author: SE Community';

CREATE OR REPLACE PROCEDURE REFRESH_ENRICHED_DOCUMENTS()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO STG_ENRICHED_DOCUMENTS (
        document_id,
        document_type,
        priority_level,
        business_category,
        total_amount,
        currency,
        document_date,
        vendor_territory,
        confidence_score,
        enrichment_details,
        enriched_at
    )
    SELECT
        base.document_id,
        COALESCE(enrichment_json:document_type::STRING, base.catalog_document_type) AS document_type,
        enrichment_json:priority_level::STRING AS priority_level,
        enrichment_json:business_category::STRING AS business_category,
        TRY_TO_NUMBER(enrichment_json:total_amount::STRING) AS total_amount,
        COALESCE(enrichment_json:currency::STRING, 'USD') AS currency,
        TRY_TO_DATE(enrichment_json:document_date::STRING) AS document_date,
        enrichment_json:vendor_territory::STRING AS vendor_territory,
        TRY_TO_NUMBER(enrichment_json:confidence_score::STRING) AS confidence_score,
        enrichment_json AS enrichment_details,
        CURRENT_TIMESTAMP() AS enriched_at
    FROM (
        SELECT
            parsed.document_id,
            parsed.document_type AS catalog_document_type,
            COALESCE(trans.translated_text, parsed.parsed_content:content::STRING) AS analysis_text
        FROM STG_PARSED_DOCUMENTS parsed
        LEFT JOIN STG_TRANSLATED_CONTENT trans
            ON parsed.document_id = trans.document_id
        WHERE parsed.parsed_content:content::STRING IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM STG_ENRICHED_DOCUMENTS existing
              WHERE existing.document_id = parsed.document_id
          )
    ) base,
    LATERAL (
        SELECT TRY_PARSE_JSON(
            AI_COMPLETE(
                model => 'snowflake-arctic',
                prompt => CONCAT(
                    'You are a data extraction system. Return only JSON that matches the schema. ',
                    'Use enum values exactly as provided. Use null when unknown. ',
                    'Use ISO date format YYYY-MM-DD for document_date. ',
                    'Document text: ',
                    SUBSTR(COALESCE(base.analysis_text, ''), 1, 12000)
                ),
                model_parameters => OBJECT_CONSTRUCT('temperature', 0, 'max_tokens', 2048),
                response_format => OBJECT_CONSTRUCT(
                    'type', 'json',
                    'schema', OBJECT_CONSTRUCT(
                        'type', 'object',
                        'additionalProperties', FALSE,
                        'properties', OBJECT_CONSTRUCT(
                            'document_type', OBJECT_CONSTRUCT(
                                'type', 'string',
                                'enum', ARRAY_CONSTRUCT('INVOICE', 'ROYALTY_STATEMENT', 'CONTRACT', 'OTHER')
                            ),
                            'priority_level', OBJECT_CONSTRUCT(
                                'type', 'string',
                                'enum', ARRAY_CONSTRUCT('HIGH', 'MEDIUM', 'LOW')
                            ),
                            'business_category', OBJECT_CONSTRUCT(
                                'type', 'string',
                                'enum', ARRAY_CONSTRUCT(
                                    'ACCOUNTS_PAYABLE',
                                    'RIGHTS_MANAGEMENT',
                                    'LEGAL_COMPLIANCE',
                                    'GENERAL'
                                )
                            ),
                            'total_amount', OBJECT_CONSTRUCT('type', 'number'),
                            'currency', OBJECT_CONSTRUCT('type', 'string'),
                            'document_date', OBJECT_CONSTRUCT('type', 'string'),
                            'vendor_territory', OBJECT_CONSTRUCT('type', 'string'),
                            'confidence_score', OBJECT_CONSTRUCT('type', 'number')
                        ),
                        'required', ARRAY_CONSTRUCT(
                            'document_type',
                            'priority_level',
                            'business_category',
                            'total_amount',
                            'currency',
                            'document_date',
                            'vendor_territory',
                            'confidence_score'
                        )
                    )
                )
            )
        ) AS enrichment_json
    ) enriched;

    RETURN 'STG_ENRICHED_DOCUMENTS refreshed';
END;
$$;

CALL REFRESH_ENRICHED_DOCUMENTS();

CREATE OR REPLACE TASK REFRESH_ENRICHED_DOCUMENTS_TASK
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    SCHEDULE = '10 MINUTE'
AS
    CALL REFRESH_ENRICHED_DOCUMENTS();

ALTER TASK REFRESH_ENRICHED_DOCUMENTS_TASK RESUME;

-- ============================================================================
-- STAGE 4: AGGREGATE BUSINESS INSIGHTS
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE FCT_DOCUMENT_INSIGHTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
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
    CAST(NULL AS NUMBER) AS processing_time_seconds,
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
    OBJECT_CONSTRUCT(
        'priority_level', enriched.priority_level,
        'business_category', enriched.business_category,
        'source_language', catalog.original_language,
        'extraction_mode', parsed.extraction_mode,
        'page_count', parsed.page_count,
        'catalog_metadata', catalog.metadata
    ) AS metadata
FROM RAW_DOCUMENT_CATALOG catalog
LEFT JOIN STG_PARSED_DOCUMENTS parsed
    ON catalog.document_id = parsed.document_id
LEFT JOIN STG_ENRICHED_DOCUMENTS enriched
    ON catalog.document_id = enriched.document_id;

-- ============================================================================
-- MONITORING VIEW
-- ============================================================================

CREATE OR REPLACE VIEW V_PROCESSING_METRICS
COMMENT = 'DEMO: swiftclaw - Real-time pipeline monitoring metrics | Expires: 2026-02-20 | Author: SE Community'
AS
WITH pipeline_stats AS (
    SELECT
        (SELECT COUNT(*) FROM RAW_DOCUMENT_CATALOG) AS total_catalog_documents,
        (SELECT COUNT(*) FROM STG_PARSED_DOCUMENTS) AS total_parsed,
        (SELECT COUNT(*) FROM STG_TRANSLATED_CONTENT) AS total_translated,
        (SELECT COUNT(*) FROM STG_ENRICHED_DOCUMENTS) AS total_enriched,
        (SELECT COUNT(*) FROM FCT_DOCUMENT_INSIGHTS) AS total_insights,
        (SELECT AVG(overall_confidence_score) FROM FCT_DOCUMENT_INSIGHTS) AS avg_overall_confidence,
        (SELECT COUNT(*) FROM FCT_DOCUMENT_INSIGHTS WHERE requires_manual_review = TRUE)
            AS documents_needing_review,
        (SELECT SUM(total_amount) FROM FCT_DOCUMENT_INSIGHTS WHERE document_type = 'INVOICE')
            AS total_invoice_value,
        (SELECT SUM(total_amount) FROM FCT_DOCUMENT_INSIGHTS WHERE document_type = 'ROYALTY_STATEMENT')
            AS total_royalty_value,
        (SELECT SUM(total_amount) FROM FCT_DOCUMENT_INSIGHTS WHERE document_type = 'CONTRACT')
            AS total_contract_value,
        (SELECT MAX(processed_at) FROM STG_PARSED_DOCUMENTS) AS last_parsing_timestamp,
        (SELECT MAX(translated_at) FROM STG_TRANSLATED_CONTENT) AS last_translation_timestamp,
        (SELECT MAX(enriched_at) FROM STG_ENRICHED_DOCUMENTS) AS last_enrichment_timestamp,
        (SELECT MAX(insight_created_at) FROM FCT_DOCUMENT_INSIGHTS) AS last_insight_timestamp
),
metrics AS (
    SELECT
        total_catalog_documents,
        total_parsed,
        total_translated,
        total_enriched,
        total_insights,
        avg_overall_confidence,
        documents_needing_review,
        total_invoice_value,
        total_royalty_value,
        total_contract_value,
        last_parsing_timestamp,
        last_translation_timestamp,
        last_enrichment_timestamp,
        last_insight_timestamp,
        ROUND((total_insights::FLOAT / NULLIF(total_catalog_documents, 0)) * 100, 2)
            AS completion_percentage,
        ROUND((documents_needing_review::FLOAT / NULLIF(total_insights, 0)) * 100, 2)
            AS manual_review_percentage,
        ROUND(COALESCE(total_invoice_value, 0) + COALESCE(total_royalty_value, 0)
            + COALESCE(total_contract_value, 0), 2) AS total_value_processed_usd
    FROM pipeline_stats
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

