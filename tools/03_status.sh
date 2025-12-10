#!/bin/bash
set -euo pipefail

echo "=== Snowflake demo status ==="
echo "Warehouse: SFE_DOCUMENT_AI_WH"
echo "Schema: SNOWFLAKE_EXAMPLE.SWIFTCLAW"
echo
echo "Staged files (first 10):"
snowsql -q "LIST @SNOWFLAKE_EXAMPLE.SWIFTCLAW.DOCUMENT_STAGE LIMIT 10" 2>/dev/null || echo "snowsql not configured; run in Snowsight instead."
echo
echo "Row counts (if snowsql configured):"
snowsql -q "SELECT 'RAW_DOCUMENT_CATALOG' AS table, COUNT(*) AS rows FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.RAW_DOCUMENT_CATALOG UNION ALL SELECT 'FCT_DOCUMENT_INSIGHTS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SWIFTCLAW.FCT_DOCUMENT_INSIGHTS;" 2>/dev/null || echo "Snowsight: run SELECT COUNT(*) FROM SWIFTCLAW tables."
