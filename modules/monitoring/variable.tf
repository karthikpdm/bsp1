variable "email_subscribers" {
  type          = list(string)
  description   = "List of email subscribers for CloudWatch alerts"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "env" {
  type        = string
  description = "Environment (e.g., dev, prod)"
}

variable "map_tagging" {
  description = "MAP tagging for all the resources"
  type        = map(string)
}