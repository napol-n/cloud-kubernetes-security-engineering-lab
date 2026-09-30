# Lab 08 Security Assessment

## Observed baseline behavior

The [workload manifest](../manifests/baseline/workloads.yaml) defines `backend` with label `app=backend`, `authorized-client` with `access=authorized`, and `unauthorized-client` with `access=unauthorized`, all in namespace `lab08`.

No NetworkPolicy existed during baseline testing. The [baseline evidence](../evidence/baseline/connectivity-baseline.txt) records an empty NetworkPolicies section and these results:

| Path | Observed result |
| --- | --- |
| `authorized-client` → `backend` | HTTP 200 |
| `unauthorized-client` → `backend` | HTTP 200 |

The backend accepted east-west traffic from both the intended client and an unauthorized client because no NetworkPolicy restricted ingress. The demonstrated issue is lack of namespace workload network segmentation.

## Trust boundary

The intended boundary is between backend Pods labeled `app=backend` and client workloads in `lab08`. Only clients labeled `access=authorized` should be permitted to reach the backend on TCP/80. The `access=unauthorized` client is outside that intended access group even though it shares the namespace.

The labels identify the intended network access groups in this lab. They are not evidence of application authentication or user permissions. The baseline behavior shows that sharing the namespace allowed both tested clients to reach the backend without the intended network restriction.

## Why this connectivity is excessive

The authorized client needs backend connectivity for its intended role. The unauthorized client has no such intended access in this scenario, yet received the same HTTP 200 connectivity result. Allowing that path exceeds the stated workload access requirement and leaves the backend reachable from a workload outside its intended client group.

## Realistic impact

The demonstrated impact is unwanted backend reachability: the unauthorized client could send a request and receive an HTTP response. Such reachability gives an unintended workload an opportunity to interact with the backend application. Whether particular requests could affect application behavior or expose information depends on application controls and functionality that these artifacts do not assess.

The evidence does not demonstrate exploitation, credentials, sensitive data access, or production impact. HTTP 200 alone establishes successful HTTP connectivity for the recorded request.

## Scope and limitations

- The observations cover two named client Pods reaching one backend in `lab08`.
- The baseline Service is recorded as `ClusterIP` with no external IP. These tests assess internal east-west connectivity and provide no evidence about Internet reachability.
- The captures do not include exact curl commands, request paths, timeout settings, response bodies, or packet traces. Those details cannot be reconstructed from the artifacts.
- Other clients, namespaces, ports, protocols, and egress behavior were not demonstrated by the recorded tests.
- NetworkPolicy controls network reachability. This review does not assess application authentication, Kubernetes administrative permissions, or who can change Pod labels and policies.
- The final observations describe the captured lab state. They do not establish continued enforcement after later label or policy changes. Additional policies selecting the backend could permit other ingress paths; this single policy is not a universal deny override.

## Remediation decision

Use the [NetworkPolicy `backend-ingress`](../manifests/hardened/network-policy.yaml) in namespace `lab08` to select destination Pods labeled `app=backend`. Its ingress rule permits only sources matching `access=authorized` in the same namespace on TCP/80. It expresses the required workload access boundary while retaining the legitimate client path.

The [effective policy capture](../evidence/final/network-policy-effective.yaml) matches those selectors and port settings. The [final retest](../evidence/final/connectivity-retest.txt) records HTTP 200 for the authorized client and curl output `HTTP 000` with exit code 28 for the unauthorized client. `HTTP 000` means no HTTP response was received, not an HTTP status code; together with exit 28, it demonstrates a connection timeout.

These observations support the remediation decision for the tested paths: legitimate connectivity remained functional and unauthorized east-west connectivity was blocked. See the [remediation and retest review](remediation-retest.md) for the comparison.
