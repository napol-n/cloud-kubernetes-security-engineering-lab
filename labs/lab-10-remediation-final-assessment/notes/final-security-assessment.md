# Final Security Assessment — Labs 01–10

## Assessment conclusion and method

The repository demonstrates a security-engineering workflow from baseline assessment through targeted remediation, verification, automated checks, and final regression review. The evidence supports specific improvements to container execution, Kubernetes workload configuration, IaC, image vulnerability management, CI validation, RBAC, and network segmentation. It also retains unresolved findings and explicit coverage limits.

This assessment reviews existing artifacts only. Baseline captures describe the state before each lab's remediation; they are not presented as the current hardened state. Final captures are observations of particular artifacts and identities at capture time. Findings, policy tests, and authorization checks have different scopes and are not combined into a single security score. The [control matrix](control-remediation-matrix.md) provides traceability, and [residual risk](residual-risk.md) records the limitations.

## Container hardening — Lab 01

**Baseline weaknesses:** The [baseline capture](../../lab-01-container-security-baseline/evidence/baseline/container-security-baseline.txt) records UID 0, a writable root filesystem, retained effective capabilities, no explicit memory/CPU/PID limits, and no healthcheck. Privileged mode was already disabled. It also records different image IDs for the running container and the mutable baseline tag.

**Remediation and verification:** The [hardened capture](../../lab-01-container-security-baseline/evidence/hardened/container-security-hardened.txt) records UID/GID 999, a read-only root filesystem, zero capability sets, `no-new-privileges`, 128 MiB memory, 0.5 CPU, and a PID limit of 100. A root-filesystem write was blocked, an explicit `/tmp` write succeeded, and `/health` returned HTTP 200 with Docker health reported as healthy.

**Residual risk:** These controls restrict the tested container's execution environment. They do not establish absence of vulnerable packages, resistance to all container escapes, or equivalence between images identified only by mutable tags.

## Kubernetes deployment and workload security — Labs 02–03

**Baseline and context:** Lab 02's [deployment capture](../../lab-02-kubernetes-deployment/evidence/deployment-final.txt) establishes a functional application behind a ClusterIP Service with non-root identity. The existing [self-healing evidence](../../lab-02-kubernetes-deployment/evidence/self-healing-test.txt) records replacement of a deleted Pod, endpoint reconciliation, and restored HTTP 200. That historical destructive test was not rerun for Lab 10.

Lab 03's [security baseline](../../lab-03-kubernetes-security-assessment/evidence/baseline/security-baseline.txt) shows missing explicit workload controls, no resource settings, a mounted ServiceAccount token, `NoNewPrivs: 0`, and `Seccomp: 0`. The process already ran as UID/GID 999 with zero effective capabilities; the weakness was not root execution in this Kubernetes baseline, but reliance on defaults and incomplete workload enforcement.

**Remediation and verification:** The [hardened runtime capture](../../lab-03-kubernetes-security-assessment/evidence/hardened/security-hardened.txt) records explicit non-root execution, UID/GID 999, privilege escalation disabled, a read-only filesystem, zero capability sets, `NoNewPrivs: 1`, seccomp filter mode, and an absent ServiceAccount token. CPU/memory requests and limits are present; a filesystem write is blocked and application health remains healthy.

The [Lab 10 configuration retest](../evidence/final/kubernetes-security-retest.txt) records the security settings again, including `capabilities.drop=["ALL"]`, requests of `50m` CPU and `32Mi` memory, and limits of `500m` CPU and `128Mi` memory. It does not repeat Lab 03's runtime kernel-state, token-presence, or filesystem-write evidence.

**Residual risk:** Workload configuration and a historical recovery test do not establish cluster-wide hardening or high availability. The records do not establish that this Kubernetes Deployment was updated to the Lab 05 remediated image.

## Terraform / IaC security — Lab 04

**Baseline weaknesses:** The [baseline scan](../../lab-04-terraform-iac-security/evidence/baseline/trivy-config-scan.txt) reports seven S3 misconfigurations involving public-access controls, logging, versioning, and encryption.

**Remediation and verification:** The [hardened Terraform](../../lab-04-terraform-iac-security/terraform/hardened/main.tf) configures public-access blocking, versioning, application-bucket access logging, a customer-managed KMS key with rotation for application data, and a separately protected logging destination using SSE-S3. The [final scan](../../lab-04-terraform-iac-security/evidence/hardened/trivy-config-scan-final.txt) retains two findings on the logging destination: AWS-0089 (Low) and AWS-0132 (High).

**Residual risk:** The [existing exception review](../../lab-04-terraform-iac-security/notes/residual-findings.md) classifies AWS-0089 as an accepted contextual exception and AWS-0132 as an accepted technical exception, based on its recorded logging-destination rationale and scanner guidance. These remain scanner findings; this assessment carries forward the lab's documented dispositions without treating them as eliminated or granting production approval. The [Lab 04 scope](../../lab-04-terraform-iac-security/README.md) states that no AWS infrastructure was deployed, so static controls were not verified in a live cloud environment.

## Container vulnerability management — Lab 05

**Baseline weaknesses:** The [baseline inventory](../../lab-05-container-vulnerability-management/evidence/baseline/trivy-vulnerability-scan.json) contains 203 package-level findings, including 45 with reported fixed versions.

**Remediation and verification:** The [remediation record](../../lab-05-container-vulnerability-management/notes/remediation-retest.md) documents targeted OS upgrades followed by removal of unneeded pip tooling. The [final inventory](../../lab-05-container-vulnerability-management/evidence/final/trivy-vulnerability-scan.json) contains 158 findings, none with a reported fixed version. The [runtime retest](../../lab-05-container-vulnerability-management/evidence/final/runtime-retest.txt) confirms non-root identity, pip absence, healthy application output, and healthy container status.

**Residual risk:** The [residual summary](../../lab-05-container-vulnerability-management/evidence/final/residual-risk-summary.txt) records 44 High, 55 Medium, and 59 Low findings. These are package-level findings, not 158 distinct vulnerability IDs. Their [existing disposition](../../lab-05-container-vulnerability-management/notes/residual-risk.md) is **Monitor / Deferred pending upstream remediation**. No reported fixed version does not mean non-exploitable, accepted, or remediated. These results belong to the scanned Lab 05 image, not automatically to every application image.

## Secure CI/CD validation — Lab 06

**Baseline weakness and remediation:** Build success alone does not detect or enforce remediation of vulnerable dependencies. The [workflow](../../../.github/workflows/security-ci.yml) adds Terraform validation, IaC reporting, and a container vulnerability gate using the Lab 05 remediated Dockerfile. It declares `contents: read`; it contains no publication or deployment step.

**Verification:** The [local failure log](../../lab-06-secure-cicd-pipeline/evidence/failure/container-security-gate.txt) records 45 gate-visible findings and `TrivyExitCode=1`; the [final local gate](../../lab-06-secure-cicd-pipeline/evidence/final/container-security-gate.txt) records zero gate-visible findings and `TrivyExitCode=0`. Separate [runtime evidence](../../lab-06-secure-cicd-pipeline/evidence/final/container-runtime-verification.txt) confirms UID/GID 999 and pip absence. The [hosted-run screenshot](../../lab-06-secure-cicd-pipeline/evidence/final/github-actions-success.png) shows successful Repository Checks, Terraform Security, and Container Security jobs.

**Residual risk:** The container gate uses `ignore-unfixed: true`; passing it does not clear Lab 05's unfiltered residual inventory. IaC scanning uses finding exit code 0 and does not enforce the exception list. The runtime identity command prints identity without asserting non-root execution. Branch protection and required merge checks are not demonstrated. The Lab 06 screenshot predates the later Policy as Code job and does not verify a hosted run of that job.

## RBAC least privilege — Lab 07

**Baseline weakness:** The [baseline authorization capture](../../lab-07-kubernetes-rbac-least-privilege/evidence/baseline/effective-permissions.txt) shows that `system:serviceaccount:default:lab07-app-sa` could list/delete Pods and get/list Secrets in `default`. Node deletion and access to `kube-system` Secrets were already denied.

**Remediation and verification:** The [remediation record](../../lab-07-kubernetes-rbac-least-privilege/notes/remediation-retest.md) documents removal of the unnecessary RoleBinding and Role, retaining the dedicated ServiceAccount with token automount disabled. The [final authorization capture](../../lab-07-kubernetes-rbac-least-privilege/evidence/final/effective-permissions.txt) and [Lab 10 regression](../evidence/final/rbac-regression.txt) deny all six tested operations. Lab 10 also records `automountServiceAccountToken=false`.

**Residual risk:** The final permission list still contains other authorization entries, including discovery and self-review access. These tests establish denial for the named identity and operations, not zero API permissions, coverage of every identity, or attempted execution of the destructive operations. The evidence does not establish that the main application Deployment uses this dedicated ServiceAccount.

## Network segmentation — Lab 08

**Baseline weakness:** Both clients reached the backend with HTTP 200 before segmentation, as recorded in the [baseline](../../lab-08-workload-network-hardening/evidence/baseline/connectivity-baseline.txt).

**Remediation and verification:** The [effective NetworkPolicy](../../lab-08-workload-network-hardening/evidence/final/network-policy-effective.yaml) selects `app=backend` in `lab08` and permits ingress from same-namespace Pods labeled `access=authorized` on TCP/80. Both the [Lab 08 retest](../../lab-08-workload-network-hardening/evidence/final/connectivity-retest.txt) and [Lab 10 regression](../evidence/final/network-regression.txt) preserve authorized HTTP 200 while the unauthorized path reports `HTTP 000` and `CurlExitCode=28`. Lab 10 explicitly records a connection timeout. Together, these support blocked connectivity for the tested unauthorized path; `HTTP 000` is absence of an HTTP response, not an application rejection status.

**Residual risk:** The policy is ingress-only and label-based. The captures do not establish egress isolation, application authentication, authorization to change labels/policies, or coverage of other clients, namespaces, ports, and protocols.

## Policy as Code — Lab 09

**Baseline weakness and remediation:** The [Rego policy](../../lab-09-policy-as-code/policies/kubernetes.rego) makes ten explicit Deployment requirements executable: non-root execution, disabled privilege escalation, read-only filesystem, dropped capabilities, disabled token automount, pod seccomp, and CPU/memory requests and limits. The [baseline evaluation](../../lab-09-policy-as-code/evidence/baseline/policy-evaluation.txt) records 10 failures and exit code 1 against Lab 02's manifest. The [hardened evaluation](../../lab-09-policy-as-code/evidence/final/policy-evaluation.txt) records 10 passes, zero failures, and exit code 0 against Lab 03's manifest.

**Verification and limits:** The current workflow configures that hardened-manifest check. Existing [mutation notes](../../lab-09-policy-as-code/notes/remediation-retest.md) report missing-field validation but explicitly state that separate mutation transcripts are not retained. They are not additional Lab 10 executions. The policy checks Deployments and regular containers; it does not cover other resource kinds, init/ephemeral containers, numeric resource sizing, or admission-time/live-cluster enforcement.

## Final regression testing — Lab 10

The five final captures support these scoped conclusions:

| Evidence | Recorded outcome and assessment boundary |
| --- | --- |
| [Project state](../evidence/final/project-state.txt) | Node Ready, Deployment 1/1 available, application Pod 1/1 Running. The Pod has two recorded restarts; this is not evidence of uninterrupted operation. Docker lists both baseline and hardened containers. |
| [Kubernetes retest](../evidence/final/kubernetes-security-retest.txt) | Explicit workload hardening settings and resource values retained in the capture; configuration evidence rather than a repeat of every runtime test. |
| [Policy regression](../evidence/final/policy-regression.txt) | 10 tests, 10 passed, zero warnings/failures/exceptions, `ConftestExitCode=0`. |
| [RBAC regression](../evidence/final/rbac-regression.txt) | All six named authorization queries return no; token automount is false for the assessed ServiceAccount. |
| [Network regression](../evidence/final/network-regression.txt) | Authorized HTTP 200; unauthorized timeout, HTTP 000, exit 28. Intended segmentation demonstrated for these two paths. |

The policy regression records Conftest `dev` and OPA `1.21.0`; Lab 09 records Conftest `0.62.0` and OPA `1.6.0`. Lab 10's capture omits the exact invocation and manifest target, so its recorded result cannot establish identical toolchain or input provenance with Lab 09. Lab 10 also contains no fresh image scan, IaC scan, or hosted CI run; those conclusions rely on their earlier evidence sets.

The final recorded checks support targeted remediation and retained controls within this local lab. They do not establish production security, complete Kubernetes security, or zero residual risk.
