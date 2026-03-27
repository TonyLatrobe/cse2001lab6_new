package terraform.security

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "kubernetes_pod"
  namespace := resource.change.after.metadata[_].namespace
  namespace == ""
  msg := "Pod namespace cannot be empty"
}