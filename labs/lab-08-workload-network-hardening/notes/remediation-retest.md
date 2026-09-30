# Lab 08 Remediation and Retest

## Baseline

The [baseline capture](../evidence/baseline/connectivity-baseline.txt) records no NetworkPolicy and HTTP 200 from both `authorized-client` and `unauthorized-client` to `backend`. The [workload manifest](../manifests/baseline/workloads.yaml) places all three Pods in `lab08` and defines the backend Service on port 80 with target port 80.

The finding was missing namespace workload network segmentation: both the intended client and a client outside the intended access group could reach the backend.

## Remediation

The [hardened manifest](../manifests/hardened/network-policy.yaml) defines NetworkPolicy `backend-ingress` in namespace `lab08`. The [effective policy capture](../evidence/final/network-policy-effective.yaml) confirms the same configuration in the recorded final state.

| Policy field | Value | Meaning |
| --- | --- | --- |
| `metadata.name` | `backend-ingress` | Policy name |
| `metadata.namespace` | `lab08` | Namespace containing the policy and selected backend Pods |
| `spec.podSelector.matchLabels` | `app: backend` | Select destination backend Pods |
| `spec.policyTypes` | `Ingress` | Restrict incoming traffic to selected Pods |
| `spec.ingress[].from[].podSelector.matchLabels` | `access: authorized` | Permit source Pods matching the authorized label |
| `spec.ingress[].ports[]` | `protocol: TCP`, `port: 80` | Permit the backend's TCP/80 path |

The source selector has no `namespaceSelector`, so it selects authorized Pods in the policy's own namespace, `lab08`. The authorized client matches `access=authorized`; the unauthorized client, labeled `access=unauthorized`, does not match. The rule applies by label, not by client Pod name.

## Allowed TCP/80 path

The permitted path is a source Pod in `lab08` labeled `access=authorized` reaching a destination Pod in `lab08` labeled `app=backend` on TCP/80. The backend Service maps port 80 to target port 80 and selects the backend label.

This ingress policy contains no allowance for the unauthorized client's label and configures no egress restrictions. Other policies can add ingress permissions, so the recorded retest is the evidence for the observed unauthorized block in this lab state.

## Retest methodology

This review uses the existing retest capture; it does not execute new tests or change resources.

1. Compare the two named client-to-backend paths in the baseline and final connectivity captures.
2. Check the final policy listing for `backend-ingress` and its `app=backend` destination selector.
3. Compare the hardened manifest with the effective policy capture for namespace, ingress direction, source and destination selectors, protocol, and port.
4. Check that the authorized path still receives HTTP 200.
5. Interpret the unauthorized client's curl output together with its recorded exit code.

The captures identify the paths and outcomes but omit the exact commands, request URLs, timeout duration, and packet traces. This review does not claim those unrecorded details or reproduce a test procedure from them.

## Before/after results

| Check | Baseline evidence | Final evidence |
| --- | --- | --- |
| NetworkPolicy | None during baseline testing | `backend-ingress`, selector `app=backend` |
| `authorized-client` → `backend` | HTTP 200 | HTTP 200 |
| `unauthorized-client` → `backend` | HTTP 200 | curl output `HTTP 000` |
| Unauthorized curl exit code | Not recorded | `CurlExitCode=28` |
| Observed segmentation | Both tested clients reached backend | Authorized path functional; unauthorized path blocked |

Sources: [baseline connectivity](../evidence/baseline/connectivity-baseline.txt), [final connectivity](../evidence/final/connectivity-retest.txt), and [effective policy](../evidence/final/network-policy-effective.yaml).

## Interpretation of `HTTP 000` and exit 28

`HTTP 000` is curl output indicating that no HTTP response was received. It is not an HTTP status code and is not a backend rejection response. Combined with `CurlExitCode=28`, it demonstrates a connection timeout for the unauthorized path.

The timeout, the matching effective ingress policy, and the authorized client's continued HTTP 200 response support the recorded conclusion that unauthorized east-west connectivity was blocked while legitimate connectivity remained functional. The artifacts do not reveal the exact packet handling mechanism or establish results for untested paths.

## Final result

The existing evidence demonstrates the intended segmentation for the two tested paths in `lab08`. NetworkPolicy `backend-ingress` selects `app=backend` and permits ingress from same-namespace Pods labeled `access=authorized` on TCP/80. Authorized connectivity remained functional; unauthorized east-west connectivity timed out and was blocked in the retest.

The [security assessment](security-assessment.md) describes the trust boundary and limitations, and the [Lab 08 README](../README.md) summarizes the workflow and evidence.
