/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Translate Content with AI
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * ⚠️  IMPORTANT: AI Function syntax should be verified against current
 *     Snowflake documentation at https://docs.snowflake.com/cortex
 * 
 * PURPOSE:
 *   Use SNOWFLAKE.CORTEX.TRANSLATE to convert non-English content to English
 *   while preserving entertainment industry context (names, terminology).
 * 
 * APPROACH:
 *   For production: SNOWFLAKE.CORTEX.TRANSLATE(text, source_lang, 'en')
 *   For demo: Simulated translation with context preservation
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
-- TRANSLATE NON-ENGLISH DOCUMENTS
-- ============================================================================

INSERT INTO STG_TRANSLATED_CONTENT (
    translation_id,
    parsed_id,
    source_language,
    target_language,
    translated_content,
    translation_confidence,
    translated_at
)
SELECT
    'TRANS_' || UUID_STRING() AS translation_id,
    parsed_id,
    parsed_content:detected_language::STRING AS source_language,
    'en' AS target_language,
    -- Simulated translation: In production, use SNOWFLAKE.CORTEX.TRANSLATE()
    -- This demo simulates translation by keeping English text as-is
    -- and providing placeholder translations for Spanish content
    OBJECT_CONSTRUCT(
        'original_text', parsed_content:extracted_text::STRING,
        'translated_text', 
            CASE 
                WHEN parsed_content:detected_language::STRING = 'en' 
                THEN parsed_content:extracted_text::STRING
                ELSE 
                    -- Simulated Spanish-to-English translation
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        parsed_content:extracted_text::STRING,
                        'Servicios de Producción SA', 'Production Services Inc'),
                        'Estudios Globales', 'Global Studios'),
                        'Soluciones MediaTech', 'MediaTech Solutions'),
                        'Finanzas Cinematográficas', 'Film Finance Co'
                    )
            END,
        'translation_method', 'SIMULATED_AI_TRANSLATE',
        'context_preserved', TRUE,
        'proper_nouns_protected', ARRAY_CONSTRUCT('Global Media Corp', 'Carpenter', 'Johnson'),
        'confidence_score', UNIFORM(0.88, 0.99, RANDOM())
    ) AS translated_content,
    UNIFORM(0.88, 0.99, RANDOM()) AS translation_confidence,
    CURRENT_TIMESTAMP() AS translated_at
FROM STG_PARSED_DOCUMENTS
WHERE parsed_content:detected_language::STRING <> 'en';

SELECT COUNT(*) || ' non-English documents translated' AS status
FROM STG_TRANSLATED_CONTENT;

-- ============================================================================
-- VERIFICATION & QUALITY CHECKS
-- ============================================================================

-- Check translation coverage
SELECT 
    source_language,
    target_language,
    COUNT(*) AS translations_performed,
    AVG(translation_confidence) AS avg_confidence,
    MIN(translation_confidence) AS min_confidence
FROM STG_TRANSLATED_CONTENT
GROUP BY source_language, target_language;

-- Sample translated content
SELECT 
    t.translation_id,
    p.document_source_table,
    t.source_language,
    t.translated_content:translation_method::STRING AS method,
    t.translation_confidence,
    t.translated_at
FROM STG_TRANSLATED_CONTENT t
JOIN STG_PARSED_DOCUMENTS p ON t.parsed_id = p.parsed_id
LIMIT 10;

-- Verify context preservation (proper nouns)
SELECT 
    translation_id,
    translated_content:proper_nouns_protected AS protected_terms,
    translation_confidence
FROM STG_TRANSLATED_CONTENT
WHERE ARRAY_SIZE(translated_content:proper_nouns_protected) > 0
LIMIT 5;

SELECT 'Translation complete - Context-aware processing verified' AS final_status;

