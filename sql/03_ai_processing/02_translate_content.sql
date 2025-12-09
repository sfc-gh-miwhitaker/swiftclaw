/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Translate Content with AI_TRANSLATE
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Use Snowflake Cortex AI_TRANSLATE to convert non-English content to English
 *   while preserving entertainment industry context (names, terminology).
 * 
 * REQUIREMENTS:
 *   - Parsed documents in STG_PARSED_DOCUMENTS
 *   - SNOWFLAKE.CORTEX_USER database role granted
 * 
 * AI FUNCTION: AI_TRANSLATE
 *   Syntax: AI_TRANSLATE(text, source_language, target_language)
 *   Supports: 20+ languages including auto-detection ('')
 *   Quality: Best results when English is source or target
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community
 * Created: 2025-11-24 | Updated: 2025-12-09 | Expires: 2025-12-24
 ******************************************************************************/

-- Set context
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SFE_STG_ENTERTAINMENT;
USE WAREHOUSE SFE_DOCUMENT_AI_WH;

-- ============================================================================
-- TRANSLATE NON-ENGLISH DOCUMENTS
-- ============================================================================

-- Translate parsed documents where source language is not English
INSERT INTO STG_TRANSLATED_CONTENT (
    translation_id,
    parsed_id,
    source_language,
    target_language,
    source_text,
    translated_text,
    translation_confidence,
    translated_at
)
SELECT
    UUID_STRING() AS translation_id,
    parsed.parsed_id,
    catalog.original_language AS source_language,
    'en' AS target_language,
    -- Extract text from parsed content
    parsed.parsed_content:text::STRING AS source_text,
    -- Call AI_TRANSLATE with source and target languages
    AI_TRANSLATE(
        parsed.parsed_content:text::STRING,
        catalog.original_language,  -- Source language (e.g., 'es', 'fr')
        'en'  -- Target language (English)
    ) AS translated_text,
    UNIFORM(0.88, 0.99, RANDOM()) AS translation_confidence,  -- Simulated for demo
    CURRENT_TIMESTAMP() AS translated_at
FROM STG_PARSED_DOCUMENTS parsed
JOIN SFE_RAW_ENTERTAINMENT.DOCUMENT_CATALOG catalog 
    ON parsed.document_id = catalog.document_id
WHERE catalog.original_language <> 'en'  -- Only translate non-English
AND parsed.parsed_content:text::STRING IS NOT NULL  -- Has extractable text
-- Limit to prevent timeout
LIMIT 100;

-- Log translation attempts
INSERT INTO SFE_RAW_ENTERTAINMENT.DOCUMENT_PROCESSING_LOG (
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
    'TRANSLATE' AS processing_step,
    trans.translated_at AS started_at,
    trans.translated_at AS completed_at,
    UNIFORM(2, 10, RANDOM()) AS duration_seconds,  -- Simulated
    CASE 
        WHEN trans.translated_text IS NOT NULL THEN 'SUCCESS'
        ELSE 'FAILED'
    END AS status
FROM STG_TRANSLATED_CONTENT trans
JOIN STG_PARSED_DOCUMENTS parsed ON trans.parsed_id = parsed.parsed_id;

-- ============================================================================
-- AUTO-DETECT LANGUAGE MODE
-- ============================================================================

-- For documents where source language is unknown, use auto-detection
-- AI_TRANSLATE accepts empty string '' for source language to auto-detect

/*
INSERT INTO STG_TRANSLATED_CONTENT (...)
SELECT
    UUID_STRING() AS translation_id,
    parsed_id,
    '' AS source_language,  -- Auto-detect
    'en' AS target_language,
    source_text,
    AI_TRANSLATE(
        source_text,
        '',  -- Empty string triggers auto-detection
        'en'
    ) AS translated_text,
    ...
FROM STG_PARSED_DOCUMENTS
WHERE ... ;
*/

-- ============================================================================
-- QUALITY TEST: Russian Names Preservation
-- ============================================================================

-- Test case: Ensure proper nouns (Russian names that are also occupations)
-- are preserved correctly and not mistranslated

CREATE OR REPLACE TEMPORARY TABLE russian_name_test AS
SELECT * FROM (VALUES
    ('Режиссер Иван Пекарь работает в Москве', 'Ivan Pekar', 'director', 'Пекарь means Baker'),
    ('Актриса Анна Кузнец получила главную роль', 'Anna Kuznets', 'actress', 'Кузнец means Smith'),
    ('Продюсер Сергей Плотник снимает фильм', 'Sergey Plotnik', 'producer', 'Плотник means Carpenter')
) AS t(russian_text, expected_name, occupation, note);

-- Run translation quality test
CREATE OR REPLACE TEMPORARY TABLE russian_translation_results AS
SELECT
    russian_text,
    expected_name,
    occupation,
    note,
    AI_TRANSLATE(russian_text, 'ru', 'en') AS translated_text,
    -- Check if name is preserved (not translated to occupation)
    CASE
        WHEN CONTAINS(AI_TRANSLATE(russian_text, 'ru', 'en'), expected_name) 
        THEN TRUE
        ELSE FALSE
    END AS name_preserved_correctly
FROM russian_name_test;

-- Display test results
SELECT
    '🔬 Russian Name Translation Quality Test' AS test_category,
    COUNT(*) AS total_test_cases,
    SUM(CASE WHEN name_preserved_correctly THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN NOT name_preserved_correctly THEN 1 ELSE 0 END) AS failed,
    CASE 
        WHEN SUM(CASE WHEN NOT name_preserved_correctly THEN 1 ELSE 0 END) = 0 
        THEN '✅ PASS - All names correctly preserved'
        ELSE '⚠️  FAIL - Some names mistranslated'
    END AS test_result
FROM russian_translation_results;

-- Show detailed results
SELECT
    russian_text AS original,
    translated_text AS translation,
    expected_name AS expected_name_preservation,
    CASE 
        WHEN name_preserved_correctly 
        THEN '✅ Correct' 
        ELSE '❌ Failed'
    END AS result,
    note
FROM russian_translation_results
ORDER BY name_preserved_correctly ASC, russian_text;

-- ============================================================================
-- VERIFICATION & ANALYTICS
-- ============================================================================

-- Translation coverage summary
SELECT 
    source_language,
    target_language,
    COUNT(*) AS translations_performed,
    AVG(translation_confidence) AS avg_confidence,
    MIN(translation_confidence) AS min_confidence,
    AVG(LENGTH(translated_text)) AS avg_translated_length
FROM STG_TRANSLATED_CONTENT
GROUP BY source_language, target_language;

-- Sample translated content
SELECT 
    trans.source_language,
    trans.target_language,
    -- Show first 100 characters of source and translated text
    SUBSTR(trans.source_text, 1, 100) AS source_preview,
    SUBSTR(trans.translated_text, 1, 100) AS translated_preview,
    trans.translation_confidence,
    trans.translated_at
FROM STG_TRANSLATED_CONTENT trans
LIMIT 10;

-- Check for translation failures
SELECT 
    COUNT(*) AS failed_translations
FROM STG_TRANSLATED_CONTENT
WHERE translated_text IS NULL 
OR LENGTH(translated_text) = 0;

SELECT 'Translation processing complete - check STG_TRANSLATED_CONTENT for results' AS final_status;

-- ============================================================================
-- ADVANCED: Multi-language Translation Chain
-- ============================================================================

-- For multilingual content requiring multiple translations:
/*
-- Example: Spanish → English → French
WITH spanish_to_english AS (
    SELECT
        document_id,
        AI_TRANSLATE(source_text, 'es', 'en') AS english_text
    FROM source_documents
    WHERE source_language = 'es'
),
english_to_french AS (
    SELECT
        document_id,
        AI_TRANSLATE(english_text, 'en', 'fr') AS french_text
    FROM spanish_to_english
)
SELECT * FROM english_to_french;
*/

-- ============================================================================
-- PRODUCTION NOTES
-- ============================================================================

/*
FOR PRODUCTION DEPLOYMENT:

1. **Language Support:**
   - AI_TRANSLATE supports 20+ languages
   - Best results when English is source or target language
   - Use auto-detect ('') for unknown source languages
   - Supported languages: ar, zh, hr, cs, nl, en, fi, fr, de, el, hi, id, 
                          it, ja, ko, pl, pt, ru, es, sv, tr, uk, vi

2. **Context Preservation:**
   - Proper nouns (names, places) are generally preserved
   - Industry-specific terminology may need validation
   - For critical translations, implement quality checks
   - Consider manual review for legal/contractual documents

3. **Performance Optimization:**
   - Batch translations in groups of 100-1000 records
   - Parallel processing with multiple warehouses
   - Cache frequently translated phrases
   - Skip translation if source and target languages match

4. **Error Handling:**
   - Wrap AI_TRANSLATE in TRY_CAST for graceful failures
   - Log translation failures
   - Retry with auto-detect if specific language fails
   - Set timeout limits for very long documents

5. **Cost Management:**
   - AI_TRANSLATE costs per character processed
   - Translate only necessary fields (not entire documents if not needed)
   - Skip translation for English documents
   - Consider pre-filtering by language detection

6. **Quality Assurance:**
   - Implement test suites for critical translations
   - Track confidence scores (if available from future API updates)
   - Flag low-quality translations for manual review
   - Test with representative samples from each language
*/
