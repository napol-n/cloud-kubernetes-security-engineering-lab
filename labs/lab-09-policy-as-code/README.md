# Lab 09 — Policy-as-Code

## Objective

Implement Policy-as-Code for Kubernetes Deployment security using Conftest and OPA/Rego. Evaluate the insecure Lab 02 manifest, verify the Lab 03 hardened manifest, and enforce the same policy in CI.

## Scope and results

The [policy](policies/kubernetes.rego) uses Rego v1 and applies only to `Deployment` resources. Recorded evaluations used Conftest **0.62.0** with OPA **1.6.0**.

| Target | Tests | Passed | Failures | Exit code | Evidence |
| --- | ---: | ---: | ---: | ---: | --- |
| [Lab 02 baseline](../lab-02-kubernetes-deployment/manifests/deployment.yaml) | 10 | 0 | 10 | 1 | [Baseline evaluation](evidence/baseline/policy-evaluation.txt) |
| [Lab 03 hardened](../lab-03-kubernetes-security-assessment/manifests/deployment-hardened.yaml) | 10 | 10 | 0 | 0 | [Final evaluation](evidence/final/policy-evaluation.txt) |

Both recorded evaluations report zero warnings and zero exceptions. These results validate manifest policy compliance; they do not establish runtime behavior or a completed GitHub Actions run.

## Enforced controls

Container controls apply to each entry in `spec.template.spec.containers`. Pod controls apply under `spec.template.spec`.

| Control | Required value or presence |
| --- | --- |
| Container `securityContext.runAsNonRoot` | `true` |
| Container `securityContext.allowPrivilegeEscalation` | `false` |
| Container `securityContext.readOnlyRootFilesystem` | `true` |
| Container `securityContext.capabilities.drop` | Exists and contains `ALL` |
| Pod `automountServiceAccountToken` | Explicitly `false` |
| Pod `securityContext.seccompProfile.type` | `RuntimeDefault` |
| Container `resources.requests.cpu` | Required |
| Container `resources.requests.memory` | Required |
| Container `resources.limits.cpu` | Required |
| Container `resources.limits.memory` | Required |

Missing required fields fail evaluation. Resource rules require CPU and memory requests and limits; they do not enforce particular quantities.

## Mutation validation

Prior local validation removed one control at a time from temporary copies of the hardened manifest under `/tmp`:

| Mutation | Tests | Passed | Failures | Exit code |
| --- | ---: | ---: | ---: | ---: |
| Remove container `securityContext.capabilities` | 10 | 9 | 1 | 1 |
| Remove pod `automountServiceAccountToken` | 10 | 9 | 1 | 1 |
| Remove pod `securityContext.seccompProfile` | 10 | 9 | 1 | 1 |

Each removal triggered its corresponding denial, demonstrating fail-closed behavior for these missing security controls. These are previously verified local results; separate mutation transcripts are not stored in the repository. See [remediation and retest](notes/remediation-retest.md) for details.

## CI integration

The [Security CI workflow](../../.github/workflows/security-ci.yml) includes a `policy-as-code` job for pushes and pull requests targeting `main`. The job checks out the repository, installs Conftest **0.62.0** from the official Linux x86_64 release tarball, and evaluates the hardened Kubernetes Deployment using this command from the repository root:

```sh
conftest test \
  labs/lab-03-kubernetes-security-assessment/manifests/deployment-hardened.yaml \
  --policy labs/lab-09-policy-as-code/policies
```

A policy failure returns a non-zero exit code and fails the job. The configured job evaluates the hardened target; the baseline is a local negative control. No successful remote CI run is claimed by the local evidence.

## Security workflow

```text
Insecure manifest
  -> policy evaluation
  -> CI failure
  -> hardened manifest
  -> policy re-evaluation
  -> CI security gate
```

The baseline's exit code 1 demonstrates the rejection that would fail the CI job if that manifest were evaluated. The hardened manifest's exit code 0 satisfies the policy gate. This workflow describes enforcement behavior, not a recorded sequence of remote CI runs.

## Review material

- [Security assessment](notes/security-assessment.md)
- [Remediation and retest](notes/remediation-retest.md)
- [Baseline evidence](evidence/baseline/policy-evaluation.txt)
- [Final evidence](evidence/final/policy-evaluation.txt)
- [Rego policy](policies/kubernetes.rego)

Status: **Ready for human review**.
