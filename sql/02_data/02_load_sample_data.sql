/*******************************************************************************
 * DEMO PROJECT: AI Document Processing for Entertainment Industry
 * Script: Load Sample Data - References Real PDFs from GitHub
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Catalog real PDF documents hosted on GitHub for AI processing.
 *   Documents are accessed via external stage pointing to GitHub raw content.
 *
 * DOCUMENTS CATALOGED:
 *   From pdfs/generated/ (18 documents):
 *   - 6 Invoices (en, es, de, pt)
 *   - 6 Royalty Statements (en, es, de, pt)
 *   - 6 Contracts (en, es, de, pt)
 *
 *   From pdfs/ root (6 documents):
 *   - 6 Bridge documents (en, es, de, pt, ru, zh) - Translation demo
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
-- CATALOG GENERATED INVOICES (6 documents)
-- ============================================================================

INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
VALUES
    -- English Invoices
    ('INV_EN_001', 'INVOICE', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/invoice_en_001.pdf', 'invoice_en_001.pdf', 'PDF', 4500, 'en', 'PENDING',
     PARSE_JSON('{"vendor_name": "Acme Production Services", "invoice_number": "INV-2024-0001", "currency": "USD", "generated_for_demo": true}')),
    ('INV_EN_002', 'INVOICE', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/invoice_en_002.pdf', 'invoice_en_002.pdf', 'PDF', 4600, 'en', 'PENDING',
     PARSE_JSON('{"vendor_name": "Acme Production Services", "invoice_number": "INV-2024-0002", "currency": "USD", "generated_for_demo": true}')),
    -- Spanish Invoices
    ('INV_ES_003', 'INVOICE', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/invoice_es_003.pdf', 'invoice_es_003.pdf', 'PDF', 4700, 'es', 'PENDING',
     PARSE_JSON('{"vendor_name": "Servicios de Produccion Acme", "invoice_number": "INV-2024-0003", "currency": "USD", "generated_for_demo": true}')),
    ('INV_ES_004', 'INVOICE', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/invoice_es_004.pdf', 'invoice_es_004.pdf', 'PDF', 4800, 'es', 'PENDING',
     PARSE_JSON('{"vendor_name": "Servicios de Produccion Acme", "invoice_number": "INV-2024-0004", "currency": "USD", "generated_for_demo": true}')),
    -- German Invoice
    ('INV_DE_005', 'INVOICE', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/invoice_de_005.pdf', 'invoice_de_005.pdf', 'PDF', 4900, 'de', 'PENDING',
     PARSE_JSON('{"vendor_name": "Acme Produktionsdienstleistungen", "invoice_number": "INV-2024-0005", "currency": "USD", "generated_for_demo": true}')),
    -- Portuguese Invoice
    ('INV_PT_006', 'INVOICE', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/invoice_pt_006.pdf', 'invoice_pt_006.pdf', 'PDF', 5000, 'pt', 'PENDING',
     PARSE_JSON('{"vendor_name": "Servicos de Producao Acme", "invoice_number": "INV-2024-0006", "currency": "USD", "generated_for_demo": true}'));

SELECT '6 invoice documents cataloged from GitHub' AS status;

-- ============================================================================
-- CATALOG GENERATED ROYALTY STATEMENTS (6 documents)
-- ============================================================================

INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
VALUES
    -- English Royalty Statements
    ('ROY_EN_001', 'ROYALTY_STATEMENT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/royalty_en_001.pdf', 'royalty_en_001.pdf', 'PDF', 5500, 'en', 'PENDING',
     PARSE_JSON('{"territory": "North America", "period": "Q3 2024", "currency": "USD", "generated_for_demo": true}')),
    ('ROY_EN_002', 'ROYALTY_STATEMENT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/royalty_en_002.pdf', 'royalty_en_002.pdf', 'PDF', 5600, 'en', 'PENDING',
     PARSE_JSON('{"territory": "Europe", "period": "Q3 2024", "currency": "USD", "generated_for_demo": true}')),
    -- Spanish Royalty Statements
    ('ROY_ES_003', 'ROYALTY_STATEMENT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/royalty_es_003.pdf', 'royalty_es_003.pdf', 'PDF', 5700, 'es', 'PENDING',
     PARSE_JSON('{"territory": "America Latina", "period": "Q3 2024", "currency": "USD", "generated_for_demo": true}')),
    ('ROY_ES_004', 'ROYALTY_STATEMENT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/royalty_es_004.pdf', 'royalty_es_004.pdf', 'PDF', 5800, 'es', 'PENDING',
     PARSE_JSON('{"territory": "Europa", "period": "Q4 2024", "currency": "USD", "generated_for_demo": true}')),
    -- German Royalty Statement
    ('ROY_DE_005', 'ROYALTY_STATEMENT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/royalty_de_005.pdf', 'royalty_de_005.pdf', 'PDF', 5900, 'de', 'PENDING',
     PARSE_JSON('{"territory": "Europa", "period": "Q3 2024", "currency": "USD", "generated_for_demo": true}')),
    -- Portuguese Royalty Statement
    ('ROY_PT_006', 'ROYALTY_STATEMENT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/royalty_pt_006.pdf', 'royalty_pt_006.pdf', 'PDF', 6000, 'pt', 'PENDING',
     PARSE_JSON('{"territory": "America do Sul", "period": "Q4 2024", "currency": "USD", "generated_for_demo": true}'));

SELECT '6 royalty statement documents cataloged from GitHub' AS status;

-- ============================================================================
-- CATALOG GENERATED CONTRACTS (6 documents)
-- ============================================================================

INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
VALUES
    -- English Contracts
    ('CON_EN_001', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/contract_en_001.pdf', 'contract_en_001.pdf', 'PDF', 7500, 'en', 'PENDING',
     PARSE_JSON('{"contract_type": "Licensing Agreement", "territory": "Worldwide", "currency": "USD", "generated_for_demo": true}')),
    ('CON_EN_002', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/contract_en_002.pdf', 'contract_en_002.pdf', 'PDF', 7600, 'en', 'PENDING',
     PARSE_JSON('{"contract_type": "Distribution License", "territory": "North America", "currency": "USD", "generated_for_demo": true}')),
    -- Spanish Contracts
    ('CON_ES_003', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/contract_es_003.pdf', 'contract_es_003.pdf', 'PDF', 7700, 'es', 'PENDING',
     PARSE_JSON('{"contract_type": "Acuerdo de Licencia", "territory": "America Latina", "currency": "USD", "generated_for_demo": true}')),
    ('CON_ES_004', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/contract_es_004.pdf', 'contract_es_004.pdf', 'PDF', 7800, 'es', 'PENDING',
     PARSE_JSON('{"contract_type": "Licencia de Distribucion", "territory": "Europa", "currency": "USD", "generated_for_demo": true}')),
    -- German Contract
    ('CON_DE_005', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/contract_de_005.pdf', 'contract_de_005.pdf', 'PDF', 7900, 'de', 'PENDING',
     PARSE_JSON('{"contract_type": "Lizenzvereinbarung", "territory": "Europa", "currency": "USD", "generated_for_demo": true}')),
    -- Portuguese Contract
    ('CON_PT_006', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'generated/contract_pt_006.pdf', 'contract_pt_006.pdf', 'PDF', 8000, 'pt', 'PENDING',
     PARSE_JSON('{"contract_type": "Contrato de Licenciamento", "territory": "America do Sul", "currency": "USD", "generated_for_demo": true}'));

SELECT '6 contract documents cataloged from GitHub' AS status;

-- ============================================================================
-- CATALOG BRIDGE TRANSLATION DEMO DOCUMENTS (6 documents)
-- ============================================================================

INSERT INTO RAW_DOCUMENT_CATALOG (
    document_id,
    document_type,
    stage_name,
    file_path,
    file_name,
    file_format,
    file_size_bytes,
    original_language,
    processing_status,
    metadata
)
VALUES
    -- Bridge documents - same content in 6 languages for translation demo
    ('BRIDGE_EN', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'bridge_en.pdf', 'bridge_en.pdf', 'PDF', 15000, 'en', 'PENDING',
     PARSE_JSON('{"document_set": "bridge_translation_demo", "purpose": "Translation baseline (English)", "generated_for_demo": true}')),
    ('BRIDGE_ES', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'bridge_es.pdf', 'bridge_es.pdf', 'PDF', 15500, 'es', 'PENDING',
     PARSE_JSON('{"document_set": "bridge_translation_demo", "purpose": "Spanish translation demo", "generated_for_demo": true}')),
    ('BRIDGE_DE', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'bridge_de.pdf', 'bridge_de.pdf', 'PDF', 15200, 'de', 'PENDING',
     PARSE_JSON('{"document_set": "bridge_translation_demo", "purpose": "German translation demo", "generated_for_demo": true}')),
    ('BRIDGE_PT', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'bridge_pt.pdf', 'bridge_pt.pdf', 'PDF', 15300, 'pt', 'PENDING',
     PARSE_JSON('{"document_set": "bridge_translation_demo", "purpose": "Portuguese translation demo", "generated_for_demo": true}')),
    ('BRIDGE_RU', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'bridge_ru.pdf', 'bridge_ru.pdf', 'PDF', 16000, 'ru', 'PENDING',
     PARSE_JSON('{"document_set": "bridge_translation_demo", "purpose": "Russian translation demo", "generated_for_demo": true}')),
    ('BRIDGE_ZH', 'CONTRACT', '@SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS', 'bridge_zh.pdf', 'bridge_zh.pdf', 'PDF', 14000, 'zh', 'PENDING',
     PARSE_JSON('{"document_set": "bridge_translation_demo", "purpose": "Chinese translation demo", "generated_for_demo": true}'));

SELECT '6 bridge translation demo documents cataloged from GitHub' AS status;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check catalog summary
SELECT
    document_type,
    original_language,
    COUNT(*) AS document_count,
    processing_status
FROM RAW_DOCUMENT_CATALOG
GROUP BY document_type, original_language, processing_status
ORDER BY document_type, original_language;

-- Total documents cataloged
SELECT COUNT(*) || ' total documents cataloged and ready for AI processing' AS final_status
FROM RAW_DOCUMENT_CATALOG;

-- Verify external stage accessibility
SELECT 'Verifying GitHub stage accessibility...' AS status;
LS @SNOWFLAKE_EXAMPLE.SWIFTCLAW.GITHUB_SAMPLE_DOCS/generated/ PATTERN = '.*\.pdf';
