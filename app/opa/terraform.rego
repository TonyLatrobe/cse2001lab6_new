package terraform.security

deny[msg] {
  input.resource.kubernetes_pod[_].spec[_].metadata[_].namespace == ""
  msg := "Pod namespace cannot be empty"
}