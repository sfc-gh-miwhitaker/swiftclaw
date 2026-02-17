# Data Model - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

**Reference Implementation:** This diagram reflects production-grade patterns. Review and customize security, networking, and logic for your organization before production deployment.

## Overview

This diagram shows the schema and relationships for the AI document pipeline. The design uses a catalog table refreshed from the stage directory and Dynamic Tables for processing and insights.

## Diagram

```mermaid
erDiagram
    RAW_DOCUMENT_CATALOG ||--o{ STG_PARSED_DOCUMENTS : "parsed"
    STG_PARSED_DOCUMENTS ||--o{ STG_TRANSLATED_CONTENT : "translated"
    STG_PARSED_DOCUMENTS ||--o{ STG_ENRICHED_DOCUMENTS : "enriched"
    STG_ENRICHED_DOCUMENTS ||--o{ FCT_DOCUMENT_INSIGHTS : "aggregated"

    RAW_DOCUMENT_CATALOG {
        string document_id PK
        string document_type
        string stage_name
        string file_path
        string file_name
        string file_format
        number file_size_bytes
        string original_language
        timestamp upload_date
        variant metadata
    }

    STG_PARSED_DOCUMENTS {
        string document_id PK
        variant parsed_content
        string extraction_mode
        number page_count
        timestamp processed_at
    }

    STG_TRANSLATED_CONTENT {
        string document_id PK
        string source_language
        string target_language
        string source_text
        string translated_text
        timestamp translated_at
    }

    STG_ENRICHED_DOCUMENTS {
        string document_id PK
        string document_type
        string priority_level
        string business_category
        number total_amount
        string currency
        date document_date
        string vendor_territory
        number confidence_score
        variant enrichment_details
        timestamp enriched_at
    }

    FCT_DOCUMENT_INSIGHTS {
        string insight_id PK
        string document_id FK
        string document_type
        number total_amount
        string currency
        date document_date
        string vendor_territory
        number overall_confidence_score
        boolean requires_manual_review
        string manual_review_reason
        timestamp insight_created_at
        variant metadata
    }
```

## Notes

- `RAW_DOCUMENT_CATALOG` is a table refreshed from the stage directory by a task.
- STG_PARSED_DOCUMENTS and STG_TRANSLATED_CONTENT are Dynamic Tables.
- STG_ENRICHED_DOCUMENTS is a Dynamic Table using AI_EXTRACT + AI_CLASSIFY for structured enrichment.
- `FCT_DOCUMENT_INSIGHTS` is the primary analytics table used by the Streamlit dashboard.

---

**Last Updated:** 2026-01-21  
**Author:** SE Community

