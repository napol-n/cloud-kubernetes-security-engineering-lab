# Lab 03 — Kubernetes Security Assessment

## Status

✅ Completed

## Objective

Assess the Kubernetes workload created in Lab 02, identify workload-level security hardening gaps, implement explicit Kubernetes security controls, and validate both the resulting runtime security state and application functionality.

## Workflow

```text
Baseline Deployment
        ↓
Inspect Configuration
        ↓
Validate Runtime State
        ↓
Classify Findings
        ↓
Apply Hardening
        ↓
Retest Security Controls
        ↓
Validate Application Health

Assessment Summary
Seven Kubernetes workload hardening gaps were identified:
1. Non-root execution was not explicitly enforced by Kubernetes.
2. The root filesystem was not configured read-only.
3. Privilege escalation protection was not explicitly enabled.
4. Linux capabilities were not explicitly dropped.
5. Seccomp filtering was not enabled.
6. CPU and memory resource controls were not defined.
7. An unnecessary ServiceAccount token was mounted into the application Pod.
The baseline application already executed as UID/GID 999 and had no effective Linux capabilities, but these properties were partly dependent on image/runtime defaults rather than explicit Kubernetes workload controls.
Remediation
The hardened workload implements:
- runAsNonRoot: true
- explicit UID/GID 999
- allowPrivilegeEscalation: false
- readOnlyRootFilesystem: true
- capabilities.drop: [ALL]
- seccompProfile: RuntimeDefault
- CPU and memory requests/limits
- automountServiceAccountToken: false
- readiness and liveness probes
Retest
Runtime verification confirmed:
- non-root identity retained
- all capability sets reduced to zero
- NoNewPrivs: 1
- seccomp filter mode enabled
- root filesystem writes blocked
- ServiceAccount token absent
- resource controls present
Application functionality remained healthy:
{"status": "healthy"}
Ready=true
Restarts=0

Evidence
Baseline evidence:
- evidence/baseline/deployment-effective.yaml
- evidence/baseline/pod-effective.yaml
- evidence/baseline/runtime-identity.txt
- evidence/baseline/security-baseline.txt
Hardened evidence:
- evidence/hardened/security-hardened.txt
Assessment:
- notes/security-assessment.md
Hardened manifest:
- manifests/deployment-hardened.yaml
Result
7 findings remediated — 7 retests passed.
The workload moved from relying partly on container-image defaults to explicit Kubernetes workload-level security enforcement.
