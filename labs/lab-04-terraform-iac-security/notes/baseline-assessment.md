# Terraform IaC Baseline Assessment

## Objective

Assess a Terraform configuration for security misconfigurations before infrastructure deployment and demonstrate the difference between configuration validity and security posture.

## Scope

The baseline models an Amazon S3 data bucket using Terraform.

No cloud infrastructure was deployed during this assessment. Terraform was used for static configuration validation and Trivy was used for Infrastructure as Code security scanning.

## Terraform Validation

The baseline configuration successfully passed:

`terraform validate`

This confirmed that the Terraform configuration was syntactically and internally valid.

However, successful validation did not indicate that the infrastructure configuration was securely designed.

## Security Scan

Trivy detected seven misconfigurations:

| ID | Severity | Finding | Disposition |
| --- | --- | --- | --- |
| AWS-0086 | High | Public ACLs not blocked | Remediate |
| AWS-0087 | High | Public bucket policies not blocked | Remediate |
| AWS-0089 | Low | S3 access logging disabled | Remediate |
| AWS-0090 | Medium | S3 versioning disabled | Remediate |
| AWS-0091 | High | Public ACLs not ignored | Remediate |
| AWS-0093 | High | Public buckets not restricted | Remediate |
| AWS-0132 | High | Customer-managed KMS encryption not configured | Remediate |

## Severity Summary

| Severity | Count |
| --- | ---: |
| Critical | 0 |
| High | 5 |
| Medium | 1 |
| Low | 1 |
| Total | 7 |

## Assessment

The baseline demonstrated multiple security weaknesses despite passing Terraform validation.

The most significant issues were:

- incomplete S3 public-access protection
- absence of customer-managed encryption
- absence of versioning
- absence of server access logging

This establishes the security baseline used for remediation and retesting in Lab 04.

## Key Lesson

Terraform validation and IaC security scanning serve different purposes.

Terraform validation answers whether the configuration is structurally valid.

IaC security scanning evaluates whether valid infrastructure definitions contain known security misconfigurations.

A configuration can therefore be valid while still presenting significant security risk.
