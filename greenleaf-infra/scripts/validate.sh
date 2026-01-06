#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}/terraform"

ALB_DNS=$(terraform output -raw alb_dns_name)
URL="http://${ALB_DNS}"

echo "Checking ${URL} ..."
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "${URL}")

echo "HTTP status: ${HTTP_CODE}"

if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "302" ]]; then
  echo "Magento appears reachable at ${URL}"
else
  echo "Unexpected status. App may still be provisioning or failing health checks."
  exit 1
fi
