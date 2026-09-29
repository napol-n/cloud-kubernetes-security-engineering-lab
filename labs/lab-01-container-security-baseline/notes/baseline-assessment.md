# Container Security Baseline Assessment

## Scope

Assessment of the initial `cloud-k8s-security-lab:baseline` container configuration before security hardening.

## Baseline Findings

| Control | Observed State | Assessment |
|---|---|---|
| Runtime user | UID 0 (`root`) | Hardening required |
| Explicit image user | Not configured | Hardening required |
| Privileged mode | Disabled | Positive control |
| Root filesystem | Writable | Hardening required |
| Linux capabilities | Default effective capabilities retained | Hardening required |
| Memory limit | Not configured | Hardening required |
| CPU limit | Not configured | Hardening required |
| PID limit | Not configured | Hardening required |
| Container healthcheck | Not configured | Hardening required |

## BL01-01 — Root Runtime Identity

The application process runs as UID 0 (`root`). The application does not require root privileges to listen on TCP port 8080.

Recommended control:

- Create a dedicated non-root application user.
- Configure the image to run under that identity.

## BL01-02 — Writable Root Filesystem

The container root filesystem is writable. A controlled write test successfully created and read a file under `/tmp`.

Recommended control:

- Run the container with a read-only root filesystem.
- Provide explicit writable storage only where required.

## BL01-03 — Default Linux Capabilities Retained

The baseline process retains Docker's default effective Linux capability set.

Recommended control:

- Drop all Linux capabilities.
- Add back only capabilities demonstrated to be required.

## BL01-04 — Resource Controls Not Configured

No explicit memory, CPU, or PID limits are configured for the baseline container.

Recommended control:

- Apply explicit runtime resource limits.
- Validate that legitimate application functionality remains available.

## BL01-05 — Container Healthcheck Not Configured

The application exposes `/health`, but the image does not define a container healthcheck.

Recommended control:

- Add a healthcheck that validates the application health endpoint.

## Positive Control — Privileged Mode Disabled

The baseline container is not running with Docker privileged mode enabled.

## Artifact Identity Observation

The running container references a different immutable image ID from the image currently referenced by the mutable `baseline` tag.

This demonstrates that an image tag is not a stable artifact identity after a rebuild. Immutable image IDs or digests should be used when exact artifact provenance is required.

## Remediation Status

Not yet implemented.

Post-hardening retesting is required before any baseline weakness is considered remediated.
