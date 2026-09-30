# Lab 10 — Remediation & Final Security Assessment

## Objective and scope

Consolidate the security work across Labs 01–09 and assess the final recorded regression results. Lab 10 is the final validation and assessment phase, rather than a new vulnerability test. It connects historical weaknesses, implemented controls, verification, and remaining limitations into an evidence-driven security assessment.

This assessment uses existing repository artifacts only. No security tests, resource changes, or destructive tests were performed for this documentation. Baseline evidence remains a historical record; hardened and final captures describe their respective tested states, not every artifact or workload in the repository.

## Final regression summary

| Area | Recorded result | Evidence |
| --- | --- | --- |
| Project state | Node Ready; application Deployment available at 1/1; application Pod Running at 1/1. This is a state snapshot, not a security test. | [Project state](evidence/final/project-state.txt) |
| Kubernetes workload | Non-root enforcement, privilege escalation disabled, read-only root filesystem, all capabilities dropped, `RuntimeDefault` seccomp, token automount disabled, and CPU/memory requests and limits recorded. | [Kubernetes security retest](evidence/final/kubernetes-security-retest.txt) |
| Policy as Code | **10 tests, 10 passed, 0 failures; Conftest exit code 0.** | [Policy regression](evidence/final/policy-regression.txt) |
| RBAC | `list pods`, `delete pods`, `get secrets`, `list secrets`, `delete nodes`, and `get kube-system secrets`: **no** for `system:serviceaccount:default:lab07-app-sa`; `automountServiceAccountToken=false`. | [RBAC regression](evidence/final/rbac-regression.txt) |
| Network segmentation | `authorized-client -> backend`: **HTTP 200**. `unauthorized-client -> backend`: **HTTP 000**, `CurlExitCode=28`, with a recorded connection timeout. | [Network regression](evidence/final/network-regression.txt) |

`HTTP 000` means curl received no HTTP response; it is not an HTTP status returned by the backend. The timeout, together with the policy evidence and successful authorized path, supports blocked unauthorized connectivity for the tested path.

The Kubernetes retest records configuration; earlier Lab 03 evidence supplies runtime verification. The Lab 10 policy capture records Conftest `dev` and OPA `1.21.0`, whereas Lab 09 records Conftest `0.62.0` and OPA `1.6.0`. These are separate recorded evaluations, not proof of identical toolchains.

## Assessment documents

- [Final security assessment](notes/final-security-assessment.md) — security posture and evidence boundaries across Labs 01–10.
- [Control and remediation matrix](notes/control-remediation-matrix.md) — historical risks, controls, verification, and scoped dispositions.
- [Residual risk](notes/residual-risk.md) — remaining findings, environmental limitations, and controls not demonstrated.

## Final result

The recorded Lab 10 regressions support the retained workload hardening configuration, passing policy checks, denied tested RBAC operations, and intended segmentation for the two tested network paths. Earlier evidence demonstrates targeted remediation with retained application functionality. Residual image vulnerabilities and documented IaC exceptions remain; this assessment does not establish zero risk, production readiness, or complete Kubernetes security.
