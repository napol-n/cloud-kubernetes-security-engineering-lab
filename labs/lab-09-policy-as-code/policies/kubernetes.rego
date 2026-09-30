package main

import rego.v1

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot == true
    msg := sprintf(
        "container %q must set securityContext.runAsNonRoot=true",
        [container.name],
    )
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.allowPrivilegeEscalation == false
    msg := sprintf(
        "container %q must set allowPrivilegeEscalation=false",
        [container.name],
    )
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.readOnlyRootFilesystem == true
    msg := sprintf(
        "container %q must set readOnlyRootFilesystem=true",
        [container.name],
    )
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not drops_all_capabilities(container)
    msg := sprintf(
        "container %q must drop ALL Linux capabilities",
        [container.name],
    )
}

drops_all_capabilities(container) if {
    "ALL" in container.securityContext.capabilities.drop
}

deny contains msg if {
    input.kind == "Deployment"
    not input.spec.template.spec.automountServiceAccountToken == false
    msg := "Deployment must set automountServiceAccountToken=false"
}

deny contains msg if {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.seccompProfile.type == "RuntimeDefault"
    msg := "Deployment must set pod securityContext.seccompProfile.type=RuntimeDefault"
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.cpu
    msg := sprintf("container %q must define CPU requests", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("container %q must define memory requests", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("container %q must define CPU limits", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("container %q must define memory limits", [container.name])
}
