# Lab 06 — Security Gate Remediation and Retest

## Evidence Chain

The local logs demonstrate failure and successful retest of the container gate. The screenshot independently establishes successful execution of the pushed workflow on GitHub-hosted runners.

```text
Container security gate
    ↓
Local baseline scan: 45 gate-visible findings
    ↓
TrivyExitCode=1
    ↓
Local gate failure
    ↓
Use Lab 05 remediated build: targeted OS upgrades + pip removal
    ↓
Local final scan: 0 gate-visible findings; TrivyExitCode=0
    ↓
Local runtime verification: appuser identity; pip absent
    ↓
GitHub-hosted pushed workflow: Success
```

This is an evidence chain, not the step order inside the hosted workflow. In the workflow, the `id` command runs before the vulnerability scan, and the repository, Terraform, and container jobs have no dependency ordering between them.

## Gate Policy

The [workflow](../../../.github/workflows/security-ci.yml) configures the container scan for `CRITICAL,HIGH,MEDIUM,LOW`, `scanners: vuln`, `ignore-unfixed: true`, and `exit-code: "1"`. Findings that remain within that policy fail the scan step and Container Security job. The `ignore-unfixed` filter excludes findings without a reported fix from this gate.

The Terraform Trivy step instead uses `exit-code: "0"`. It reports misconfigurations without using their presence to fail the job. Terraform initialization, format checking, and validation can still fail on command errors. Successful IaC reporting does not mean the configuration has no security findings or that CI enforces Lab 04's exception dispositions.

## Local Failure

The [failure log](../evidence/failure/container-security-gate.txt) targets `cloud-k8s-security-lab:hardened` and contains these summaries:

| Target | Critical | High | Medium | Low | Findings |
| --- | ---: | ---: | ---: | ---: | ---: |
| Debian packages | 0 | 6 | 27 | 6 | 39 |
| Python / pip | 0 | 0 | 5 | 1 | 6 |
| Combined | 0 | 6 | 32 | 7 | 45 |

The Debian findings are associated with `libssl3t64`, `openssl`, and `openssl-provider-legacy`, each installed at `3.5.7-1~deb13u2` with reported fixed version `3.5.7-1~deb13u3`. The Python findings are associated with pip `25.0.1` and reported fixed versions.

The final line, `TrivyExitCode=1`, records the local gate failure. These 45 package-level findings correspond to the fixable findings in the [Lab 05 baseline JSON](../../lab-05-container-vulnerability-management/evidence/baseline/trivy-vulnerability-scan.json). They are not the full baseline vulnerability inventory and are not evidence of a failed hosted workflow run.

## Remediation and Hardened Build

The current workflow builds `cloud-k8s-security-lab:ci` using [Dockerfile.lab05-remediated](../../../app/Dockerfile.lab05-remediated) and `--pull`.

The existing Dockerfile performs targeted upgrades for `libpcre2-8-0`, `libssl3t64`, `openssl`, and `openssl-provider-legacy`, then removes pip. The finding reduction is attributable to the OpenSSL packages and pip; the local failure log does not attribute findings to `libpcre2-8-0`.

The build preserves the non-root application user, application-file ownership, and healthcheck. [Lab 05 remediation notes](../../lab-05-container-vulnerability-management/notes/remediation-retest.md) document the separate OS-remediation and runtime-tool-removal stages. The final CI workflow selects that remediated build; the Lab 06 artifacts do not supply a hosted failure-run log or a workflow revision history for the transition.

## Local Successful Retest

The [final gate log](../evidence/final/container-security-gate.txt) records:

| Observation | Failure log | Final log |
| --- | --- | --- |
| Image | `cloud-k8s-security-lab:hardened` | `cloud-k8s-security-lab:ci` |
| Debian gate findings | 39 | 0 |
| Language-specific files detected | 1 | 0 |
| Combined gate-visible findings | 45 | 0 |
| Trivy exit code | 1 | 0 |

The final log has no Python vulnerability table and reports no language-specific files. Pip absence is verified by the separate runtime evidence, rather than inferred solely from the missing scan target.

The zero finding result is scoped to the filtered gate. It does not establish that every vulnerability was eliminated.

## Local Runtime Verification

The [runtime verification log](../evidence/final/container-runtime-verification.txt) records:

```text
=== CI Image Runtime Identity ===
uid=999(appuser) gid=999(appgroup) groups=999(appgroup)

=== pip Presence Check ===
RESULT=PASS: pip absent
```

This supports non-root execution and pip absence for the locally checked CI image. It contains no health-endpoint result. The hosted workflow prints `id`, but does not assert a non-root UID, perform the pip-presence check, or run an application health test.

## GitHub Actions Successful Run

The [success screenshot](../evidence/final/github-actions-success.png) shows a push-triggered `Security CI` run on `main` with status **Success**. Repository Checks, Terraform Security, and Container Security all completed successfully.

This supplies hosted CI confirmation in addition to the local validation logs. The screenshot does not supply the full hosted scan output, an image digest match to local tests, branch-protection settings, or a deployment result.

## Residual Risk and Final Interpretation

The [Lab 05 final JSON](../../lab-05-container-vulnerability-management/evidence/final/trivy-vulnerability-scan.json) retains 158 findings across 69 unique vulnerability IDs, with zero reported fixed versions. Its severity counts are 44 High, 55 Medium, and 59 Low; its statuses are 156 `affected` and two `fix_deferred`.

Those broader inventory findings remain **Monitor / Deferred pending upstream remediation** under the [Lab 05 disposition](../../lab-05-container-vulnerability-management/notes/residual-risk.md). They are not remediated or automatically accepted by a successful filtered CI scan. Missing `FixedVersion` values do not prove non-exploitability or low risk, and these Lab 05 counts should not be presented as an unfiltered scan of the hosted CI image.

The supported conclusion is that the local gate rejected the baseline's fixable findings, the remediated local build passed the gate and runtime checks recorded here, and the pushed workflow completed successfully on GitHub Actions. Enforcement is at the scan-step/job level. PR merge blocking, branch protection, cloud deployment, and production readiness are not established by the evidence.
