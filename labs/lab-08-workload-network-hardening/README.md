# Lab 08: Workload Network Hardening

## Objective

Restrict ingress to the backend to the intended client group while preserving legitimate connectivity. This lab documents an evidence-driven assessment and remediation of missing namespace workload network segmentation.

## Scenario

The [baseline workload manifest](manifests/baseline/workloads.yaml) defines namespace `lab08` with three Pods and a backend Service:

| Workload | Label | Role |
| --- | --- | --- |
| `backend` | `app=backend` | Backend served on TCP/80 |
| `authorized-client` | `access=authorized` | Intended backend client |
| `unauthorized-client` | `access=unauthorized` | Client outside the intended access boundary |

The backend Service selects `app=backend` and maps port 80 to target port 80. Baseline evidence records it as a `ClusterIP` Service with no external IP. The assessed traffic is east-west Pod-to-backend traffic within `lab08`.

## Baseline

No NetworkPolicy existed during baseline testing. The [baseline capture](evidence/baseline/connectivity-baseline.txt) has an empty NetworkPolicies section and records HTTP 200 for both clients reaching the backend. The intended and unauthorized clients therefore both had working backend connectivity.

## Security Assessment

The backend accepted traffic from both tested clients because no NetworkPolicy restricted ingress. The demonstrated finding is a lack of namespace workload network segmentation: the intended boundary between authorized clients and other workloads was unenforced.

This gives an unintended workload a network path to the backend and an opportunity to send requests. The evidence establishes reachability only; it does not establish application privileges, access to sensitive data, or a production incident. See the [security assessment](notes/security-assessment.md) for the trust boundary, impact, and limitations.

## Remediation

The [hardened manifest](manifests/hardened/network-policy.yaml) defines NetworkPolicy `backend-ingress` in `lab08`. It selects destination Pods labeled `app=backend`, applies to ingress, and permits TCP/80 from Pods labeled `access=authorized` in the same namespace.

The [effective NetworkPolicy capture](evidence/final/network-policy-effective.yaml) contains the same policy name, namespace, selectors, ingress direction, and port. This policy expresses access by Pod label, rather than by a single Pod name. It does not configure egress restrictions.

## Retest

The [final retest capture](evidence/final/connectivity-retest.txt) records `backend-ingress` selecting `app=backend`. The authorized client still received HTTP 200. The unauthorized client produced curl output `HTTP 000` and `CurlExitCode=28`.

`HTTP 000` is curl output indicating that no HTTP response was received; it is not an HTTP status code. Combined with exit code 28, it demonstrates a connection timeout. In this recorded retest, unauthorized east-west connectivity was blocked while legitimate connectivity remained functional. See the [remediation and retest notes](notes/remediation-retest.md) for the evidence review methodology.

## Before/After

| Check | Baseline | Final retest |
| --- | --- | --- |
| Backend ingress policy | No NetworkPolicy | `backend-ingress` selects `app=backend` |
| `authorized-client` → `backend` | HTTP 200 | HTTP 200; legitimate connectivity preserved |
| `unauthorized-client` → `backend` | HTTP 200 | curl output `HTTP 000`, exit 28; connection timeout |
| Tested access boundary | Both clients could reach backend | Unauthorized path blocked; authorized path functional |

## Evidence

| Artifact | What it establishes |
| --- | --- |
| [Baseline workloads](manifests/baseline/workloads.yaml) | Namespace, Pod labels, backend Service mapping |
| [Hardened NetworkPolicy](manifests/hardened/network-policy.yaml) | Intended ingress restriction |
| [Baseline connectivity](evidence/baseline/connectivity-baseline.txt) | No baseline policy and HTTP 200 from both clients |
| [Final connectivity](evidence/final/connectivity-retest.txt) | Policy presence, preserved authorized access, unauthorized timeout |
| [Effective NetworkPolicy](evidence/final/network-policy-effective.yaml) | Captured policy configuration matching the hardened manifest |

## Security Workflow

1. Establish workload identities and the intended client-to-backend boundary from the workload manifest.
2. Review baseline connectivity and the absence of a NetworkPolicy.
3. Identify excessive reachability across the intended boundary.
4. Define backend ingress restricted to authorized Pods on TCP/80.
5. Compare the hardened manifest with the captured effective policy.
6. Compare both recorded client paths before and after remediation, including curl's exit code.
7. Record the result and the limits of what was demonstrated.

This documentation was finalized from existing artifacts. No connectivity tests were rerun, and no Kubernetes resources, manifests, or existing evidence were changed during this review.

## Result

The recorded final state demonstrates successful segmentation for the two tested client paths in `lab08`: authorized connectivity remained functional and unauthorized east-west connectivity was blocked. The evidence does not establish behavior for other workloads, namespaces, ports, or protocols.
