# Lab 04 — Terraform / IaC Security

## Status

✅ Completed

## Objective

Assess Terraform Infrastructure as Code before deployment, identify security misconfigurations, implement targeted remediation, re-scan the hardened configuration, and document justified residual findings.

No AWS infrastructure was deployed as part of this lab.

## Workflow

```text
Terraform Baseline
        ↓
terraform validate
        ↓
Trivy IaC Scan
        ↓
Triage Findings
        ↓
Security Hardening
        ↓
terraform validate
        ↓
Trivy Re-scan
        ↓
Residual Finding Review
        ↓
Document Exceptions
```

## Baseline

The baseline Terraform configuration passed `terraform validate`.

Trivy nevertheless identified seven security misconfigurations:

| Severity | Count |
| --- | ---: |
| Critical | 0 |
| High | 5 |
| Medium | 1 |
| Low | 1 |
| Total | 7 |

The findings covered S3 public-access controls, logging, versioning, and encryption.

## Hardening

The hardened configuration introduced:

- S3 public-access blocking
- object versioning
- server access logging
- customer-managed KMS encryption for application data
- KMS key rotation
- a dedicated access-log bucket
- public-access protection for the logging bucket
- versioning for the logging bucket
- SSE-S3 encryption for the logging destination

## Retest

The first hardened scan reduced the result from seven findings to three.

One additional applicable finding was then remediated by enabling versioning on the logging destination.

The final scan reported two residual findings:

- AWS-0089 — Low
- AWS-0132 — High

Both relate to the dedicated S3 server access logging destination and were reviewed individually rather than automatically modified to obtain a zero-finding scan.

## Final Result

```text
Baseline findings:        7
Final scanner findings:   2
Applicable unresolved:    0
Documented exceptions:    2
```

All applicable findings within the lab scope were remediated.

The two residual findings are documented with contextual or technical justification in `notes/residual-findings.md`.

## Evidence

### Baseline

- `evidence/baseline/trivy-config-scan.txt`

### Hardened

- `evidence/hardened/trivy-config-scan-round1.txt`
- `evidence/hardened/trivy-config-scan-final.txt`

## Terraform

- `terraform/baseline/main.tf`
- `terraform/hardened/main.tf`

The Terraform provider lock files are retained to support reproducible provider selection.

Generated `.terraform/` directories and Terraform state files are excluded from version control.

## Assessment Notes

- `notes/baseline-assessment.md`
- `notes/remediation-retest.md`
- `notes/residual-findings.md`

## Security Engineering Takeaway

This lab demonstrates that successful Terraform validation does not imply secure infrastructure.

IaC security requires an additional workflow of static scanning, human triage, remediation, retesting, and documented exception handling before infrastructure deployment.
