# Lab 07 — Kubernetes RBAC & Least Privilege

## Objective

Assess Kubernetes RBAC permissions, verify effective authorization, identify excessive privileges, remediate the authorization path, and demonstrate least privilege through post-remediation testing.

## Scenario

The existing application did not require Kubernetes API access and already used workload security controls from previous labs.

To evaluate RBAC safely and reproducibly, this lab introduced a controlled namespace-scoped over-privileged identity:

- ServiceAccount: `lab07-app-sa`
- Role: `lab07-overprivileged`
- RoleBinding: `lab07-overprivileged-binding`
- Namespace: `default`

The scenario intentionally avoided modifying Kubernetes system RBAC.

## Baseline Authorization

The baseline Role granted:

| Resource | Verbs |
| --- | --- |
| Pods | `get`, `list`, `watch`, `create`, `delete` |
| Secrets | `get`, `list` |

Effective permissions were tested through the Kubernetes authorization API using `kubectl auth can-i`.

Baseline results:

| Test | Result |
| --- | --- |
| List Pods | Allowed |
| Delete Pods | Allowed |
| Get Secrets | Allowed |
| List Secrets | Allowed |
| Delete Nodes | Denied |
| Read `kube-system` Secrets | Denied |

The negative controls demonstrated that the introduced authorization was namespace-scoped rather than cluster-wide administrative access.

## Risk

The application has no demonstrated requirement to access the Kubernetes API.

The Pod and Secret permissions therefore exceeded the application's required authorization.

Potential impact included:

- workload enumeration
- workload creation or deletion
- namespace workload availability impact
- access to Kubernetes Secret objects in the namespace

## Remediation

Least privilege was implemented by removing the unnecessary authorization path rather than replacing it with arbitrary reduced permissions.

The following resources were removed:

- `Role/lab07-overprivileged`
- `RoleBinding/lab07-overprivileged-binding`

The dedicated ServiceAccount was retained with:


The dedicated ServiceAccount was retained with:

```yaml
automountServiceAccountToken: false
```

## Retest

The same authorization checks were repeated using the same ServiceAccount identity.

| Authorization Test | Baseline | Final |
| --- | --- | --- |
| List Pods | yes | no |
| Delete Pods | yes | no |
| Get Secrets | yes | no |
| List Secrets | yes | no |
| Delete Nodes | no | no |
| Read `kube-system` Secrets | no | no |

The final effective-permissions enumeration no longer contained the Pod or Secret permissions introduced by the baseline Role.

## Evidence

Baseline:

- `evidence/baseline/effective-permissions.txt`

Final:

- `evidence/final/effective-permissions.txt`
- `evidence/final/serviceaccount.yaml`

Manifests:

- `manifests/baseline/rbac.yaml`
- `manifests/hardened/rbac.yaml`

Analysis:

- `notes/risk-assessment.md`
- `notes/remediation-retest.md`

## Security Workflow

```text
RBAC Definition
      ↓
Effective Permission Testing
      ↓
Risk Assessment
      ↓
Least-Privilege Decision
      ↓
Remove Excess Authorization
      ↓
Disable Token Automount
      ↓
Authorization Retest
      ↓
Evidence
```

## Result

Lab 07 demonstrated an evidence-driven Kubernetes RBAC least-privilege workflow.

The controlled baseline showed excessive namespace-scoped Pod and Secret permissions. Those permissions were verified through the Kubernetes authorization API, removed, and retested.

Final application-specific Pod and Secret authorization: **none**.

