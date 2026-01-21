# Auth Flow - AI Document Processing Demo

**Author:** SE Community  
**Last Updated:** 2026-01-21  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

**Reference Implementation:** This diagram reflects production-grade patterns. Review and customize security, networking, and logic for your organization before production deployment.

## Overview

This diagram shows the authentication and authorization flow for users accessing the Streamlit dashboard and querying Dynamic Tables in the `SWIFTCLAW` schema.

## Diagram

```mermaid
sequenceDiagram
    actor User as BusinessUser
    participant Snowsight as SnowsightUI
    participant RBAC as RoleBasedAccess
    participant WH as SFE_DOCUMENT_AI_WH
    participant DB as SNOWFLAKE_EXAMPLE
    participant Streamlit as StreamlitApp

    User->>Snowsight: Sign in
    Snowsight->>RBAC: Verify roles and privileges
    RBAC-->>Snowsight: Role SFE_DEMO_ROLE granted

    User->>Snowsight: Open Streamlit app
    Snowsight->>RBAC: Check USAGE on warehouse and schema
    RBAC-->>Snowsight: Access granted

    Snowsight->>WH: Resume warehouse
    WH-->>Snowsight: Warehouse active

    Snowsight->>Streamlit: Launch app with session context
    Streamlit-->>User: Render dashboard

    User->>Streamlit: Request data
    Streamlit->>RBAC: Check SELECT on dynamic tables and views
    RBAC-->>Streamlit: Access granted

    Streamlit->>WH: Execute query
    WH->>DB: Read from SWIFTCLAW
    DB-->>WH: Return rows
    WH-->>Streamlit: Query results
    Streamlit-->>User: Display results
```

## Role and Privileges

**SFE_DEMO_ROLE** should have:

```sql
GRANT USAGE ON WAREHOUSE SFE_DOCUMENT_AI_WH TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SFE_DEMO_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SWIFTCLAW TO ROLE SFE_DEMO_ROLE;
```

---

**Last Updated:** 2026-01-21  
**Author:** SE Community

