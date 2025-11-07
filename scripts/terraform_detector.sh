#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${TF_WORKING_DIR:-terraform}"
OUTFILE="terraform-plan-output.txt"

cd "$WORKDIR" || { echo "Terraform working dir not found: $WORKDIR"; exit 1; }

echo "Terraform version"
terraform -v || true

terraform init -input=false -no-color

echo "Running terraform plan..."
set +e
terraform plan -detailed-exitcode -input=false -no-color -out=tfplan.binary > >(tee "$OUTFILE") 2>&1
EXIT_CODE=$?
set -e

echo "terraform plan exit code 1: $EXIT_CODE"

if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "No drift detected."
  exit 0
elif [[ "$EXIT_CODE" -eq 2 ]]; then
  echo "Drift detected."
  terraform show -no-color tfplan.binary > human-readable-plan.txt
  cat human-readable-plan.txt >> "$OUTFILE"
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    PAYLOAD=$(jq -nc --arg text "Terraform drift detected in ${GITHUB_REPOSITORY}. Run: $GITHUB_RUN_ID\n\n$(head -n 60 human-readable-plan.txt)" '{text:$text}')
    curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL" || true
  fi
  exit 2
else
  echo "Terraform plan failed. Exit $EXIT_CODE"
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    PAYLOAD=$(jq -nc --arg text "Terraform plan failed in ${GITHUB_REPOSITORY}. Run: $GITHUB_RUN_ID" '{text:$text}')
    curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL" || true
  fi
  exit "$EXIT_CODE"
fi
