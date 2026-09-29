# Lab 01 — Container Security Baseline

## Status

✅ Completed

## Objective

Establish a reproducible container security baseline, identify security-relevant configuration weaknesses, implement targeted hardening controls, and validate the resulting security posture.

## Workflow

```text
Build
  ↓
Run
  ↓
Inspect
  ↓
Establish Baseline
  ↓
Identify Weaknesses
  ↓
Harden
  ↓
Retest
  ↓
Compare
```

## Baseline Assessment
The initial container demonstrated five hardening weaknesses:
1. Application process running as root
2. Writable root filesystem
3. Default Linux capabilities retained
4. No explicit memory, CPU, or PID limits
5. No container healthcheck
Privileged mode was disabled and retained as a positive security control.
The assessment also demonstrated that a mutable image tag may reference a different image after rebuild while an existing container continues to use the original immutable image.
Hardening
The hardened container implements:
- dedicated non-root application user
- read-only root filesystem
- explicit /tmp tmpfs
- all Linux capabilities dropped
- no-new-privileges
- memory limit
- CPU limit
- PID limit
- application healthcheck
Retest Result
All five targeted baseline weaknesses were remediated and passed post-hardening validation.
Legitimate application functionality remained available:
GET /health → HTTP 200
Container health → healthy

Evidence
Baseline
[`evidence/baseline/container-security-baseline.txt`](evidence/baseline/container-security-baseline.txt)
Hardened
[`evidence/hardened/container-security-hardened.txt`](evidence/hardened/container-security-hardened.txt)
Notes
- [Baseline assessment](notes/baseline-assessment.md)
- [Remediation and retest](notes/remediation-retest.md)
Final Disposition
Baseline weaknesses identified: 5
Remediated:                    5
Retest passed:                 5
Retest failed:                 0

Lab 01 complete.
