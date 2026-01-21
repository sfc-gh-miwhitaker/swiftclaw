# Data Flow - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

**Reference Implementation:** This diagram reflects production-grade patterns. Review and customize security, networking, and logic for your organization before production deployment.

## Overview

This diagram shows how document data flows through the AI processing pipeline, from PDF ingestion to AI enrichment and analytics. The pipeline uses Dynamic Tables for orchestration and Snowflake Cortex AI Functions for document understanding.

## Diagram

```mermaid
flowchart TD
    subgraph externalSources [External Sources]
        PDF[PDF Documents]
    end

    subgraph ingestion [Ingestion Layer - SNOWFLAKE_EXAMPLE.SWIFTCLAW]
        Stage[DOCUMENT_STAGE]
        Catalog[RAW_DOCUMENT_CATALOG]
    end

    subgraph processing [AI Processing Layer - SNOWFLAKE_EXAMPLE.SWIFTCLAW]
        Parse[AI_PARSE_DOCUMENT]
        Parsed[STG_PARSED_DOCUMENTS]
        Translate[AI_TRANSLATE]
        Translated[STG_TRANSLATED_CONTENT]
        Enrich[AI_COMPLETE]
        Enriched[STG_ENRICHED_DOCUMENTS]
    end

    subgraph analytics [Analytics Layer - SNOWFLAKE_EXAMPLE.SWIFTCLAW]
        Insights[FCT_DOCUMENT_INSIGHTS]
        Metrics[V_PROCESSING_METRICS]
    end

    subgraph consumption [Consumption Layer]
        Streamlit[Streamlit Dashboard]
        SQL[SQL Analytics]
    end

    PDF -->|Upload| Stage
    Stage -->|Directory Table Refresh| Catalog

    Catalog -->|Stage File Path| Parse
    Parse -->|Structured JSON| Parsed

    Parsed -->|Non-EN Text| Translate
    Translate -->|Translated Text| Translated

    Parsed -->|Document Text| Enrich
    Translated -->|Translated Text| Enrich
    Enrich -->|Task Output| Enriched

    Enriched -->|Aggregate| Insights
    Insights -->|Monitor| Metrics

    Metrics -->|Visualize| Streamlit
    Insights -->|Visualize| Streamlit
    Insights -->|Query| SQL
```

## Data Flow Stages

### Stage 1: Document Ingestion
**Input:** PDF files uploaded to the internal stage  
**Process:** Stage directory is merged into `RAW_DOCUMENT_CATALOG` table  
**Output:** File metadata (path, size, language, type)  

### Stage 2: AI Parsing
**Input:** Files referenced by `RAW_DOCUMENT_CATALOG`  
**Process:** `AI_PARSE_DOCUMENT` extracts text and layout  
**Output:** Parsed JSON in `STG_PARSED_DOCUMENTS`  

### Stage 3: Translation
**Input:** Parsed content for non-English documents  
**Process:** `AI_TRANSLATE` converts content to English  
**Output:** Translated text in `STG_TRANSLATED_CONTENT`  

### Stage 4: Enrichment
**Input:** Parsed or translated text  
**Process:** Task calls `AI_COMPLETE` to produce structured JSON  
**Output:** Enriched fields in `STG_ENRICHED_DOCUMENTS`  

### Stage 5: Analytics
**Input:** Enrichment outputs  
**Process:** Aggregation into `FCT_DOCUMENT_INSIGHTS`  
**Output:** Business metrics and monitoring views  

## Notes

- Dynamic Tables orchestrate processing and refresh automatically.
- Uploading new PDFs to the stage triggers refresh within the target lag window.

---

**Last Updated:** 2026-01-21  
**Author:** SE Community

