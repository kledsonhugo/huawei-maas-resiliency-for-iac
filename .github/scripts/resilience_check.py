"""Resilience validation script — calls Huawei Cloud MaaS API to analyze Terraform code."""

import json
import os
import re
import sys
import urllib.request
import urllib.error

SYSTEM_PROMPT = """\
You are an agent specialized in cloud infrastructure resilience analysis. Your function is to evaluate Terraform code and assign a score based on resilience, security, and operations best practices.

Given the Terraform code provided, produce a structured report with:

1. Overall Score (0-100 points)
2. Analysis by Category with sub-scores
3. Improvement Recommendations
4. Decision (APPROVED/APPROVED WITH REVIEW/REJECTED)

Evaluation Criteria and Scoring System:

Category 1: High Availability (30 points)
- Multi-Zone/Region (10 pts): Infrastructure distributed across multiple availability zones
- Load Balancing (10 pts): Proper Load Balancer configuration
- Auto-scaling (10 pts): Auto-scaling policies configured

Category 2: Security (25 points)
- Least Privilege Principle (8 pts): Restrictive security rules
- Network Security (8 pts): Well-configured NACLs and Security Groups
- Secrets Management (5 pts): Use of secrets management systems
- Security Monitoring (4 pts): Logs and auditing enabled

Category 3: State Management (20 points)
- Backup/Recovery (8 pts): Backup strategies implemented
- State Versioning (6 pts): Terraform state versioned and protected
- State Locking (6 pts): Lock mechanism to prevent conflicts

Category 4: Monitoring and Observability (15 points)
- Metrics (5 pts): Essential metrics collection
- Logs (5 pts): Log centralization
- Alerts (5 pts): Alert system configured

Category 5: Infrastructure as Code Practices (10 points)
- Modularity (4 pts): Modular and reusable code
- Documentation (3 pts): Clear and up-to-date documentation
- Validation (3 pts): Code tests and validation

Approval Thresholds:
- APPROVED (Automatic Deploy): Score >= 80 points
- APPROVED WITH REVIEW: Score 60-79 points (requires manual review)
- REJECTED: Score < 60 points (blocks the pipeline)

Response Template:

## RESILIENCE VALIDATION REPORT

### OVERALL SCORE: [X]/100

### ANALYSIS BY CATEGORY

#### 1. High Availability: [X]/30
- **Multi-Zone:** [Analysis]
- **Load Balancer:** [Analysis]
- **Auto-scaling:** [Analysis]

#### 2. Security: [X]/25
- **Least Privilege:** [Analysis]
- **Network Security:** [Analysis]
- **Secrets Management:** [Analysis]

#### 3. State Management: [X]/20
- **Backup/Recovery:** [Analysis]
- **Versioning:** [Analysis]
- **State Locking:** [Analysis]

#### 4. Monitoring: [X]/15
- **Metrics:** [Analysis]
- **Logs:** [Analysis]
- **Alerts:** [Analysis]

#### 5. IaC Practices: [X]/10
- **Modularity:** [Analysis]
- **Documentation:** [Analysis]
- **Validation:** [Analysis]

### CRITICAL RECOMMENDATIONS
1. [Recommendation 1 - High Priority]
2. [Recommendation 2 - Medium Priority]
3. [Recommendation 3 - Low Priority]

### QUALITY GATE DECISION
**STATUS:** [APPROVED/APPROVED WITH REVIEW/REJECTED]

**JUSTIFICATION:** [Brief justification based on score and analysis]
"""


def concatenate_tf_files(tf_dir: str) -> str:
    """Read all .tf files from tf_dir and return them as a single string."""
    parts = []
    for root, _dirs, files in sorted(os.walk(tf_dir)):
        for fname in sorted(files):
            if fname.endswith(".tf"):
                fpath = os.path.join(root, fname)
                with open(fpath, "r") as f:
                    content = f.read()
                parts.append(f"--- FILE: {fpath} ---\n{content}\n")
    return "\n".join(parts)


def call_maas(api_key: str, model: str, system_msg: str, user_msg: str) -> dict:
    """Call the Huawei Cloud MaaS endpoint (OpenAI-compatible)."""
    url = "https://api-ap-southeast-1.modelarts-maas.com/openai/v1/chat/completions"
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_msg},
            {"role": "user", "content": user_msg},
        ],
        "temperature": 0.1,
        "max_tokens": 4096,
    }
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"API call failed with HTTP {e.code}", file=sys.stderr)
        print(f"Response: {body}", file=sys.stderr)
        sys.exit(1)


def extract_score(report: str) -> int:
    """Extract the overall score from the report text."""
    match = re.search(r"OVERALL SCORE:\s*(\d+)", report)
    return int(match.group(1)) if match else 0


def main():
    tf_dir = os.environ.get("TF_DIR", "terraform")
    api_key = os.environ.get("HW_MAAS_API_KEY", "")
    model = os.environ.get("HW_MAAS_MODEL", "glm-5.1")
    report_path = os.environ.get("REPORT_PATH", "/tmp/resilience_report.md")

    if not api_key:
        print("ERROR: HW_MAAS_API_KEY is not set.", file=sys.stderr)
        sys.exit(1)

    # 1. Concatenate Terraform code
    tf_code = concatenate_tf_files(tf_dir)
    if not tf_code.strip():
        print("ERROR: No .tf files found.", file=sys.stderr)
        sys.exit(1)

    # 2. Call MaaS API
    user_msg = f"Analyze the following Terraform code for infrastructure resilience:\n\n{tf_code}"
    response = call_maas(api_key, model, SYSTEM_PROMPT, user_msg)

    # 3. Extract report
    report = response["choices"][0]["message"]["content"]
    with open(report_path, "w") as f:
        f.write(report)
    print("Report generated successfully.")

    # 4. Quality gate
    score = extract_score(report)
    print(f"score={score}")

    github_output = os.environ.get("GITHUB_OUTPUT", "")

    if score >= 80:
        print(f"Quality Gate PASSED - Score: {score}/100")
        print("decision=approved")
        if github_output:
            with open(github_output, "a") as f:
                f.write("decision=approved\n")
    elif score >= 60:
        print(f"Quality Gate PASSED WITH REVIEW - Score: {score}/100")
        print("decision=review")
        if github_output:
            with open(github_output, "a") as f:
                f.write("decision=review\n")
    else:
        print(f"Quality Gate FAILED - Score: {score}/100")
        print("decision=rejected")
        if github_output:
            with open(github_output, "a") as f:
                f.write("decision=rejected\n")


if __name__ == "__main__":
    main()
