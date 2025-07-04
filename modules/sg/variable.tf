variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "my-eks-project"
}

variable "env" {
  type        = string
  description = "Environment (e.g., dev, prod)"
  default     = "dev"
}

variable "map_tagging" {
  description = "MAP tagging for all the resources"
  type        = map(string)
}

# variable "eks_workers_sg_id" {
#   type        = string
#   description = "worker sg id"
# }
########################################################################################################
                # master_ingress_rules
########################################################################################################


variable "master_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of ingress rules for EKS master"
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.11.0.0/19"]
      description = "Allow HTTPS from anywhere (for kubectl)"
    }
  ]
}


#######################################################################################################

variable "master_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of egress rules for EKS master"
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.11.0.0/19"]
      description = "Allow all outbound traffic"
    }
  ]
}

#########################################################################################################
                # worker_rules
########################################################################################################
variable "workers_ingress_rules" {
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    description     = string
  }))
  description = "List of ingress rules for EKS workers"
}

########################################################################################################

variable "workers_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of egress rules for EKS workers"
}

#########################################################################################################
                # eks_alb_rules
########################################################################################################
variable "eks_alb_ingress_rules" {
  description = "List of ingress rules for EKS ALB security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    security_groups  = optional(list(string))
    description      = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      security_groups = []
      description = "Allow HTTP traffic"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      security_groups = []
      description = "Allow HTTPS traffic"
    }
  ]
}
########################################################################################################

variable "eks_alb_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  description = "List of egress rules for EKS workers"
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}