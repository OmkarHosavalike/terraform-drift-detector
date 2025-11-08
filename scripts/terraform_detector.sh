#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${TF_WORKING_DIR:-terraform}"
OUTFILE="terraform-plan-output.txt"
EXIT_CODE=0

cd "$WORKDIR" || { echo "Terraform working dir not found: $WORKDIR"; exit 1; }

echo "Terraform version"
terraform -v || true

terraform init -input=false -no-color -backend-config="bucket=${bucket}"

echo "Running terraform plan..."
set +e
terraform plan -detailed-exitcode -input=false -no-color -out=tfplan.binary | tee "$OUTFILE"
terraform show -no-color tfplan.binary > human-readable-plan.txt
PLAN_LINE=$(grep "Plan:" human-readable-plan.txt)
if [[ "$PLAN_LINE" =~ [1-9] ]]; then
  EXIT_CODE=1
fi
set -e

if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "No drift detected."
  exit 0
elif [[ "$EXIT_CODE" -eq 1 ]]; then
  echo "Drift detected."
  cat human-readable-plan.txt >> "$OUTFILE"
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    PAYLOAD=$(jq -nc --arg text "Terraform drift detected in ${GITHUB_REPOSITORY}. Run: $GITHUB_RUN_ID\n\n$(head -n 60 human-readable-plan.txt)" '{text:$text}')
    curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL" || true
  fi
  exit 1
else
  echo "Terraform plan failed. Exit $EXIT_CODE"
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    PAYLOAD=$(jq -nc --arg text "Terraform plan failed in ${GITHUB_REPOSITORY}. Run: $GITHUB_RUN_ID" '{text:$text}')
    curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL" || true
  fi
  exit "$EXIT_CODE"
fi