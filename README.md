# Terraform Drift Detection with GitHub Actions

This repository automatically detects **Terraform drift** in AWS using **GitHub Actions**.

---

## How it works
- Runs on a schedule or manually via workflow_dispatch.
- Uses GitHub OIDC to assume AWS IAM roles.
- Runs terraform plan to compare actual infrastructure with Terraform configuration.
- Sends a Slack alert if any drift is found.
- Uploads the Terraform plan output as an artifact.

---

## Setup OIDC

1. **Create IAM roles** for OIDC:
   - **`OIDC_IAM_ROLE`** – Role for drift detection (read-only for EC2&S3)
   - **`OIDC_IAM_ROLE_EC2_ADMIN`** – Role for Terraform workflow to create resources (full EC2&S3 access)  

2. **Enable OIDC trust** for GitHub Actions in these roles.

---

## Repository Variables (Secrets)

| Name | Description |
|------|-------------|
| `BACKEND_S3_BUCKET` | S3 bucket for Terraform backend with versioning enabled |
| `OIDC_IAM_ROLE` | IAM role assumed by the drift detection workflow (read-only) |
| `OIDC_IAM_ROLE_EC2_ADMIN` | IAM role assumed by the Terraform workflow to create resources |
| `SLACK_WEBHOOK_URL` | Slack Incoming Webhook URL for notifications |

---