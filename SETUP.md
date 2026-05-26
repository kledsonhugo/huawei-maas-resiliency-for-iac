# Setup Guide

Step-by-step instructions to configure the repository for local development and CI/CD.

## Local Development

1. Install Terraform

   Download and install the latest version from [terraform.io](https://www.terraform.io/downloads.html).

   Verify:

   ```bash
   terraform version
   ```

2. Configure Huawei Cloud Credentials

   Export your **Access Key** and **Secret Key** as environment variables:

   ```bash
   # Linux / macOS
   export HW_ACCESS_KEY="YOUR_ACCESS_KEY_HERE"
   export HW_SECRET_KEY="YOUR_SECRET_KEY_HERE"

   # Windows (PowerShell)
   $env:HW_ACCESS_KEY = "YOUR_ACCESS_KEY_HERE"
   $env:HW_SECRET_KEY = "YOUR_SECRET_KEY_HERE"
   ```

3. Run Terraform

   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

## Automated Pipeline with GitHub Actions

1. Configure GitHub Secrets

   Go to **Settings → Secrets and variables → Actions** and add:

   | Secret | Description |
   |---|---|
   | `HW_MAAS_API_KEY` | API key for the Huawei Cloud ModelArts MaaS endpoint (`https://api-ap-southeast-1.modelarts-maas.com/openai/v1`) |

   The built-in `GITHUB_TOKEN` is used automatically for posting PR comments (the workflow grants `pull-requests: write` permission).

2. Workflow Configuration

   The resilience validation workflow supports the following environment variables:

   | Variable | Default | Description |
   |---|---|---|
   | `HW_MAAS_API_KEY` | (required) | API key for MaaS |
   | `HW_MAAS_MODEL` | `glm-5.1` | Model to use on the MaaS endpoint |
   | `TF_DIR` | `terraform` | Directory containing `.tf` files to analyze |
   | `REPORT_PATH` | `/tmp/resilience_report.md` | Path where the report is written |
   | `FAIL_ON_GATE` | `false` | Set to `true` to make the quality gate block the pipeline on REJECTED |

## Branch Strategy

- **`dev`**: Active development. All feature work happens here.
- **`staging`**: Pre-production. PRs from `dev` trigger the AI resilience validation pipeline.
- **`main`**: Production. Only promoted from `staging` after validation passes.

## Security Considerations

- **Never commit** API keys, access keys, or secrets to the repository.
- Use GitHub Secrets for all credentials used in CI/CD.
- The `GITHUB_TOKEN` is scoped to `pull-requests: write` and `contents: read` only.