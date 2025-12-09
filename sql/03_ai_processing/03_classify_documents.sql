/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Classify Documents with AI_CLASSIFY
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Use Snowflake Cortex AI_CLASSIFY to categorize documents by type,
 *   priority level, and business category using natural language categories
 *   with enhanced descriptions and examples.
 * 
 * REQUIREMENTS:
 *   - Parsed documents in STG_PARSED_DOCUMENTS
 *   - SNOWFLAKE.CORTEX_USER database role granted
 * 
 * AI FUNCTION: AI_CLASSIFY
 *   Syntax: AI_CLASSIFY(text, categories_array, options)
 *   Features: Multi-label, category descriptions, examples, task descriptions
 *   Output: JSON with label, confidence, and optional explanations
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
-- CLASSIFY DOCUMENTS: Enhanced Mode with Category Descriptions
-- ============================================================================

-- Classify documents using AI_CLASSIFY with detailed category definitions
-- This enhanced approach improves accuracy by providing context

INSERT INTO STG_CLASSIFIED_DOCS (
    classification_id,
    parsed_id,
    document_type,
    priority_level,
    business_category,
    classification_confidence,
    classification_details,
    classified_at
)
SELECT
    UUID_STRING() AS classification_id,
    parsed.parsed_id,
    -- Extract primary document type classification
    doc_classification:label::STRING AS document_type,
    -- Extract priority level (if available)
    priority_classification:label::STRING AS priority_level,
    -- Map to business category
    CASE doc_classification:label::STRING
        WHEN 'Invoice' THEN 'Accounts Payable'
        WHEN 'Royalty Statement' THEN 'Rights Management'
        WHEN 'Contract' THEN 'Legal & Compliance'
        ELSE 'General'
    END AS business_category,
    -- Extract confidence score
    doc_classification:confidence::FLOAT AS classification_confidence,
    -- Store full classification response
    OBJECT_CONSTRUCT(
        'document_classification', doc_classification,
        'priority_classification', priority_classification
    ) AS classification_details,
    CURRENT_TIMESTAMP() AS classified_at
FROM (
    SELECT
        parsed.parsed_id,
        -- Document Type Classification with enhanced categories
        AI_CLASSIFY(
            COALESCE(
                trans.translated_text,  -- Use translated text if available
                parsed.parsed_content:text::STRING  -- Otherwise use original
            ),
            [
                {
                    'category': 'Invoice',
                    'description': 'Billing documents requesting payment with itemized line items, amounts due, and payment terms',
                    'examples': ['Net 30 payment terms', 'remit payment to', 'invoice number', 'amount due', 'line items']
                },
                {
                    'category': 'Royalty Statement',
                    'description': 'Periodic reports showing rights usage, units sold, revenue distribution, and royalty payments by territory or time period',
                    'examples': ['territory performance', 'title royalties', 'payment period', 'units sold', 'gross receipts']
                },
                {
                    'category': 'Contract',
                    'description': 'Legal agreements between parties outlining terms, conditions, obligations, and rights for services or licenses',
                    'examples': ['party A and party B', 'effective date', 'confidentiality provisions', 'term of agreement', 'consideration']
                },
                {
                    'category': 'Other',
                    'description': 'Documents that do not fit the above categories, including correspondence, reports, or unclassified materials'
                }
            ]
        ) AS doc_classification,
        -- Priority Level Classification
        AI_CLASSIFY(
            COALESCE(
                trans.translated_text,
                parsed.parsed_content:text::STRING
            ),
            [
                {
                    'category': 'High',
                    'description': 'Urgent documents requiring immediate attention, such as overdue invoices, expiring contracts, or time-sensitive agreements',
                    'examples': ['overdue', 'urgent', 'immediate action required', 'deadline approaching', 'time-sensitive']
                },
                {
                    'category': 'Medium',
                    'description': 'Standard priority documents requiring attention within normal business timelines',
                    'examples': ['standard terms', 'net 30', 'quarterly statement', 'annual review']
                },
                {
                    'category': 'Low',
                    'description': 'Routine or informational documents with no immediate action required',
                    'examples': ['for your information', 'reference only', 'archive', 'courtesy copy']
                }
            ],
            {'task_description': 'Determine the urgency and priority level of this business document based on its content and context'}
        ) AS priority_classification
    FROM STG_PARSED_DOCUMENTS parsed
    LEFT JOIN STG_TRANSLATED_CONTENT trans ON parsed.parsed_id = trans.parsed_id
    WHERE parsed.parsed_content:text::STRING IS NOT NULL
    -- Limit to prevent timeout
    LIMIT 100
) classifications;

-- Log classification attempts
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
    'CLASSIFY' AS processing_step,
    classified.classified_at AS started_at,
    classified.classified_at AS completed_at,
    UNIFORM(1, 5, RANDOM()) AS duration_seconds,  -- Simulated
    CASE 
        WHEN classified.document_type IS NOT NULL THEN 'SUCCESS'
        ELSE 'FAILED'
    END AS status
FROM STG_CLASSIFIED_DOCS classified
JOIN STG_PARSED_DOCUMENTS parsed ON classified.parsed_id = parsed.parsed_id;

-- ============================================================================
-- BASIC CLASSIFICATION (Simpler, Faster Alternative)
-- ============================================================================

-- For simpler use cases, use basic category list without descriptions:
/*
INSERT INTO STG_CLASSIFIED_DOCS (...)
SELECT
    UUID_STRING() AS classification_id,
    parsed_id,
    AI_CLASSIFY(
        text_content,
        ['Invoice', 'Royalty Statement', 'Contract', 'Other']
    ):label::STRING AS document_type,
    AI_CLASSIFY(
        text_content,
        ['High', 'Medium', 'Low']
    ):label::STRING AS priority_level,
    ...
FROM STG_PARSED_DOCUMENTS;
*/

-- ============================================================================
-- MULTI-LABEL CLASSIFICATION
-- ============================================================================

-- For documents that may belong to multiple categories:
/*
CREATE OR REPLACE TEMPORARY TABLE multi_label_classification AS
SELECT
    parsed_id,
    AI_CLASSIFY(
        text_content,
        ['Financial', 'Legal', 'Creative', 'Technical', 'Administrative'],
        {'multi_label': TRUE, 'max_labels': 3}
    ) AS multi_categories
FROM STG_PARSED_DOCUMENTS;

-- Extract all assigned labels
SELECT
    parsed_id,
    label.value:category::STRING AS category,
    label.value:confidence::FLOAT AS confidence
FROM multi_label_classification,
LATERAL FLATTEN(input => multi_categories:labels) label
WHERE label.value:confidence::FLOAT > 0.5;  -- Filter by confidence threshold
*/

-- ============================================================================
-- VERIFICATION & ANALYTICS
-- ============================================================================

-- Classification distribution
SELECT 
    document_type,
    priority_level,
    business_category,
    COUNT(*) AS document_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage,
    AVG(classification_confidence) AS avg_confidence
FROM STG_CLASSIFIED_DOCS
GROUP BY document_type, priority_level, business_category
ORDER BY document_count DESC;

-- High-priority documents requiring attention
SELECT 
    classified.classification_id,
    parsed.document_id,
    classified.document_type,
    classified.priority_level,
    classified.classification_confidence,
    -- Preview of document content
    SUBSTR(parsed.parsed_content:text::STRING, 1, 200) AS content_preview
FROM STG_CLASSIFIED_DOCS classified
JOIN STG_PARSED_DOCUMENTS parsed ON classified.parsed_id = parsed.parsed_id
WHERE classified.priority_level = 'High'
ORDER BY classified.classification_confidence DESC
LIMIT 20;

-- Confidence score analysis
SELECT 
    document_type,
    COUNT(*) AS document_count,
    ROUND(AVG(classification_confidence), 4) AS avg_confidence,
    ROUND(MIN(classification_confidence), 4) AS min_confidence,
    ROUND(MAX(classification_confidence), 4) AS max_confidence,
    -- Flag low-confidence classifications
    SUM(CASE WHEN classification_confidence < 0.70 THEN 1 ELSE 0 END) AS low_confidence_count
FROM STG_CLASSIFIED_DOCS
GROUP BY document_type
ORDER BY avg_confidence DESC;

SELECT 'Classification complete - check STG_CLASSIFIED_DOCS for results' AS final_status;

-- ============================================================================
-- PRODUCTION NOTES
-- ============================================================================

/*
FOR PRODUCTION DEPLOYMENT:

1. **Category Design:**
   - Keep categories mutually exclusive for single-label classification
   - Provide clear, distinct descriptions
   - Include 3-5 relevant examples per category
   - Test with representative samples to validate category definitions

2. **Enhanced Accuracy:**
   - Add task_description parameter for context
   - Provide examples that clearly differentiate similar categories
   - Use multi-label classification when documents span multiple themes
   - Iterate on category descriptions based on real-world performance

3. **Confidence Thresholds:**
   - Set minimum confidence threshold (e.g., 0.70 or 0.80)
   - Flag low-confidence classifications for manual review
   - Track confidence scores over time
   - Adjust thresholds by document type if needed

4. **Performance Optimization:**
   - Batch classifications in groups of 100-1000
   - Use parallel processing with multiple warehouses
   - Cache classification results
   - Consider pre-filtering by obvious patterns before AI classification

5. **Error Handling:**
   - Wrap AI_CLASSIFY in TRY_CAST for graceful failures
   - Log classification failures and ambiguous results
   - Implement fallback classification rules
   - Set timeout limits for very long documents

6. **Quality Assurance:**
   - Create test dataset with known classifications
   - Measure precision and recall
   - A/B test different category descriptions
   - Manual review of random sample (e.g., 5% of classified documents)

7. **Cost Management:**
   - AI_CLASSIFY costs per classification request
   - Classify only once per document (cache results)
   - Use simpler categories when possible
   - Consider rule-based pre-filtering for obvious cases

8. **Continuous Improvement:**
   - Track misclassifications
   - Refine category descriptions based on errors
   - Add new categories as business needs evolve
   - Retrain/reclassify when category definitions change
*/
