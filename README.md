# Huawei MaaS Resiliency for IaC

Repository containing Terraform configurations to provision infrastructure for running a CCE (Cloud Container Engine) cluster on Huawei Cloud, with AI-powered resilience validation in CI/CD.

Purpose is automatically validate the infrastructure resilience using an AI agent (Huawei Cloud MaaS).

**Contents**

- Terraform configurations in `terraform/`.
- CI/CD pipelines in `.github/workflows/` for automated quality gates.
- AI resilience validation script in `.github/scripts/`.

## Quickstart

> See [SETUP.md](SETUP.md) for step-by-step instructions.

1. Export your credentials:

   ```bash
   export HW_ACCESS_KEY="YOUR_ACCESS_KEY_HERE"
   export HW_SECRET_KEY="YOUR_SECRET_KEY_HERE"
   ```

2. Initialize Terraform:

   ```bash
   terraform init
   ```

3. Review the plan:

   ```bash
   terraform plan
   ```

4. Apply the changes:

   ```bash
   terraform apply
   ```

## CI/CD Pipelines

All pipelines trigger on **pull requests from `dev` → `staging`**.

| Pipeline | File | Description |
|---|---|---|
| AI Resiliency Check | `huawei-maas-ai-resiliency-check.yml` | Calls Huawei Cloud MaaS (GLM-5.1) to analyze all Terraform code for resilience, security and IaC best practices. Posts a scored report as a PR comment. Quality gate is informational (does not block the pipeline by default). |

**Resilience Validation Categories**

| Category | Max Points |
|---|---|
| High Availability (multi-zone, LB, auto-scaling) | 30 |
| Security (least privilege, network, secrets, monitoring) | 25 |
| State Management (backup, versioning, locking) | 20 |
| Monitoring & Observability (metrics, logs, alerts) | 15 |
| IaC Practices (modularity, docs, validation) | 10 |
| **Total** | **100** |

**Decision Criteria**

| Decision | Score |
|---|---|
| APPROVED (auto deploy) | ≥ 80 |
| APPROVED WITH REVIEW (manual review and deploy) | 60–79 |
| REJECTED | < 60 |
