# output "alb_controller_service_account_name" {
#   description = "Name of the Kubernetes service account created for the AWS Load Balancer Controller"
#   value       = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
# }

# output "alb_controller_namespace" {
#   description = "Kubernetes namespace where the AWS Load Balancer Controller is deployed"
#   value       = kubernetes_service_account.aws_load_balancer_controller.metadata[0].namespace
# }

output "alb_controller_helm_release_name" {
  description = "Name of the Helm release for the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}

output "alb_controller_helm_release_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart deployed"
  value       = helm_release.aws_load_balancer_controller.version
}

output "alb_controller_helm_release_status" {
  description = "Status of the Helm release for the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.status
}

output "customer_namespace_name" {
  value = kubernetes_namespace.customer.metadata[0].name
}

output "website_namespace_name" {
  value = kubernetes_namespace.website.metadata[0].name
}

output "internal_namespace_name" {
  value = kubernetes_namespace.internal.metadata[0].name
}
