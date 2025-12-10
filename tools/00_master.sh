#!/bin/bash
set -euo pipefail

echo "=== swiftclaw master control ==="
echo "Mode: Snowsight-only (no local services)."
echo
echo "1) Deploy: open deploy_all.sql in Snowsight and Run All."
echo "2) Upload: use Streamlit page '📤 Upload Documents' or PUT to @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE."
echo "3) Process: run SQL scripts in sql/03_ai_processing/ via EXECUTE IMMEDIATE (see README)."
echo "4) Clean up: run sql/99_cleanup/teardown_all.sql."
echo
echo "Use tools/03_status.sh to see staged files and row counts."
