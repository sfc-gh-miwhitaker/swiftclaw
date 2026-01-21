# Network Flow - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

**Reference Implementation:** This diagram reflects production-grade patterns. Review and customize security, networking, and logic for your organization before production deployment.

## Overview

This diagram shows the network architecture for the demo, highlighting connections between users, Snowflake services, and the GitHub repository integration.

## Diagram

```mermaid
flowchart TB
    subgraph externalSystems [External Systems]
        User[Business Users]
        GitHub[GitHub Repository]
    end

    subgraph snowflakeAccount [Snowflake Account]
        subgraph networkLayer [Network Layer]
            LB[Load Balancer]
            Auth[Authentication Service]
        end

        subgraph computeLayer [Compute Layer]
            WH[SFE_DOCUMENT_AI_WH]
            Streamlit[Streamlit Runtime]
        end

        subgraph aiLayer [AI Services Layer]
            Parse[AI_PARSE_DOCUMENT]
            Translate[AI_TRANSLATE]
            Complete[AI_COMPLETE]
        end

        subgraph storageLayer [Storage Layer]
            DB[SNOWFLAKE_EXAMPLE]
            Stage[DOCUMENT_STAGE]
            GitRepo[sfe_swiftclaw_repo]
        end

        subgraph integrationLayer [Integration Layer]
            GitAPI[SFE_GIT_API_INTEGRATION]
        end
    end

    User -->|HTTPS| LB
    LB -->|Authenticate| Auth
    Auth -->|Authorize| WH
    Auth -->|Authorize| Streamlit

    WH -->|AI Calls| Parse
    WH -->|AI Calls| Translate
    WH -->|AI Calls| Complete

    Parse -->|Write Results| DB
    Translate -->|Write Results| DB
    Complete -->|Write Results| DB

    Streamlit -->|Query Data| DB
    Streamlit -->|Render UI| User

    GitAPI -->|HTTPS Pull| GitHub
    GitRepo -->|EXECUTE IMMEDIATE| WH
    Stage -->|File Metadata| DB
```

## Network Components

### External Connections

**Business Users**
- Protocol: HTTPS (TLS 1.2+)  
- Port: 443  
- Access: Snowsight UI and Streamlit in Snowflake  

**GitHub Repository**
- URL: https://github.com/sfc-gh-miwhitaker/swiftclaw  
- Protocol: HTTPS (Git over HTTPS)  
- Authentication: API integration (no user credentials required)  

### Snowflake Internal Network

**Virtual Warehouse**
- Size: XSMALL  
- Auto-suspend: 60 seconds  
- Auto-resume: Enabled  

**Streamlit Runtime**
- Snowflake-managed runtime  
- Internal network access only  

### AI Services Layer

**Cortex AI Functions**
- `AI_PARSE_DOCUMENT`  
- `AI_TRANSLATE`  
- `AI_COMPLETE`  

### Storage and Integration

**Database and Stage**
- `SNOWFLAKE_EXAMPLE` database  
- `SWIFTCLAW.DOCUMENT_STAGE` internal stage  

**Git Integration**
- `SFE_GIT_API_INTEGRATION`  
- `sfe_swiftclaw_repo`  

---

**Last Updated:** 2026-01-21  
**Author:** SE Community

