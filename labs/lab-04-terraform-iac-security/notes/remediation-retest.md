# Terraform IaC Remediation and Retest

## Baseline

The baseline Terraform configuration passed `terraform validate` but Trivy detected seven security misconfigurations.

Baseline result:

| Severity | Count |
| --- | ---: |
| Critical | 0 |
| High | 5 |
| Medium | 1 |
| Low | 1 |
| Total | 7 |

This demonstrated that syntactically valid Infrastructure as Code is not necessarily securely configured.

## Remediation

The hardened Terraform configuration introduced:

- complete S3 public-access blocking
- S3 object versioning
- server access logging
- customer-managed KMS encryption for application data
- KMS key rotation
- a dedicated access-log destination bucket
- public-access blocking for the logging bucket
- versioning for the logging bucket
- SSE-S3 encryption for the logging bucket

## First Retest

After the initial remediation, Trivy reported three findings against the newly introduced logging destination bucket:

- AWS-0089 — Low
- AWS-0090 — Medium
- AWS-0132 — High

AWS-0090 was applicable and remediated by enabling versioning on the logging destination bucket.

## Final Retest

The hardened configuration continued to pass:

```text
terraform validate
Success! The configuration is valid.
```

The final Trivy scan reported:

| Severity | Count |
| --- | ---: |
| Critical | 0 |
| High | 1 |
| Medium | 0 |
| Low | 1 |
| Total | 2 |

The remaining AWS-0089 and AWS-0132 findings were reviewed and documented as justified exceptions.

## Result

```text
Baseline findings:        7
Final scanner findings:   2
Applicable unresolved:    0
Documented exceptions:    2
```

All applicable findings identified within the lab scope were remediated.

The exercise demonstrates a complete IaC security workflow:

```text
Author
  ↓
Validate
  ↓
Scan
  ↓
Triage
  ↓
Remediate
  ↓
Re-scan
  ↓
Review Residual Findings
  ↓
Document Exceptions
```
