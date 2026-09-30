# Kubernetes RBAC Remediation and Retest

## Baseline

A controlled over-privileged RBAC configuration was introduced for `lab07-app-sa`.

The baseline Role permitted:

```text
pods:
  get
  list
  watch
  create
  delete

secrets:
  get
  list
```

Effective authorization testing confirmed that the ServiceAccount could list and delete Pods and get and list Secrets in the `default` namespace.

## Least-Privilege Decision

The application has no demonstrated requirement to communicate with the Kubernetes API.

Granting a smaller arbitrary permission set would therefore still exceed the documented requirement.

The hardened design retains the dedicated ServiceAccount but removes application-specific Role and RoleBinding authorization.

The ServiceAccount also explicitly configures:

```yaml
automountServiceAccountToken: false
```

## Remediation

The following authorization objects were removed:

- `Role/lab07-overprivileged`
- `RoleBinding/lab07-overprivileged-binding`

The hardened ServiceAccount configuration was then applied.

## Retest

The same identity and authorization tests used for the baseline were repeated after remediation.

| Test | Baseline | Final |
| --- | --- | --- |
| `list pods` | yes | no |
| `delete pods` | yes | no |
| `get secrets` | yes | no |
| `list secrets` | yes | no |
| `delete nodes` | no | no |
| `get secrets -n kube-system` | no | no |

The final effective-permissions enumeration no longer contained the Pod or Secret authorization granted by the baseline Role.

The final ServiceAccount configuration also confirmed:

```yaml
automountServiceAccountToken: false
```

## Result

The excessive namespace-scoped RBAC permissions were removed without replacing them with unnecessary permissions.

The final configuration follows least privilege based on the application's demonstrated authorization requirements.
