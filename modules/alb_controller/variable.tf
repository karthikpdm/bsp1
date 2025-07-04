variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "cluster_ca_certificate" {}
variable "oidc_provider_arn" {}
variable "aws_region" {}
variable "alb_controller_role_arn" {}
variable "env" {}
variable "eks_alb_sg_id" {}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "map_tagging" {
  description = "MAP tagging for all the resources"
  type        = map(string)
}

variable "certificate_arn" {
  description = "ARN of the TLS certificate for HTTPS (if used)"
  type        = string
}



variable "customer_domain" {
  description = "domain name for the customer portal"
  type        = string
}

variable "website_domain" {
  description = "domain name for the customer portal"
  type        = string
}

variable "internal_domain" {
  description = "domain name for the customer portal"
  type        = string
}

variable "eks_websocket_alb_sg_id" {
  type        = string
  description = "Security group ID for the websocket ALB"
}