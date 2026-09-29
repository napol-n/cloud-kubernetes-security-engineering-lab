# Lab 02 — Kubernetes Deployment

## Status

✅ Completed

## Objective

Deploy the hardened container image from Lab 01 to a local Kubernetes cluster, establish a reproducible Kubernetes workload baseline, expose the application through an internal Service, validate application functionality, and demonstrate Kubernetes reconciliation behavior.

## Architecture

```text
Docker
  ↓
kind Cluster
  ↓
Kubernetes Control Plane
  ↓
Deployment
  ↓
ReplicaSet
  ↓
Pod
  ↓
Container
  ↓
ClusterIP Service
  ↓
Application :8080

Environment
The lab uses:
- Docker Desktop
- kind
- kubectl
- Kubernetes v1.37.0
- single-node local Kubernetes cluster
- containerd runtime
Cluster:
cloud-k8s-security

kubectl context:
kind-cloud-k8s-security

Container Image
The hardened image produced in Lab 01 was loaded into the kind cluster:
cloud-k8s-security-lab:hardened

The image retained its non-root runtime identity when executed by Kubernetes:
uid=999(appuser) gid=999(appgroup) groups=999(appgroup)

Kubernetes Resources
Deployment
cloud-k8s-security-app

Desired replicas:
1

Service
cloud-k8s-security-service

Service type:
ClusterIP

Port:
8080/TCP

The application is not exposed externally through NodePort or LoadBalancer.
Functional Validation
The application was validated through the Kubernetes Service using port forwarding.
GET /health
HTTP 200
{"status": "healthy"}

Application health was also validated directly from the running Pod.
Self-Healing Validation
The original application Pod was intentionally deleted.
Before deletion:
Pod IP: 10.244.0.5
Service Endpoint: 10.244.0.5:8080

Kubernetes reconciled the Deployment back to its desired state and created a replacement Pod.
After reconciliation:
Pod: cloud-k8s-security-app-779846487-kbh5k
Pod IP: 10.244.0.6
State: 1/1 Running
Restarts: 0

The Service EndpointSlice automatically updated to:
10.244.0.6:8080

A post-reconciliation request to /health returned HTTP 200.
Result: PASS
Security Boundary
This lab establishes a functional Kubernetes deployment baseline.
The container image includes image-level hardening from Lab 01, but Kubernetes-specific workload security controls are intentionally not assessed or remediated here.
Those controls will be evaluated separately in Lab 03.
Examples include:
- Kubernetes securityContext
- explicit runAsNonRoot
- privilege escalation controls
- capability configuration at the Pod/container level
- read-only root filesystem enforcement at the workload level
- resource requests and limits
- service account configuration
- workload exposure
Evidence
- [Cluster baseline](evidence/cluster-baseline.txt)
- [Final deployment state](evidence/deployment-final.txt)
- [Self-healing test](evidence/self-healing-test.txt)
Manifests
- [kind configuration](manifests/kind-config.yaml)
- [Deployment](manifests/deployment.yaml)
- [Service](manifests/service.yaml)
Final Result
Cluster created:               PASS
Node Ready:                    PASS
System workloads operational: PASS
Deployment available:         PASS
Pod Running:                   PASS
Non-root identity preserved:  PASS
Service routing:              PASS
Application health:           PASS
Self-healing:                 PASS
Endpoint reconciliation:      PASS

Lab 02 complete.
