variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "URL of the EKS OIDC Provider"
  type        = string
}

variable "map_tagging" {
  description = "MAP tagging for all the resources"
  type        = map(string)
}

# variable "account_id" {
#   description = "Source Account ID"
#   type        = string
# }

# variable "eks_s3_bucket_arns" {
#   description = "S3 ARN for eks access"
#   type        = list(string)
# }

# variable "eks_kms_arns" {
#   description = "KMS ARN for eks access"
#   type        = list(string)
# }

# variable "eks_secret_manage_arns" {
#   description = "Secret Manager ARN for eks access"
#   type        = list(string)
# }

# variable "eks_dynamodb_arns" {
#   description = "DynamoDB ARN for eks access"
#   type        = list(string)
# }

