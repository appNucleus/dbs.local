#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "WARNING: This deletes ALL Docker volumes for this stack."
read -r -p "Type DELETE to continue: " answer
if [ "${answer}" != "DELETE" ]; then
  echo "Cancelled."
  exit 0
fi

docker compose down -v --remove-orphans
rm -rf generated
echo "Deleted all stack data."
