#!/bin/bash
set -euo pipefail

echo "No local processes to stop. If you want to minimize cost:"
echo "- Suspend warehouse: ALTER WAREHOUSE SFE_DOCUMENT_AI_WH SUSPEND;"
echo "- Drop demo objects: run sql/99_cleanup/teardown_all.sql in Snowsight."
