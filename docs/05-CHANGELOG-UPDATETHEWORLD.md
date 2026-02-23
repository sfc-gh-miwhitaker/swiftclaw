# updatetheworld Audit Report

**Project:** swiftclaw (AI Document Processing for Entertainment Industry)
**Audit Date:** 2026-02-20
**Prior Audit:** 2026-02-17 (11 findings, all resolved)
**Snowflake Docs Verified:** 2026-02-20 via Cortex Search MCP

## Executive Summary

- **Features Scanned:** 14
- **Doc Lookups:** 12 (AI_PARSE_DOCUMENT, AI_EXTRACT, AI_CLASSIFY, AI_TRANSLATE, AI_REDACT, Dynamic Tables, Streamlit CREATE FROM, model deprecation, Snowflake releases Jan-Feb 2026)
- **Findings:** 7 (1 Critical, 1 High, 3 Medium, 2 Low)
- **Implemented:** Finding 1 (Critical bug fix)

This audit is a follow-up to the 2026-02-17 audit that implemented 10 modernization
changes. The primary finding is a **critical bug** in the AI_CLASSIFY output extraction
introduced during the prior audit's implementation. Additionally, the demo expiration
date has been reached (2026-02-20), and several new modernization opportunities were
identified (AI_REDACT GA, AI_EXTRACT table extraction, AI_CLASSIFY config options).

---

## Critical (Fix Immediately)

### Finding 1: AI_CLASSIFY Output Not Properly Extracted — IMPLEMENTED

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:248`

**Current Code (before fix):**

```sql
COALESCE(base.ai_document_type, base.catalog_document_type) AS document_type,
```

**Issue:** AI_CLASSIFY returns a JSON object `{"labels": ["INVOICE"]}`, NOT a plain string
like `"INVOICE"`. The COALESCE treats this VARIANT as non-null (which it always is, since
AI_CLASSIFY always returns a JSON object), so it never falls through to
`catalog_document_type`. The resulting `document_type` column contains the full JSON object
string instead of the clean label.

**Cascade Impact:**
- `FCT_DOCUMENT_INSIGHTS.document_type` inherits the broken value
- Streamlit dashboard filters (`document_type IN ('INVOICE', ...)`) never match the JSON string
- Charts and manual review queue show zero or incorrectly formatted results
- The `V_PROCESSING_METRICS` aggregations by document type produce wrong breakdowns

**Documentation Evidence:**
- Source: Snowflake Docs — AI_CLASSIFY examples show `AI_CLASSIFY(...):labels AS classification`
- Output format: `'{"labels": ["travel"]}'` (always JSON with labels array)
- Verified: 2026-02-20

**Fix Applied:**

```sql
-- AI_CLASSIFY returns {"labels": [...]}, extract first label as STRING
COALESCE(base.ai_document_type:labels[0]::STRING, base.catalog_document_type) AS document_type,
```

**Why `:labels[0]::STRING`:**
- Extracts the first (and typically only) label from the JSON array
- `::STRING` ensures proper type for downstream string comparisons and filters
- If AI_CLASSIFY returns empty labels `{"labels": []}`, `:labels[0]` is NULL, so COALESCE correctly falls through to `catalog_document_type`

**Impact:**
- Correctness: document_type now contains clean strings (`INVOICE`, `CONTRACT`, etc.)
- Dashboard: All Streamlit filters, charts, and review queue work correctly
- Metrics: V_PROCESSING_METRICS aggregations by document type are accurate

**Migration Risk:** NONE
- Breaking Changes: None (output is now correct)
- Rollback: N/A (this is a bug fix)

**Priority:** CRITICAL

**IMPLEMENTED (2026-02-20):** Fixed `:labels[0]::STRING` extraction in STG_ENRICHED_DOCUMENTS.

---

### Finding 2: Demo Expires Today (2026-02-20)

**Files:** `deploy_all.sql:62`, `.demo-config:12`, `README.md:8`, and 8+ other locations

**Current Code:**

```sql
DECLARE
    expires DATE DEFAULT '2026-02-20'::DATE;
BEGIN
    IF (CURRENT_DATE() >= expires) THEN
        RAISE demo_expired;
    END IF;
END;
```

**Issue:** The expiration check uses `>=`, meaning the demo fails to deploy starting today
(2026-02-20). The `EXECUTE IMMEDIATE` block raises an exception that halts Snowsight
"Run All" execution. This is working as designed — the demo has reached its 30-day
expiration window.

**Recommended Action:** Run `extendexpiration 30` to extend by 30 days, or archive
the repository per the demo lifecycle policy.

**Priority:** CRITICAL (blocking deployment)

---

## High Priority (This Sprint)

### Finding 3: AI_TRANSLATE Limitations Doc Discrepancy — Risk Flag

**File:** `sql/03_ai_processing/01_create_dynamic_tables.sql:202-225` (STG_TRANSLATED_CONTENT)

**Observation:** The AI_TRANSLATE function reference page includes this limitation:
> "Snowflake Cortex functions do not support dynamic tables."

However, this is contradicted by:
1. **Sep 11, 2025 announcement:** "You can now use Snowflake Cortex AI Functions (including LLM functions) in the SELECT clause for dynamic tables in incremental refresh mode."
2. **Dynamic table supported queries table:** Lists `TRANSLATE (SNOWFLAKE.CORTEX)` as "Supported in the SELECT clause" for both incremental and full refresh modes.
3. **The project deploys successfully** — STG_TRANSLATED_CONTENT has been running as a Dynamic Table since the 2026-02-17 update.

**Assessment:** The limitation text on the AI_TRANSLATE page is stale and was not updated
after the Sep 2025 Dynamic Table + Cortex AI Functions GA. The same stale text appears on
the AI_COMPLETE page. The Dynamic Table supported queries table (which is the authoritative
reference) explicitly lists these functions as supported.

**Recommended:** No code change needed. Document this as a known doc discrepancy.
If deployment fails in a new region, consider falling back to `SNOWFLAKE.CORTEX.TRANSLATE()`
which is explicitly listed in the supported queries table.

**Priority:** HIGH (risk awareness, no code change)

---

## Medium Priority (Next Month)

### Finding 4: AI_REDACT Could Enhance Pipeline

**Status:** AI_REDACT is GA (Dec 08, 2025)

**Opportunity:** Add a PII redaction step to the pipeline before publishing parsed/translated
content. This would demonstrate data privacy best practices for entertainment industry
documents that may contain personal information (names, addresses, financial details).

**Example addition to pipeline:**

```sql
CREATE OR REPLACE DYNAMIC TABLE STG_REDACTED_CONTENT
    TARGET_LAG = '10 minutes'
    WAREHOUSE = SFE_DOCUMENT_AI_WH
    REFRESH_MODE = INCREMENTAL
AS
SELECT
    document_id,
    AI_REDACT(parsed_content:content::STRING) AS redacted_text,
    processed_at
FROM STG_PARSED_DOCUMENTS
WHERE parsed_content:content::STRING IS NOT NULL;
```

**Documentation Evidence:**
- Source: "Dec 08, 2025: AI_REDACT for automated redaction of PII (General availability)"
- Limitations: Best with English text, 4096 token input+output limit
- Verified: 2026-02-20

**Impact:**
- Demo value: Showcases data privacy awareness
- Practical: Entertainment contracts often contain PII

**Migration Risk:** LOW (additive feature)

**Priority:** MEDIUM

---

### Finding 5: AI_EXTRACT Table Extraction Support

**Status:** GA (Oct 16, 2025 update)

**Opportunity:** AI_EXTRACT now supports table extraction from documents. The current
`responseFormat` uses simple key-question pairs for entity extraction. For invoice
documents, table extraction could pull structured line items (item, quantity, price).

**Example enhancement:**

```sql
AI_EXTRACT(
    file => TO_FILE(catalog.stage_name, catalog.file_path),
    responseFormat => {
        'schema': {
            'type': 'object',
            'properties': {
                'line_items': {
                    'description': 'Extract all invoice line items',
                    'type': 'array'
                },
                'total_amount': {
                    'description': 'Total monetary amount',
                    'type': 'number'
                }
            }
        }
    }
)
```

**Documentation Evidence:**
- Source: "Oct 16, 2025: AI_EXTRACT function — Table extraction support"
- Table extraction max output: 4096 tokens
- Verified: 2026-02-20

**Impact:**
- Demo value: Demonstrates deeper document understanding
- Practical: Invoice line items are high-value extraction targets

**Migration Risk:** MEDIUM (changes responseFormat and output schema)

**Priority:** MEDIUM

---

### Finding 6: AI_CLASSIFY Config Object Opportunities

**Observation:** AI_CLASSIFY now supports a `config_object` with:
- `task_description`: Contextual guidance for the classifier
- `output_mode`: `'multi'` for multi-label classification
- `examples`: Few-shot examples for improved accuracy

The current code uses only required arguments (input + categories). Adding a
`task_description` could improve classification accuracy:

```sql
AI_CLASSIFY(
    SUBSTR(COALESCE(trans.translated_text, parsed.parsed_content:content::STRING), 1, 4000),
    [
        {'label': 'INVOICE', 'description': 'Billing document with line items, amounts, and payment terms'},
        {'label': 'ROYALTY_STATEMENT', 'description': 'Entertainment royalty payment or distribution report'},
        {'label': 'CONTRACT', 'description': 'Legal agreement, license, or contract between parties'},
        {'label': 'OTHER', 'description': 'Document not matching invoice, royalty, or contract'}
    ],
    {'task_description': 'Classify this entertainment industry document by its primary purpose'}
):labels[0]::STRING AS ai_document_type,
```

**Impact:**
- Quality: Better classification accuracy with contextual guidance
- Cost: Minimal (task_description adds tokens but is short)

**Migration Risk:** NONE

**Priority:** MEDIUM

---

## Low Priority (Backlog)

### Finding 7: AI_COUNT_TOKENS for Cost Monitoring

**Status:** GA (Jan 2026)

**Opportunity:** AI_COUNT_TOKENS can estimate token usage for AI functions. Adding a
monitoring column or view could help users understand AI processing costs.

**Priority:** LOW

---

## Modernization Opportunities Summary

| Current Pattern | Modern Alternative | Impact | Risk | Finding | Status |
|---|---|---|---|---|---|
| Raw AI_CLASSIFY JSON in COALESCE | `:labels[0]::STRING` extraction | Correctness fix | None | #1 | DONE |
| Demo expired | `extendexpiration 30` | Deployment unblocked | None | #2 | ACTION NEEDED |
| No PII redaction | AI_REDACT in pipeline | Data privacy | Low | #4 | BACKLOG |
| Entity-only extraction | AI_EXTRACT table extraction | Richer data | Medium | #5 | BACKLOG |
| Basic AI_CLASSIFY call | Add task_description config | Better accuracy | None | #6 | BACKLOG |
| No cost visibility | AI_COUNT_TOKENS monitoring | Observability | None | #7 | BACKLOG |

## Documentation Evidence Log

| Feature | Doc Source | Verified | Status |
|---|---|---|---|
| AI_CLASSIFY output format | Snowflake Docs — AI_CLASSIFY examples | 2026-02-20 | Returns `{"labels": [...]}` |
| AI_CLASSIFY config_object | Snowflake Docs — AI_CLASSIFY | 2026-02-20 | task_description, output_mode, examples |
| AI_TRANSLATE DT limitation | Snowflake Docs — AI_TRANSLATE limitations | 2026-02-20 | Stale text, contradicted by DT support table |
| Dynamic Table + Cortex AI | Snowflake Docs — DT supported queries | 2026-02-20 | GA (Sep 2025) |
| AI_REDACT | Snowflake Docs — AI_REDACT | 2026-02-20 | GA (Dec 2025) |
| AI_EXTRACT table extraction | Snowflake Docs — AI_EXTRACT | 2026-02-20 | GA (Oct 2025 update) |
| Model deprecation (2025_05) | Snowflake Docs — Model deprecation | 2026-02-20 | gemma-7b, jamba-*, llama2-*, reka-*, llama3.2-* |
| Snowflake releases Jan-Feb 2026 | Snowflake Docs — Release notes | 2026-02-20 | No AI function changes since Feb 17 |
| CREATE STREAMLIT FROM | Snowflake Docs — CREATE STREAMLIT | 2026-02-20 | FROM recommended, ROOT_LOCATION legacy |
| AI_PARSE_DOCUMENT extract_images | Snowflake Docs — AI_PARSE_DOCUMENT | 2026-02-20 | Preview (Jan 26, 2026) |

## What's Already Correct (Carried Forward from Prior Audit)

The project gets these right and requires no changes:

- **AI_PARSE_DOCUMENT** — Uses correct modern function with LAYOUT mode and extract_images
- **AI_TRANSLATE** — Uses correct modern function (not deprecated SNOWFLAKE.CORTEX.TRANSLATE)
- **AI_EXTRACT** — Uses simple key-question responseFormat for entity extraction from files
- **AI_CLASSIFY** — Uses label descriptions for all 4 document types (output fix applied)
- **TO_FILE()** — Correct syntax for file references
- **CREATE STREAMLIT FROM** — Uses modern FROM syntax (not deprecated ROOT_LOCATION)
- **COPY FILES** — Correct syntax for Git-to-stage file transfer
- **Dynamic Table TARGET_LAG** — Valid syntax and reasonable 10-minute lag
- **Dynamic Table REFRESH_MODE = INCREMENTAL** — Explicit on all 4 dynamic tables
- **Object literal syntax** — Uses `{...}` throughout (no OBJECT_CONSTRUCT)
- **Warehouse sizing** — XSMALL with 60s auto-suspend is appropriate for demo
- **ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')** — Correct stage encryption
- **DIRECTORY = (ENABLE = TRUE)** — Correct for stage directory tables
- **Expiration guard** — EXECUTE IMMEDIATE with exception is best practice for demo expiration
- **Git Repository integration** — Correct CREATE GIT REPOSITORY syntax
- **No SELECT * in any SQL** — All queries project explicit columns
- **No hardcoded credentials** — No secrets in code
- **No deprecated function syntax** — All functions use latest AI_* naming
- **No deprecated models** — AI_COMPLETE removed entirely; no model dependency
- **V_PROCESSING_METRICS** — Efficient 5-CTE conditional aggregation pattern
- **Streamlit app** — Clean, well-structured with proper session management
- **Teardown script** — Correct dependency-ordered cleanup

---

*Generated by updatetheworld audit | 2026-02-20*
*Prior audit: 2026-02-17 (11 findings, all resolved except cancelled Finding 11)*
