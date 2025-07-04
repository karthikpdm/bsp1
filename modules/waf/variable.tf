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