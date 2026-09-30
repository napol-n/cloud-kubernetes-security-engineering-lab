# Kubernetes RBAC Risk Assessment

## Scope

Lab 07 evaluates Kubernetes RBAC authorization for the dedicated service account:

`system:serviceaccount:default:lab07-app-sa`

The assessment focuses on namespace-scoped access to Pods and Secrets in the `default` namespace.

## Baseline

The intentionally over-privileged baseline used:

- ServiceAccount: `lab07-app-sa`
- Role: `lab07-overprivileged`
- RoleBinding: `lab07-overprivileged-binding`

The Role granted:

- Pods: `get`, `list`, `watch`, `create`, `delete`
- Secrets: `get`, `list`

Effective authorization was verified with `kubectl auth can-i`.

| Authorization Test | Baseline |
| --- | --- |
| List Pods | Allowed |
| Delete Pods | Allowed |
| Get Secrets | Allowed |
| List Secrets | Allowed |
| Delete Nodes | Denied |
| Get Secrets in `kube-system` | Denied |

## Risk Analysis

The application does not require Kubernetes API access to perform its application function.

The baseline permissions therefore violated least privilege.

Pod creation and deletion could allow the identity to modify workload availability within the namespace.

Secret read access could expose sensitive data stored in Kubernetes Secrets within the namespace.

The negative controls demonstrated that the intentionally introduced authorization remained namespace-scoped rather than providing cluster-wide administrative access.

## Remediation Decision

Because the application has no demonstrated requirement for Kubernetes API access, the correct least-privilege configuration is not a reduced application Role.

Instead:

1. The over-privileged RoleBinding was removed.
2. The over-privileged Role was removed.
3. The dedicated ServiceAccount was retained.
4. `automountServiceAccountToken: false` was explicitly configured.

This removes the unnecessary authorization path rather than retaining permissions without a documented requirement.

## Final Authorization State

Post-remediation authorization testing confirmed:

| Authorization Test | Baseline | Final |
| --- | --- | --- |
| List Pods | Allowed | Denied |
| Delete Pods | Allowed | Denied |
| Get Secrets | Allowed | Denied |
| List Secrets | Allowed | Denied |
| Delete Nodes | Denied | Denied |
| Get Secrets in `kube-system` | Denied | Denied |

The final `kubectl auth can-i --list` output no longer contains the Pod or Secret permissions introduced by the Lab 07 Role.

The remaining authorization entries are not granted by the removed Lab 07 Role.

## Result

The intentionally introduced excessive RBAC permissions were successfully identified, verified, removed, and retested.

Final state:

- application-specific Pod permissions: removed
- application-specific Secret permissions: removed
- over-privileged RoleBinding: removed
- over-privileged Role: removed
- ServiceAccount token automount: disabled

Lab 07 therefore demonstrates an evidence-driven Kubernetes RBAC least-privilege workflow:

Assessment → Effective Permission Testing → Risk Analysis → Remediation → Authorization Retest
