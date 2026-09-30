# Lab 06 — Secure CI/CD Pipeline

## Objective

Integrate repository inspection, Terraform validation, IaC security reporting, and an enforceable container vulnerability gate into GitHub Actions. Demonstrate the gate's failure and successful retest using local evidence, then confirm successful execution of the pushed workflow on GitHub-hosted runners.

## Security Problem

A successful build or structurally valid Terraform configuration does not establish security. Vulnerable packages and infrastructure misconfigurations require additional checks, explicit failure criteria, and human review of residual findings.

This lab carries the hardened Terraform configuration from [Lab 04](../lab-04-terraform-iac-security/README.md) and the remediated container build from [Lab 05](../lab-05-container-vulnerability-management/README.md) into CI. It distinguishes controls that report findings from controls that fail a job.

## CI/CD Architecture and Triggers

The [Security CI workflow](../../.github/workflows/security-ci.yml) runs on pushes to `main` and pull requests targeting `main`. It declares `contents: read` permissions and uses `ubuntu-latest` runners. The jobs have no `needs` dependencies and can run independently in parallel.

```text
Developer
   ↓
Push to main / Pull Request targeting main
   ↓
GitHub Actions — Security CI
   ├── Repository Checks
   │      ├── Checkout repository
   │      └── Print commit, ref, event, and file inventory
   ├── Terraform Security
   │      ├── terraform init -backend=false
   │      ├── terraform fmt -check
   │      ├── terraform validate
   │      └── Trivy IaC scan — report findings, exit-code: "0"
   └── Container Security
          ├── Build Lab 05 remediated image with --pull
          ├── Print runtime identity using id
          └── Trivy vulnerability gate
                 ignore-unfixed: true; exit-code: "1"
```

This is the CI validation portion of a CI/CD pipeline. The workflow contains no image publication or deployment step.

## Repository Checks Job

The job checks out the repository and prints the commit SHA, Git ref, event name, and a file inventory limited to `find . -maxdepth 2`. It supplies execution context and visibility into the checkout. It does not implement a secret scan, repository policy assertion, or application test suite.

## Terraform Security Job

The job installs Terraform `1.16.0` and operates on `labs/lab-04-terraform-iac-security/terraform/hardened`:

1. `terraform init -backend=false` initializes dependencies without configuring the backend.
2. `terraform fmt -check` checks formatting.
3. `terraform validate` checks configuration validity.
4. Trivy scans the hardened directory with `scan-type: config`, all configured severities (`CRITICAL,HIGH,MEDIUM,LOW`), and table output.

Initialization, formatting, and validation commands can fail the job when they return a nonzero exit status. The Trivy IaC step uses `exit-code: "0"`: detected misconfigurations are reported without failing the job because of those findings. This is a detection/reporting control, not a blocking vulnerability or misconfiguration gate. Tool execution errors remain distinct from finding-based policy decisions.

Lab 04's [final scan](../lab-04-terraform-iac-security/evidence/hardened/trivy-config-scan-final.txt) retains AWS-0089 and AWS-0132, with the dispositions recorded in its [residual-finding review](../lab-04-terraform-iac-security/notes/residual-findings.md). The CI workflow does not enforce that exception list; its finding exit code applies to the IaC scan as a whole.

## Container Security Job and Gate Behavior

The job builds `cloud-k8s-security-lab:ci` from [app/Dockerfile.lab05-remediated](../../app/Dockerfile.lab05-remediated), using `docker build --pull` and `app/` as the build context. It then runs `docker run --rm --entrypoint id` against that image.

The Trivy step scans the image with `scanners: vuln`, `severity: CRITICAL,HIGH,MEDIUM,LOW`, `ignore-unfixed: true`, and `exit-code: "1"`. Findings within those severities that remain after filtering cause the scan step and Container Security job to fail. Unfixed findings are excluded from the gate by configuration. A passing result means no findings matched this gate's policy at scan time; it does not mean the image has no vulnerabilities.

The identity command displays the image's configured runtime identity. It does not compare the UID with an expected value or explicitly fail if that UID is root. The hosted workflow also does not include the separate pip-presence check captured in the local evidence.

## Failure Evidence

The [local failure log](evidence/failure/container-security-gate.txt) scans `cloud-k8s-security-lab:hardened` and records:

| Target | Critical | High | Medium | Low | Findings |
| --- | ---: | ---: | ---: | ---: | ---: |
| Debian packages | 0 | 6 | 27 | 6 | 39 |
| Python / pip | 0 | 0 | 5 | 1 | 6 |
| Combined | 0 | 6 | 32 | 7 | 45 |

The log ends with `TrivyExitCode=1`, demonstrating a local gate failure. These are package-level findings, not a count of unique vulnerability IDs. This log is not evidence of a failed GitHub-hosted run.

## Remediation

The final workflow selects the existing Lab 05 remediated Dockerfile. That build upgrades `libpcre2-8-0`, `libssl3t64`, `openssl`, and `openssl-provider-legacy`, removes pip with `python -m pip uninstall -y pip`, and retains `USER appuser`, application-file ownership, and the healthcheck.

The failure log attributes 39 findings to the three OpenSSL packages and six to pip. Lab 05's [remediation and retest](../lab-05-container-vulnerability-management/notes/remediation-retest.md) documents the OS upgrade and runtime-tool removal stages. No failure-log finding is attributed to `libpcre2-8-0`.

## Successful Retest and Runtime Verification

The [final local gate log](evidence/final/container-security-gate.txt) reports zero vulnerabilities for the Debian target `cloud-k8s-security-lab:ci`, no language-specific files detected, and `TrivyExitCode=0`.

| Local comparison | Failure | Final |
| --- | --- | --- |
| Image tag | `cloud-k8s-security-lab:hardened` | `cloud-k8s-security-lab:ci` |
| Gate-visible findings | 45 | 0 |
| Language-specific files detected | 1 | 0 |
| Trivy exit code | 1 | 0 |

The separate [local runtime verification](evidence/final/container-runtime-verification.txt) records:

```text
uid=999(appuser) gid=999(appgroup) groups=999(appgroup)
RESULT=PASS: pip absent
```

This verifies the recorded local CI image's non-root identity and pip absence. Lab 06's runtime evidence does not record an application health-endpoint test; Lab 05's health validation belongs to its separate evidence set.

## GitHub Actions Final Result

The [GitHub Actions screenshot](evidence/final/github-actions-success.png) shows the pushed `Security CI` run on `main` with overall status **Success**. Repository Checks, Terraform Security, and Container Security each show successful completion.

This is GitHub-hosted CI evidence, separate from the local failure, retest, and runtime logs. The screenshot confirms the workflow run completed successfully; it does not provide a complete hosted vulnerability inventory or prove that local and hosted image digests are identical.

## Evidence Inventory

| Artifact | Environment | What it establishes |
| --- | --- | --- |
| [Failure gate log](evidence/failure/container-security-gate.txt) | Local | Findings against the hardened baseline and exit code 1 |
| [Final gate log](evidence/final/container-security-gate.txt) | Local | Zero gate-visible findings against the CI image and exit code 0 |
| [Runtime verification](evidence/final/container-runtime-verification.txt) | Local | Non-root identity and pip absence |
| [GitHub Actions success](evidence/final/github-actions-success.png) | GitHub-hosted | Successful pushed workflow run and successful job statuses |
| [Remediation and retest notes](notes/remediation-retest.md) | Documentation | Failure-to-success evidence chain and policy interpretation |

## Security Conclusions

The local evidence demonstrates a vulnerability gate changing from failure to success after using the remediated build. The hosted evidence confirms that the configured workflow completed successfully. Terraform security reporting and container finding enforcement serve different purposes and use different exit-code policies.

The broader [Lab 05 final JSON inventory](../lab-05-container-vulnerability-management/evidence/final/trivy-vulnerability-scan.json) contains 158 residual findings: 44 High, 55 Medium, and 59 Low, with 156 `affected` and two `fix_deferred` statuses. None has a scanner-reported `FixedVersion`. That unfiltered inventory remains distinct from Lab 06's passing, fixable-only gate; it is not an unfiltered inventory of the GitHub-hosted CI image.

Those Lab 05 findings retain the disposition **Monitor / Deferred pending upstream remediation**, as documented in [residual risk](../lab-05-container-vulnerability-management/notes/residual-risk.md). They are neither remediated nor automatically accepted because the CI gate passes. A missing fixed version does not establish non-exploitability or low risk.

## Limitations and Scope

- Findings and exit codes reflect the recorded scans and selected policy. Mutable image tags, `--pull`, scanner data, and the Trivy action's `@master` reference can change subsequent results.
- The supplied local logs do not include full scan command lines or image digests. The workflow defines the CI policy; the logs record local observations, and the screenshot records hosted success.
- The IaC scan reports findings without enforcing a finding threshold or the documented Lab 04 exceptions.
- Runtime identity is displayed in CI without an explicit non-root assertion. Pip absence is supported by local evidence, and application health is not tested by this workflow.
- Triggering on pull requests does not establish branch protection, required checks, or blocked merges. The supplied evidence does not prove those repository settings.
- No AWS or other cloud infrastructure deployment, production readiness, or elimination of all vulnerabilities is established by this lab.
