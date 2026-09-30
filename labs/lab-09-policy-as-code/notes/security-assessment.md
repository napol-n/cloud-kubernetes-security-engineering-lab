# Lab 09 — Security Assessment

## Objective and scope

Use Conftest and OPA/Rego to turn Kubernetes Deployment hardening requirements into executable checks. This assessment compares the [Lab 02 baseline](../../lab-02-kubernetes-deployment/manifests/deployment.yaml) with the [Lab 03 hardened Deployment](../../lab-03-kubernetes-security-assessment/manifests/deployment-hardened.yaml) against the current [Rego v1 policy](../policies/kubernetes.rego).

The policy's denial rules are restricted to `kind: Deployment`. Container checks inspect `spec.template.spec.containers`; service-account-token and seccomp checks inspect pod-level fields under `spec.template.spec`.

## Findings

The baseline manifest omits every required field below. Its [recorded evaluation](../evidence/baseline/policy-evaluation.txt) reports all ten denials. The hardened manifest explicitly supplies the required values and passes the [final evaluation](../evidence/final/policy-evaluation.txt).

| Required control | Baseline | Hardened manifest |
| --- | --- | --- |
| `securityContext.runAsNonRoot == true` | Missing; denied | `true` |
| `securityContext.allowPrivilegeEscalation == false` | Missing; denied | `false` |
| `securityContext.readOnlyRootFilesystem == true` | Missing; denied | `true` |
| `securityContext.capabilities.drop` contains `ALL` | Missing; denied | `[ALL]` |
| Pod `automountServiceAccountToken == false` | Missing; denied | `false` |
| Pod `securityContext.seccompProfile.type == RuntimeDefault` | Missing; denied | `RuntimeDefault` |
| `resources.requests.cpu` required | Missing; denied | `50m` |
| `resources.requests.memory` required | Missing; denied | `32Mi` |
| `resources.limits.cpu` required | Missing; denied | `500m` |
| `resources.limits.memory` required | Missing; denied | `128Mi` |

Paths without the Pod prefix are relative to each regular container. The resource values shown describe the current hardened manifest; the policy requires their presence without enforcing those exact values.

## Evidence results

Both evidence files identify Conftest **0.62.0** and OPA **1.6.0**.

| Evaluation | Tests | Passed | Failures | Warnings | Exceptions | Exit code |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Baseline | 10 | 0 | 10 | 0 | 0 | 1 |
| Hardened | 10 | 10 | 0 | 0 | 0 | 0 |

The baseline's non-zero exit makes the missing controls actionable as a build failure. The hardened result confirms that Lab 03's manifest satisfies all ten Lab 09 checks.

## Missing-field enforcement

The policy uses negated equality checks for required boolean values and the pod seccomp profile. Undefined fields therefore trigger denial. A helper checks whether the container drops `ALL` capabilities; negating that helper also rejects missing `capabilities` or `drop` fields.

The [mutation validation](remediation-retest.md) separately removed capabilities, automatic token-mount configuration, and the seccomp profile from temporary hardened manifests. Each previously verified run produced 10 tests, 9 passed, 1 failure, and exit code 1. This demonstrates fail-closed handling of these omissions. Mutation transcripts are not retained in the repository; the stored evidence files cover baseline and hardened evaluations.

## CI enforcement and limits

The [Security CI workflow](../../../.github/workflows/security-ci.yml) configures a `policy-as-code` gate using Conftest **0.62.0** against the Lab 03 hardened Deployment. A non-zero policy result fails the job. Existing local evidence does not establish that a remote workflow run has completed or that branch protection requires this job.

This policy checks the ten listed manifest controls. It does not evaluate live workloads, non-Deployment resources, init or ephemeral containers, exact UID/GID values, or numeric resource sizing. Lab 03's additional settings are not all represented as Lab 09 rules. Passing the gate establishes compliance with this policy's scope, not complete Kubernetes security.
