# updatetheworld Audit Report

**Project:** swiftclaw (AI Document Processing for Entertainment Industry)
**Audit Date:** 2026-02-17
**Snowflake Docs Verified:** 2026-02-17 via Cortex Search MCP
**Prior Audit:** None found (first audit)

## Executive Summary

- **Features Scanned:** 14
- **Doc Lookups:** 17 (original 12 + 5 backlog validation)
- **Findings:** 11 (2 Critical, 3 High, 4 Medium, 2 Low)
- **ALL FINDINGS IMPLEMENTED** (except Finding 11, cancelled)

All findings have been validated against current Snowflake documentation and implemented.
The enrichment pipeline now uses **AI_EXTRACT** (GA Oct 2025) for structured entity extraction
directly from files and **AI_CLASSIFY** (GA Jun 2025) for purpose-built document classification,
replacing the previous AI_COMPLETE + prompt engineering approach. AI_PARSE_DOCUMENT now
includes image extraction (Preview Jan 2026). The V_PROCESSING_METRICS view was optimized
from 14 scalar subqueries to 5 table scans using conditional aggregation.

---

## Critical (Fix Immediately)

### Finding 1: Model `snowflake-arctic` Has Limited Regional Availability

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:283`

**Current Code:**

```sql
AI_COMPLETE(
    model => 'snowflake-arctic',
    prompt => CONCAT(...),
    model_parameters => OBJECT_CONSTRUCT('temperature', 0, 'max_tokens', 2048),
    response_format => OBJECT_CONSTRUCT(...)
)
```

**Issue:** `snowflake-arctic` is listed as a supported model but has **extremely limited
regional availability** (not shown as available in most native regions — only via cross-region
in select areas). This means deployments in many Snowflake regions will fail silently or error.
Additionally, it is an older, smaller model with weaker structured-output capabilities compared
to current alternatives.

**Documentation Evidence:**
- Source: Snowflake Docs — "AI_COMPLETE (Single string)" model list + regional availability
- Verified: 2026-02-17
- Status: Available but limited; NOT deprecated

**Recommended:**

```sql
AI_COMPLETE(
    model => 'llama3.1-70b',
    prompt => CONCAT(...),
    model_parameters => {'temperature': 0, 'max_tokens': 4096},
    response_format => {'type': 'json', 'schema': { ... }}
)
```

**Why `llama3.1-70b`:**
- Available in **all 8 native regions** plus cross-region (widest availability of any model)
- Strong structured output quality for JSON extraction
- Well-tested with response_format JSON schema

**Alternative models by use case:**
| Model | Availability | Best For |
|-------|-------------|----------|
| `llama3.1-70b` | All regions | General extraction, best coverage |
| `snowflake-llama-3.3-70b` | Limited | Higher quality, Snowflake-optimized |
| `mistral-large2` | All regions | Strong alternative, good JSON |
| `claude-3-5-sonnet` | Limited | Highest quality extraction |

**Impact:**
- Reliability: Deployments work in ALL Snowflake regions
- Quality: Significantly better structured output accuracy
- Cost: Similar token pricing

**Migration Risk:** LOW
- Breaking Changes: None (model parameter is a string swap)
- Rollback: Change model string back

**Priority:** CRITICAL

---

### Finding 2: `.demo-config` Expiration Date Is Stale

**File:** `.demo-config:12`

**Current Code:**

```
DEMO_EXPIRATION_DATE=2025-12-24
```

**Issue:** The `.demo-config` file shows expiration date `2025-12-24` (already passed), while
all SQL files, README, and Streamlit app consistently use `2026-02-20`. This config file is
the "single source of truth" per its own header comment. The mismatch means any automation
reading this file (e.g., `extendexpiration` tool) would consider the demo expired.

**Recommended:**

```
DEMO_EXPIRATION_DATE=2026-02-20
```

**Impact:**
- Tooling: Any script reading `.demo-config` gets wrong date
- Consistency: Breaks single-source-of-truth pattern

**Migration Risk:** NONE

**Priority:** CRITICAL

---

## High Priority (This Sprint)

### Finding 3: STG_ENRICHED_DOCUMENTS Should Be a Dynamic Table

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:219-349`

**Current Code:**

```sql
-- Regular TABLE + Stored Procedure + Task pattern (130+ lines)
CREATE OR REPLACE TABLE STG_ENRICHED_DOCUMENTS (...);
CREATE OR REPLACE PROCEDURE REFRESH_ENRICHED_DOCUMENTS() ...;
CREATE OR REPLACE TASK REFRESH_ENRICHED_DOCUMENTS_TASK ...;
ALTER TASK REFRESH_ENRICHED_DOCUMENTS_TASK RESUME;
```

**Issue:** As of **September 11, 2025**, Snowflake supports Cortex AI Functions in Dynamic
Tables (both incremental and full refresh modes). The current Task + Procedure pattern is
130+ lines of boilerplate that the Dynamic Table scheduler handles automatically. This was
the correct approach when the project was created (Nov 2024) but is now unnecessary.

**Documentation Evidence:**
- Source: "Sep 11, 2025: Support for Snowflake Cortex AI Functions in incremental dynamic table refresh"
- Source: Dynamic Table supported queries — TRANSLATE (SNOWFLAKE.CORTEX): "Supported in the SELECT clause"
- Verified: 2026-02-17

**Recommended:**

```sql
CREATE OR REPLACE DYNAMIC TABLE STG_ENRICHED_DOCUMENTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
AS
SELECT
    parsed.document_id,
    COALESCE(enriched.document_type, parsed.document_type) AS document_type,
    enriched.priority_level,
    enriched.business_category,
    enriched.total_amount,
    enriched.currency,
    enriched.document_date,
    enriched.vendor_territory,
    enriched.confidence_score,
    enriched.enrichment_json AS enrichment_details,
    CURRENT_TIMESTAMP() AS enriched_at
FROM STG_PARSED_DOCUMENTS parsed
LEFT JOIN STG_TRANSLATED_CONTENT trans
    ON parsed.document_id = trans.document_id
CROSS JOIN LATERAL (
    SELECT TRY_PARSE_JSON(
        AI_COMPLETE(
            model => 'llama3.1-70b',
            prompt => CONCAT(
                'You are a data extraction system. Return only JSON. ',
                'Document text: ',
                SUBSTR(COALESCE(trans.translated_text, parsed.parsed_content:content::STRING), 1, 12000)
            ),
            model_parameters => {'temperature': 0, 'max_tokens': 4096},
            response_format => { ... }  -- same JSON schema
        )
    ) AS enrichment_json
) enriched
WHERE parsed.parsed_content:content::STRING IS NOT NULL;
```

**Impact:**
- Code: -60% (eliminates procedure + task + ALTER TASK RESUME)
- Maintenance: Automatic refresh orchestration, no manual task management
- Reliability: DT scheduler handles retries and incremental processing
- Cleanup: Teardown script simplified (remove task + procedure drops)

**Migration Risk:** LOW
- Breaking Changes: Column names preserved
- Rollback: Re-create table + procedure + task from git history

**Priority:** HIGH

---

### Finding 4: AI_EXTRACT Can Replace AI_PARSE_DOCUMENT + AI_COMPLETE for Enrichment -- IMPLEMENTED

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:156-185` and `219-349`

**Current Pipeline (3 steps):**

```
Step 1: AI_PARSE_DOCUMENT(file) -> raw text
Step 2: AI_TRANSLATE(text) -> English text
Step 3: AI_COMPLETE(text, prompt, schema) -> structured JSON
```

**Issue:** The new **AI_EXTRACT** function (GA October 16, 2025) can extract structured data
**directly from files** on a stage, eliminating the need for AI_PARSE_DOCUMENT + AI_COMPLETE
for the enrichment path. AI_EXTRACT supports 29 languages natively, handles parsing internally,
and produces structured output with a simple `responseFormat` argument.

**Documentation Evidence:**
- Source: "Oct 16, 2025: AI_EXTRACT function (General availability)"
- Source: "Extracting information from documents with AI_EXTRACT"
- Verified: 2026-02-17

**Recommended (for enrichment):**

```sql
CREATE OR REPLACE DYNAMIC TABLE STG_ENRICHED_DOCUMENTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
AS
SELECT
    catalog.document_id,
    catalog.document_type AS catalog_document_type,
    AI_EXTRACT(
        file => TO_FILE(catalog.stage_name, catalog.file_path),
        responseFormat => {
            'schema': {
                'type': 'object',
                'properties': {
                    'document_type': {'description': 'Document type: INVOICE, ROYALTY_STATEMENT, CONTRACT, or OTHER', 'type': 'string'},
                    'priority_level': {'description': 'Priority: HIGH, MEDIUM, or LOW', 'type': 'string'},
                    'business_category': {'description': 'Category: ACCOUNTS_PAYABLE, RIGHTS_MANAGEMENT, LEGAL_COMPLIANCE, or GENERAL', 'type': 'string'},
                    'total_amount': {'description': 'Total monetary amount in the document', 'type': 'number'},
                    'currency': {'description': 'Currency code (e.g., USD, EUR)', 'type': 'string'},
                    'document_date': {'description': 'Primary date in the document (YYYY-MM-DD)', 'type': 'string'},
                    'vendor_territory': {'description': 'Vendor or territory name', 'type': 'string'},
                    'confidence_score': {'description': 'Extraction confidence 0.0-1.0', 'type': 'number'}
                }
            }
        }
    ) AS extraction_result
FROM RAW_DOCUMENT_CATALOG catalog
WHERE catalog.file_format = 'PDF';
```

**NOTE:** Keep STG_PARSED_DOCUMENTS and STG_TRANSLATED_CONTENT as they serve the Streamlit
dashboard for displaying raw parsed text and translations. AI_EXTRACT would be an **additional**
path specifically for structured enrichment.

**Impact:**
- Code: -70% for enrichment step (eliminates prompt engineering, TRY_PARSE_JSON wrapping)
- Quality: Purpose-built extraction model vs. general-purpose LLM
- Cost: AI_EXTRACT has predictable pricing vs. AI_COMPLETE token-based
- Features: Supports 29 languages natively (vs. manual translate-then-extract)

**Migration Risk:** MEDIUM
- Breaking Changes: Output format differs (need to map AI_EXTRACT output to existing columns)
- Rollback: Re-create AI_COMPLETE-based enrichment
- Testing: Validate extraction quality against AI_COMPLETE results

**Priority:** HIGH

**IMPLEMENTED (2026-02-17):** AI_EXTRACT replaces AI_COMPLETE in STG_ENRICHED_DOCUMENTS.
Uses simple key-question responseFormat for entity extraction directly from files.
Confidence score derived from field extraction completeness (6 fields, 0.0-1.0) which is
more meaningful than LLM self-assessed confidence. All downstream column names preserved.

---

### Finding 5: Dynamic Tables Should Specify REFRESH_MODE = INCREMENTAL

**Files:** `sql/03_ai_processing/01_create_dynamic_tables.sql:156, 191, 355`

**Current Code:**

```sql
CREATE OR REPLACE DYNAMIC TABLE STG_PARSED_DOCUMENTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
AS ...
```

**Issue:** Dynamic tables default to `REFRESH_MODE = AUTO`, which lets Snowflake choose. For
tables using Cortex AI Functions, explicitly setting `REFRESH_MODE = INCREMENTAL` ensures:
1. Only new/changed rows are processed (critical for expensive AI function calls)
2. AI functions aren't re-called on unchanged data
3. Cost is proportional to new data, not total data

**Documentation Evidence:**
- Source: "Sep 11, 2025: Support for Snowflake Cortex AI Functions in incremental dynamic table refresh"
- Source: "Dynamic table refresh modes"
- Verified: 2026-02-17

**Recommended:**

```sql
CREATE OR REPLACE DYNAMIC TABLE STG_PARSED_DOCUMENTS
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
AS ...
```

**Impact:**
- Cost: Prevents re-processing all documents on every refresh
- Performance: Only new documents trigger AI function calls

**Migration Risk:** LOW
- Breaking Changes: None if queries are incremental-compatible (they are)

**Priority:** HIGH

---

## Medium Priority (Next Month)

### Finding 6: Replace OBJECT_CONSTRUCT with Object Literal Syntax

**Files:** `sql/03_ai_processing/01_create_dynamic_tables.sql` (multiple locations)

**Current Code:**

```sql
OBJECT_CONSTRUCT('mode', 'LAYOUT', 'page_split', FALSE)
OBJECT_CONSTRUCT('temperature', 0, 'max_tokens', 2048)
OBJECT_CONSTRUCT('type', 'json', 'schema', OBJECT_CONSTRUCT(...))
```

**Issue:** Snowflake now supports object literal syntax (`{...}`) which is significantly
more readable and matches the syntax shown in current documentation examples.

**Documentation Evidence:**
- Source: "OBJECT constants" — `{ 'key1': 'value1', 'key2': 'value2' }` syntax
- Source: AI_COMPLETE examples now use `{'temperature': 0}` syntax
- Verified: 2026-02-17

**Recommended:**

```sql
{'mode': 'LAYOUT', 'page_split': FALSE}
{'temperature': 0, 'max_tokens': 4096}
{'type': 'json', 'schema': {'type': 'object', 'properties': { ... }}}
```

**Impact:**
- Readability: Significantly cleaner, especially for nested objects
- Maintenance: Matches current Snowflake documentation style
- Code: ~40% reduction in object construction verbosity

**Migration Risk:** NONE

**Priority:** MEDIUM

---

### Finding 7: AI_CLASSIFY for Document Type Classification -- IMPLEMENTED

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:282-334`

**Current Approach:** Uses AI_COMPLETE with prompt engineering for document classification
(embedding classification within the extraction JSON schema).

**Issue:** The purpose-built **AI_CLASSIFY** function (GA, supports up to 500 labels and
multi-label classification as of Jun 2025) is specifically designed for classification tasks.
It provides standardized output, no prompt engineering needed, and predictable pricing.

**Documentation Evidence:**
- Source: "Jun 02, 2025: AI_CLASSIFY supports up to 500 labels and multi-label classification"
- Source: AI_CLASSIFY function reference
- Verified: 2026-02-17

**Recommended (if classification separated from extraction):**

```sql
AI_CLASSIFY(
    analysis_text,
    [
        {'label': 'INVOICE', 'description': 'Billing document with amounts, dates, and vendor'},
        {'label': 'ROYALTY_STATEMENT', 'description': 'Entertainment royalty payment statement'},
        {'label': 'CONTRACT', 'description': 'Legal agreement between parties'},
        {'label': 'OTHER', 'description': 'Document not matching other categories'}
    ]
) AS document_classification
```

**Impact:**
- Quality: Purpose-built classifier vs. general LLM
- Cost: Lower per-call cost than AI_COMPLETE

**Migration Risk:** LOW

**Priority:** MEDIUM

**IMPLEMENTED (2026-02-17):** AI_CLASSIFY added to STG_ENRICHED_DOCUMENTS alongside AI_EXTRACT.
Uses label descriptions for all 4 document types (INVOICE, ROYALTY_STATEMENT, CONTRACT, OTHER).
COALESCE falls back to catalog-derived document_type when AI_CLASSIFY returns NULL.

---

### Finding 8: AI_PARSE_DOCUMENT `extract_images` Option -- IMPLEMENTED

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:181`

**Current Code:**

```sql
AI_PARSE_DOCUMENT(
    TO_FILE(catalog.stage_name, catalog.file_path),
    OBJECT_CONSTRUCT('mode', 'LAYOUT', 'page_split', FALSE)
)
```

**Issue:** AI_PARSE_DOCUMENT now supports `'extract_images': TRUE` (requires LAYOUT mode,
which the project already uses). This could enable image extraction from contracts, invoices
with logos, etc.

**Documentation Evidence:**
- Source: "Aug 21, 2025: AI Parse Document layout mode (General availability)"
- Source: AI_PARSE_DOCUMENT options — `'extract_images'` parameter
- Verified: 2026-02-17

**Recommended:**

```sql
AI_PARSE_DOCUMENT(
    TO_FILE(catalog.stage_name, catalog.file_path),
    {'mode': 'LAYOUT', 'page_split': FALSE, 'extract_images': TRUE}
)
```

**Impact:**
- Features: Enables image-aware document processing
- Demo value: More impressive extraction capabilities

**Migration Risk:** NONE (additive feature)

**Priority:** MEDIUM

**IMPLEMENTED (2026-02-17):** Added `'extract_images': TRUE` to AI_PARSE_DOCUMENT options in
STG_PARSED_DOCUMENTS. Images extracted as base64 in parsed_content JSON for downstream use.
Note: extract_images is in Preview (Jan 26, 2026) — no additional cost.

---

### Finding 9: V_PROCESSING_METRICS Uses Correlated Subqueries -- IMPLEMENTED

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:406-479`

**Current Code:**

```sql
WITH pipeline_stats AS (
    SELECT
        (SELECT COUNT(*) FROM RAW_DOCUMENT_CATALOG) AS total_catalog_documents,
        (SELECT COUNT(*) FROM STG_PARSED_DOCUMENTS) AS total_parsed,
        (SELECT COUNT(*) FROM STG_TRANSLATED_CONTENT) AS total_translated,
        -- ... 11 more scalar subqueries
)
```

**Issue:** 14 scalar subqueries hitting 4 different tables. While acceptable for a demo view
queried infrequently, this pattern scans multiple tables repeatedly. A more efficient approach
would use UNION ALL with aggregation or a single pass with conditional aggregation.

**Impact:**
- Performance: 14 separate table scans per view query
- Demo only: Acceptable for demo but not production-grade

**Migration Risk:** LOW

**Priority:** MEDIUM

**IMPLEMENTED (2026-02-17):** Consolidated 14 scalar subqueries into 5 CTEs (one per source
table). FCT_DOCUMENT_INSIGHTS scan uses COUNT_IF and SUM(IFF(...)) for conditional aggregation.
Each table scanned exactly once. Cross-joined in metrics CTE for final calculation.

---

## Low Priority (Backlog)

### Finding 10: CAST(NULL AS NUMBER) Placeholder Column

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:368`

**Current Code:**

```sql
CAST(NULL AS NUMBER) AS processing_time_seconds,
```

**Issue:** This column is always NULL and serves no purpose in the current pipeline. The
Streamlit dashboard references it but never displays it meaningfully. Either implement it
(using DT refresh metadata) or remove it.

**Recommended:** Remove the column or replace with actual timing from
`INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY()`.

**Priority:** LOW

---

### Finding 11: AI_COMPLETE `show_details` Parameter -- CANCELLED

**Issue:** AI_COMPLETE now supports `show_details => true` which returns inference metadata
(model, token counts, etc.). This could enhance the monitoring/metrics view.

**Documentation Evidence:**
- Source: AI_COMPLETE examples with `show_details => true`
- Verified: 2026-02-17

**Priority:** LOW

**CANCELLED (2026-02-17):** AI_COMPLETE has been fully replaced by AI_EXTRACT + AI_CLASSIFY
in the enrichment pipeline. AI_EXTRACT does not support a `show_details` parameter, making
this finding moot. For token cost estimation, consider AI_COUNT_TOKENS (GA Jan 2026).

---

## Modernization Opportunities Summary

| Current Pattern | Modern Alternative | Impact | Risk | Finding | Status |
|---|---|---|---|---|---|
| `snowflake-arctic` model | `llama3.1-70b` | Regional reliability | None | #1 | DONE |
| Task + Procedure enrichment | Dynamic Table | -60% code | Low | #3 | DONE |
| AI_COMPLETE for enrichment | AI_EXTRACT on file | -70% enrichment code | Medium | #4 | DONE |
| Default REFRESH_MODE | Explicit INCREMENTAL | Cost savings | None | #5 | DONE |
| OBJECT_CONSTRUCT() | `{...}` literals | Readability | None | #6 | DONE |
| AI_COMPLETE for classification | AI_CLASSIFY | Purpose-built | Low | #7 | DONE |
| No extract_images | `'extract_images': TRUE` | Feature upgrade | None | #8 | DONE |
| 14 scalar subqueries | 5 scans + conditional agg | Performance | None | #9 | DONE |
| AI_COMPLETE show_details | N/A (AI_COMPLETE removed) | N/A | N/A | #11 | CANCELLED |

## Documentation Evidence Log

| Feature | Doc Source | Verified | Status |
|---|---|---|---|
| AI_PARSE_DOCUMENT syntax | Snowflake Docs - AI_PARSE_DOCUMENT | 2026-02-17 | GA (Aug 2025 layout mode) |
| AI_TRANSLATE syntax | Snowflake Docs - AI_TRANSLATE | 2026-02-17 | GA (Sep 2025) |
| AI_COMPLETE models + structured output | Snowflake Docs - AI_COMPLETE | 2026-02-17 | GA + structured preview |
| AI_EXTRACT | Snowflake Docs - AI_EXTRACT | 2026-02-17 | GA (Oct 2025) |
| AI_CLASSIFY | Snowflake Docs - AI_CLASSIFY | 2026-02-17 | GA (Jun 2025 multi-label) |
| Dynamic Table + Cortex AI | Snowflake Docs - DT supported queries | 2026-02-17 | GA (Sep 2025) |
| Dynamic Table REFRESH_MODE | Snowflake Docs - DT refresh modes | 2026-02-17 | GA |
| CREATE STREAMLIT FROM | Snowflake Docs - CREATE STREAMLIT | 2026-02-17 | GA (2025_01 bundle) |
| Object literal syntax | Snowflake Docs - OBJECT constants | 2026-02-17 | GA |
| Model deprecation list | Snowflake Docs - Model deprecation | 2026-02-17 | 2025_05 bundle |
| COPY FILES command | Project verified | 2026-02-17 | GA |
| TO_FILE function | Snowflake Docs - AI_PARSE_DOCUMENT | 2026-02-17 | GA |

## What's Already Correct

The project gets these right and requires no changes:

- **AI_PARSE_DOCUMENT** — Uses correct modern function (not deprecated SNOWFLAKE.CORTEX.PARSE_DOCUMENT)
- **AI_TRANSLATE** — Uses correct modern function (not deprecated SNOWFLAKE.CORTEX.TRANSLATE)
- **TO_FILE()** — Correct syntax for file references
- **CREATE STREAMLIT FROM** — Uses modern FROM syntax (not deprecated ROOT_LOCATION)
- **COPY FILES** — Correct syntax for Git-to-stage file transfer
- **Dynamic Table TARGET_LAG** — Valid syntax and reasonable 10-minute lag
- **Warehouse sizing** — XSMALL with 60s auto-suspend is appropriate for demo
- **ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')** — Correct stage encryption
- **DIRECTORY = (ENABLE = TRUE)** — Correct for stage directory tables
- **Expiration guard** — EXECUTE IMMEDIATE with exception is best practice for demo expiration
- **Git Repository integration** — Correct CREATE GIT REPOSITORY syntax
- **No SELECT * in any SQL** — All queries project explicit columns
- **No hardcoded credentials** — No secrets in code
- **Streamlit app** — Clean, well-structured with proper session management

---

*Generated by updatetheworld audit | 2026-02-17*
