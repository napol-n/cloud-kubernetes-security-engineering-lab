# Residual Risk and Assessment Limitations

The final lab state retains risk. This review separates targeted remediations from remaining findings, limitations of the environment and evidence, and controls not demonstrated. It does not grant production risk acceptance or treat a passing test as proof of zero risk.

## Remediated risks within the tested scope

| Historical weakness | Supported disposition |
| --- | --- |
| Container root execution, writable root filesystem, retained capabilities, absent limits and healthcheck | The [Lab 01 hardened capture](../../lab-01-container-security-baseline/evidence/hardened/container-security-hardened.txt) demonstrates non-root identity, filesystem restrictions, zero capabilities, explicit limits, and healthy application behavior. |
| Incomplete Kubernetes workload enforcement and unnecessary mounted token | The [Lab 03 runtime retest](../../lab-03-kubernetes-security-assessment/evidence/hardened/security-hardened.txt) demonstrates explicit restrictions and token absence; [Lab 10](../evidence/final/kubernetes-security-retest.txt) records retained configuration. |
| Fixable vulnerabilities in the Lab 05 baseline image | The [final image scan](../../lab-05-container-vulnerability-management/evidence/final/trivy-vulnerability-scan.json) has zero findings with reported fixed versions after the documented remediation; this does not clear unfixed vulnerabilities. |
| Excessive application-specific RBAC grants for lab07-app-sa | The [final authorization list](../../lab-07-kubernetes-rbac-least-privilege/evidence/final/effective-permissions.txt) no longer contains the introduced Pod/Secret grants; [Lab 10](../evidence/final/rbac-regression.txt) repeats the tested denials. |
| Unauthorized client reachability to the Lab 08 backend | The [effective ingress policy](../../lab-08-workload-network-hardening/evidence/final/network-policy-effective.yaml) and [Lab 10 retest](../evidence/final/network-regression.txt) support blocked unauthorized connectivity while authorized HTTP 200 remains available. |
| Missing required fields in the historical Deployment baseline | The [Lab 09 hardened evaluation](../../lab-09-policy-as-code/evidence/final/policy-evaluation.txt) passes the ten configured policy checks. The historical baseline manifest remains evidence, not a newly hardened artifact. |

IaC remediation is documented in the [control matrix](control-remediation-matrix.md); its two retained exceptions are listed below separately from eliminated weaknesses.

## Residual findings and control gaps

| Item | Evidence and remaining risk | Recorded disposition or assessment boundary |
| --- | --- | --- |
| Unfixed image vulnerabilities | Lab 05's [residual summary](../../lab-05-container-vulnerability-management/evidence/final/residual-risk-summary.txt) records 158 findings: 44 High, 55 Medium, 59 Low; 156 affected and 2 fix_deferred. None has a scanner-reported fixed version. | **Monitor / Deferred pending upstream remediation**, per the [existing review](../../lab-05-container-vulnerability-management/notes/residual-risk.md). Absence of a fix does not establish non-exploitability or acceptance. |
| S3 logging-destination findings | The [final IaC scan](../../lab-04-terraform-iac-security/evidence/hardened/trivy-config-scan-final.txt) retains AWS-0089 (Low, logging disabled) and AWS-0132 (High, no customer-managed key) on the dedicated logging destination. | The [Lab 04 review](../../lab-04-terraform-iac-security/notes/residual-findings.md) records **Accepted — Contextual Exception** and **Accepted — Technical Exception**, respectively. Its rationale is avoiding recursive logging and retaining SSE-S3 under the recorded scanner guidance. These are lab dispositions, not eliminated findings or independent production approval. |
| CI finding coverage | The [workflow](../../../.github/workflows/security-ci.yml) ignores unfixed container findings and sets the IaC finding exit code to 0. | Container-gate success is narrower than a clean unfiltered inventory. IaC findings do not block the job by finding count, and the documented exceptions are not enforced as an allowlist. |
| Artifact identity and remediation propagation | Lab 01's [baseline](../../lab-01-container-security-baseline/evidence/baseline/container-security-baseline.txt) shows tag/image-ID divergence; the [Lab 03 manifest](../../lab-03-kubernetes-security-assessment/manifests/deployment-hardened.yaml) uses the hardened tag, while Lab 05's [runtime capture](../../lab-05-container-vulnerability-management/evidence/final/runtime-retest.txt) identifies a separate lab05-final image. | The repository does not establish deployment of the Lab 05 remediated image to the main Kubernetes workload, or identical image digests across local and hosted CI. Image-scan results must remain attached to their assessed artifact. |
| Limited network boundary | The [effective policy](../../lab-08-workload-network-hardening/evidence/final/network-policy-effective.yaml) restricts ingress by Pod label and TCP/80; it defines no egress restriction. | The two successful regression outcomes do not establish isolation of other traffic or control of who may change labels/policies. See the [Lab 08 scope](../../lab-08-workload-network-hardening/notes/security-assessment.md). |
| Limited RBAC coverage | [Final permissions](../../lab-07-kubernetes-rbac-least-privilege/evidence/final/effective-permissions.txt) retain discovery and self-review entries; Lab 10 checks one named identity and six operations. | Denial of the tested operations is not zero API access or an audit of all identities/bindings. Token automount configuration is not itself proof that no credential can ever be supplied. |
| Limited policy coverage | The [policy](../../lab-09-policy-as-code/policies/kubernetes.rego) targets Deployments, regular containers, and selected pod fields; resource checks require presence. | Passing does not validate all workload kinds, init/ephemeral containers, numeric sizing, or enforcement at admission time. |

## Environmental and evidence limitations

- **Local, single-node environment.** The [cluster baseline](../../lab-02-kubernetes-deployment/evidence/cluster-baseline.txt) identifies a local kind cluster and one control-plane node. The [final project snapshot](../evidence/final/project-state.txt) shows one available application replica and two recorded Pod restarts. These captures do not demonstrate production resilience, multi-node behavior, or uninterrupted availability.
- **Historical baselines coexist with hardened artifacts.** The final project snapshot lists a running `cloud-k8s-baseline` container alongside hardened containers. It does not include a fresh security inspection of that baseline container. The assessment therefore does not claim environment-wide remediation or removal of every intentionally weak artifact.
- **IaC was assessed statically.** The [Lab 04 scope](../../lab-04-terraform-iac-security/README.md) explicitly records no AWS deployment. Cloud runtime behavior, actual log delivery, and deployed encryption/access controls were not demonstrated.
- **Captures establish recorded states.** The [Lab 10 configuration retest](../evidence/final/kubernetes-security-retest.txt) does not include the runtime checks retained in Lab 03. The [network capture](../evidence/final/network-regression.txt) records a timeout but omits the exact request command, URL, and packet traces. It supports the tested connectivity result, not a packet-level explanation or continuing enforcement after configuration changes.
- **Policy toolchains differ.** [Lab 09](../../lab-09-policy-as-code/evidence/final/policy-evaluation.txt) records Conftest 0.62.0 / OPA 1.6.0; [Lab 10](../evidence/final/policy-regression.txt) records Conftest dev / OPA 1.21.0 without an exact command or target. Both report 10 passes, but exact execution equivalence is not established. The [mutation notes](../../lab-09-policy-as-code/notes/remediation-retest.md) acknowledge that separate mutation transcripts are not stored.
- **Hosted CI evidence has a defined scope.** The [Lab 06 screenshot](../../lab-06-secure-cicd-pipeline/evidence/final/github-actions-success.png) shows three successful jobs. It does not demonstrate the later policy job, prove local/hosted digest equality, or establish repository branch-protection settings. Lab 10 does not contain new hosted CI, image-scan, or IaC-scan evidence.

## Controls not demonstrated

The assessed artifacts do not establish the following controls. “Not demonstrated” identifies a coverage limit, not proof that a control is absent from every possible environment.

| Control | Basis for excluding a claim |
| --- | --- |
| Cluster-wide admission enforcement or comprehensive node/control-plane hardening | The [policy](../../lab-09-policy-as-code/policies/kubernetes.rego) and [workflow](../../../.github/workflows/security-ci.yml) evaluate a manifest; the [workload retest](../evidence/final/kubernetes-security-retest.txt) records selected workload settings. |
| Application authentication, authorization, TLS, or Internet exposure assessment | The [network assessment](../../lab-08-workload-network-hardening/notes/security-assessment.md) limits observations to internal client-to-backend connectivity and explicitly excludes application authentication and Internet reachability conclusions. |
| Required merge checks, signing/attestation, or deployment enforcement | The [workflow](../../../.github/workflows/security-ci.yml) configures CI validation without signing, publication, or deployment steps; the [CI assessment](../../lab-06-secure-cicd-pipeline/README.md) does not establish branch protection. |
| A CI assertion that runtime UID must be non-root, or CI application-health validation | The workflow runs `id` without comparing its result with an expected UID and has no health-endpoint test. The [local runtime evidence](../../lab-06-secure-cicd-pipeline/evidence/final/container-runtime-verification.txt) records identity and pip absence only. |

## Follow-up status

The existing Lab 05 risk disposition calls for monitoring upstream fixes, rebuilding when applicable updates exist, and repeating functional and vulnerability validation. Any future broader assessment would need evidence for the uncovered deployment, identity, network, and enforcement boundaries above. These are follow-up needs, not work completed by Lab 10.

The [final assessment](final-security-assessment.md) supports the demonstrated remediations while retaining these findings and limits. No zero-risk or production-security conclusion is warranted by the repository evidence.
