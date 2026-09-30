# Lab 09 — Remediation and Retest

## Remediation

The current [policy](../policies/kubernetes.rego) closes missing-field gaps and includes pod-level seccomp enforcement while retaining the existing Deployment-only scope and resource checks:

- `runAsNonRoot` and `readOnlyRootFilesystem` must equal boolean `true`.
- `allowPrivilegeEscalation` must equal boolean `false`.
- The capability helper requires `securityContext.capabilities.drop` to contain `ALL`; its negation denies missing capabilities, missing `drop`, or a list without `ALL`.
- Pod `automountServiceAccountToken` must explicitly equal boolean `false`; omission is denied.
- Pod `securityContext.seccompProfile.type` must equal `RuntimeDefault`; omission is denied.
- CPU and memory requests and limits remain required for each regular container.

The policy uses `import rego.v1` and `deny contains msg if` rules. Recorded evaluations use Conftest **0.62.0** with OPA **1.6.0**.

## Baseline and hardened retest

| Target | Tests | Passed | Failures | Exit code | Stored evidence |
| --- | ---: | ---: | ---: | ---: | --- |
| [Lab 02 baseline](../../lab-02-kubernetes-deployment/manifests/deployment.yaml) | 10 | 0 | 10 | 1 | [Baseline evaluation](../evidence/baseline/policy-evaluation.txt) |
| [Lab 03 hardened](../../lab-03-kubernetes-security-assessment/manifests/deployment-hardened.yaml) | 10 | 10 | 0 | 0 | [Final evaluation](../evidence/final/policy-evaluation.txt) |

Both evaluations report zero warnings and zero exceptions. The baseline evidence lists all ten missing controls. The final evidence shows that the hardened target passes the corrected policy.

## Mutation validation

Each mutation used a separate temporary copy of the hardened manifest under `/tmp`, removing only the indicated field. The repository manifests were not changed.

| Removed field | Expected denial | Tests | Passed | Failures | Exit code |
| --- | --- | ---: | ---: | ---: | ---: |
| Container `securityContext.capabilities` | Must drop `ALL` Linux capabilities | 10 | 9 | 1 | 1 |
| Pod `automountServiceAccountToken` | Must set `automountServiceAccountToken=false` | 10 | 9 | 1 | 1 |
| Pod `securityContext.seccompProfile` | Must set pod `securityContext.seccompProfile.type=RuntimeDefault` | 10 | 9 | 1 | 1 |

These previously verified local results demonstrate fail-closed behavior: removing a required security control changes an otherwise passing manifest into a policy failure. They are not new executions performed for this documentation update. Separate mutation output transcripts are not stored in the repository; the two linked evidence files record only baseline and hardened evaluations.

## CI gate

The [Security CI workflow](../../../.github/workflows/security-ci.yml) checks out the repository, installs Conftest **0.62.0**, and runs the hardened evaluation:

```sh
conftest test \
  labs/lab-03-kubernetes-security-assessment/manifests/deployment-hardened.yaml \
  --policy labs/lab-09-policy-as-code/policies
```

This command runs from the repository root. A policy violation returns a non-zero exit and fails the `policy-as-code` job. The workflow evaluates the hardened target, while the baseline and mutation cases demonstrate rejection locally. The available evidence does not record a remote CI execution.

## Human review

Review the [assessment](security-assessment.md), [policy](../policies/kubernetes.rego), and both evidence files together. The current baseline/final totals are **10/0/10** and **10/10/0** respectively, expressed as tests/passed/failures. Earlier nine-test totals do not describe the current policy.

Status: **Ready for human review**.
