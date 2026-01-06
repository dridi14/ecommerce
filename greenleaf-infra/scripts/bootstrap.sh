#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT}/terraform"

terraform init
terraform apply -auto-approve "$@"

echo "Terraform applied. Outputs:"
terraform output

ALB_DNS=$(terraform output -raw alb_dns_name)
echo "ALB DNS: http://${ALB_DNS}"
echo "If instances are still configuring, give them a few minutes then run ${ROOT}/scripts/validate.sh"
