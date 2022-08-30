package main

deny[msg] {
   input.kind = "service"
   not input.spec.type = "LoadBalancer"
   msg = "Service type should be LoadBalancer"
}

deny[msg] {
   input.kind = "Deployment"
   not input.spec.template.spec.containers[0].securityContext.runAsNonRoot = true
   msg = "Containers must not run as root - use runAsNonRoot within container security context"
}