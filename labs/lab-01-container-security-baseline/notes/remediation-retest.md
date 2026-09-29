# Container Hardening — Remediation and Retest

## Summary

The baseline container was assessed for runtime identity, filesystem permissions, Linux capabilities, resource controls, health monitoring, and privilege configuration.

Targeted hardening controls were implemented and formally retested against the original baseline criteria.

## Results

| ID | Control | Baseline | Hardened | Result |
|---|---|---|---|---|
| BL01-01 | Runtime identity | UID 0 (`root`) | UID 999 (`appuser`) | Remediated — Retest Passed |
| BL01-02 | Root filesystem | Writable | Read-only | Remediated — Retest Passed |
| BL01-03 | Linux capabilities | Default effective capabilities | All capabilities dropped | Remediated — Retest Passed |
| BL01-04 | Resource controls | No explicit memory, CPU, or PID limits | 128 MiB memory, 0.5 CPU, PID limit 100 | Remediated — Retest Passed |
| BL01-05 | Container healthcheck | Not configured | Configured and healthy | Remediated — Retest Passed |

## Additional Hardening

The hardened runtime also applies:

- `no-new-privileges`
- explicit writable `/tmp` using `tmpfs`
- `noexec` and `nosuid` on the temporary filesystem
- non-root application ownership
- privileged mode remains disabled

## Functional Regression Validation

The hardened application continued to return HTTP 200 from `/health`.

The Docker runtime reported the container as `healthy`.

## Filesystem Validation

A controlled write attempt under `/app` failed with a read-only filesystem error as expected.

A controlled write under the explicitly permitted `/tmp` tmpfs succeeded.

This demonstrates that writable storage was restricted rather than indiscriminately removed.

## Capability Validation

The baseline process retained Docker's default effective Linux capabilities.

After hardening, `CapEff`, `CapPrm`, `CapBnd`, `CapInh`, and `CapAmb` were all zero.

## Final Disposition

BL01-01 through BL01-05:

**Remediated — Retest Passed**

No failed remediation retests were observed.
