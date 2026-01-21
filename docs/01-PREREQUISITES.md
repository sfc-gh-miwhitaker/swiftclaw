# Prerequisites - AI Document Processing Demo

**Author:** SE Community
**Last Updated:** 2026-01-21
**Expires:** 2026-02-08

---

## Required Access

### Snowflake Account
- **Role:** ACCOUNTADMIN (for initial deployment)
- **Edition:** Any (Standard, Enterprise, Business Critical)
- **Cloud:** Any (AWS, Azure, GCP)
- **Region:** Any

**Why ACCOUNTADMIN?**
Creating API integrations requires ACCOUNTADMIN privileges. After deployment, users can operate the demo with the `SFE_DEMO_ROLE`.

### Network Access
- **Outbound HTTPS:** Required to `*.snowflakecomputing.com` (port 443)
- **GitHub Access:** Required to pull code from `github.com/sfc-gh-miwhitaker/swiftclaw` (port 443)
- **Corporate Proxy:** If behind a proxy, ensure Snowflake and GitHub are allowed

---

## Estimated Resource Requirements

### Compute
- **Warehouse:** XSMALL (created automatically)
- **Duration:** ~10 minutes for full deployment
- **Credits:** ~1.5 credits one-time deployment cost

### Storage
- **Demo Data:** ~1 GB (sample documents)
- **Time Travel:** 7 days (raw layer), 1 day (staging layer)
- **Monthly Cost:** < $0.50/month if left running

### Features Used
- Snowflake Cortex AI Functions (Standard edition+)
- Snowflake Git Integration (All editions)
- Snowflake Streamlit (All editions)
- Standard SQL and VARIANT data types (All editions)

---

## Skills & Knowledge

### Required (to deploy)
- Basic Snowflake knowledge (logging in, running SQL)
- Ability to copy/paste a SQL script into Snowsight
- Understanding of SQL execution (clicking "Run All")

### Optional (for customization)
- SQL scripting (to modify data generation logic)
- Python (to customize Streamlit dashboard)
- Snowflake architecture concepts (warehouses, schemas, stages)

---

## Pre-Deployment Checklist

- [ ] Snowflake account accessible
- [ ] ACCOUNTADMIN role available (or ability to request it)
- [ ] Corporate firewall allows outbound HTTPS to Snowflake and GitHub
- [ ] ~15 minutes of time available for deployment
- [ ] Familiarity with Snowsight UI (or willingness to learn)

---

## Optional: Local Development Tools

If you plan to modify the code locally (not required for deployment):

- **Git client:** For cloning the repository locally
- **Python 3.8+:** For testing Streamlit app locally
- **Snowpark library:** `pip install snowflake-snowpark-python`
- **Streamlit:** `pip install streamlit`
- **Code editor:** VS Code, PyCharm, or similar

---

## What's Not Required

- External databases or storage
- AWS/Azure/GCP accounts (Snowflake provides compute and storage)
- Docker or container orchestration
- SSH keys or VPN access
- Additional software installations
- Command-line expertise

**This demo is 100% native Snowflake** - everything runs inside your Snowflake account.

---

## Next Steps

Once prerequisites are met, run `deploy_all.sql` from Snowsight or follow the steps in `README.md`.

---

**Questions?**
See [04-TROUBLESHOOTING.md](04-TROUBLESHOOTING.md) for common issues and solutions.
