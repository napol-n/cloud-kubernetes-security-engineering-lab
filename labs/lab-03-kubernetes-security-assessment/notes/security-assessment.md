# Kubernetes Security Assessment

## Scope

This assessment evaluated the Kubernetes workload created in Lab 02, focusing on workload-level security controls and their effective runtime state.

The assessment followed this workflow:

```text
Baseline Deployment
        ↓
Configuration Inspection
        ↓
Runtime Validation
        ↓
Finding Classification
        ↓
Security Hardening
        ↓
Runtime Retest
        ↓
Functional Validation

Baseline
The application was already running as the non-root appuser account with UID/GID 999 because of the container image configuration.
However, the Kubernetes workload did not explicitly enforce several workload security controls.
K8S-01 — Non-root Execution Not Enforced by Kubernetes
Baseline:
- Runtime process executed as UID 999.
- runAsNonRoot was unset.
- runAsUser was unset.
- Non-root execution therefore depended on the container image rather than Kubernetes workload policy.
Remediation:
- runAsNonRoot: true
- runAsUser: 999
- runAsGroup: 999
Retest:
- Runtime remained UID/GID 999.
- Kubernetes explicitly enforced the expected identity.
Status: Remediated — Retest Passed
K8S-02 — Read-only Root Filesystem Not Enforced
Baseline:
- readOnlyRootFilesystem was unset.
- A write to /app failed because of Unix ownership and permissions, not because the root filesystem was read-only.
- /tmp remained writable.
Remediation:
- readOnlyRootFilesystem: true
Retest:
- Write attempt to /tmp failed with Read-only file system.
Status: Remediated — Retest Passed
K8S-03 — Privilege Escalation Protection Not Enforced
Baseline runtime:
NoNewPrivs: 0

allowPrivilegeEscalation was not explicitly disabled.
Remediation:
- allowPrivilegeEscalation: false
Retest:
NoNewPrivs: 1

Status: Remediated — Retest Passed
K8S-04 — Linux Capabilities Not Explicitly Dropped
Baseline runtime:
CapEff: 0000000000000000
CapBnd: 00000000a80425fb

The process had no effective capabilities, but the capability bounding set remained non-zero and the Kubernetes workload did not explicitly drop all capabilities.
Remediation:
capabilities:
  drop:
    - ALL

Retest:
CapInh: 0000000000000000
CapPrm: 0000000000000000
CapEff: 0000000000000000
CapBnd: 0000000000000000
CapAmb: 0000000000000000

Status: Remediated — Retest Passed
K8S-05 — Seccomp Filtering Not Enabled
Baseline:
- No explicit seccomp profile was configured.
- Runtime reported:
Seccomp: 0
Seccomp_filters: 0

Remediation:
seccompProfile:
  type: RuntimeDefault

Retest:
Seccomp: 2
Seccomp_filters: 1

Status: Remediated — Retest Passed
K8S-06 — Resource Requests and Limits Not Defined
Baseline:
Resources={}

No explicit CPU or memory requests or limits were configured.
Remediation:
CPU request:     50m
Memory request:  32Mi
CPU limit:       500m
Memory limit:    128Mi

Retest confirmed all four resource controls.
Status: Remediated — Retest Passed
K8S-07 — Unnecessary Service Account Token Mount
Baseline:
- Pod used the default ServiceAccount.
- A projected ServiceAccount token was present inside the container.
- The application does not require Kubernetes API access for its intended functionality.
This finding concerns unnecessary credential exposure rather than excessive RBAC privileges.
Remediation:
automountServiceAccountToken: false

Retest:
ServiceAccountToken=absent

Status: Remediated — Retest Passed
Positive Controls
The baseline already contained useful security properties:
- Application process executed as non-root UID/GID 999.
- Effective capability set was zero.
- /app was protected from writes by Unix ownership and permissions.
These controls were retained while Kubernetes-level enforcement was strengthened.
Functional Retest
After remediation:
Application health: {"status": "healthy"}
Pod Ready: true
Restarts: 0

The hardened workload therefore retained expected application functionality.
Final Result
Seven Kubernetes workload hardening gaps were identified and remediated.
Finding	Final Status
K8S-01 Non-root enforcement	Remediated — Retest Passed
K8S-02 Read-only root filesystem	Remediated — Retest Passed
K8S-03 Privilege escalation protection	Remediated — Retest Passed
K8S-04 Linux capability restriction	Remediated — Retest Passed
K8S-05 Seccomp filtering	Remediated — Retest Passed
K8S-06 Resource controls	Remediated — Retest Passed
K8S-07 ServiceAccount token exposure	Remediated — Retest Passed


The final workload demonstrates explicit Kubernetes security enforcement rather than relying solely on container-image defaults.
