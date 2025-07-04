project_name     =  "pw"
region           = "us-east-1"
env                  = "poc"

#tags
map_tagging = {
  track         = "devops"
  project       = "pw"
  env           = "poc"
}

# EKS settings
eks_version      = "1.32"  # Replace with your desired EKS version
# desired_size     = 2
# max_size         = 3
# min_size         = 2
# instance_type    = "t2.medium"
# disk_size        = 40
# max_unavailable  = 1
# ami_type         = "AL2"

# karpenter_version = "1.0.6"
# karpenter_vcpu    = "10"
# karpenter_memory  = "100"

# account_id  = "256482947245"
# 730335309831
account_id  = "730335309831"

################################################################################################
# Security Group Rules
################################################################################################


# # Security Group Rules
# master_ingress_rules = [
#   {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow incoming HTTPS traffic from anywhere"
#   },
#   {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"  # -1 means all protocols
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all incoming traffic"
#   }
# ]


# master_egress_rules = [
#   {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outgoing traffic"
#   }
# ]

# workers_ingress_rules = [
#   {
#     from_port   = 1025
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/8"]
#     description = "Allow incoming traffic from VPC CIDR"
#   },
#   {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"  # -1 means all protocols
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all incoming traffic"
#   }
# ]

# workers_egress_rules = [
#   {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outgoing traffic"
#   }
# ]


# Security Group Rules
master_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS traffic from anywhere"
  }
]

master_egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outgoing traffic"
  }
]

workers_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS incoming traffic from anywhere"
  },
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"  
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP incoming traffic from anywhere"
  }
]

workers_egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outgoing traffic"
  }
]



metrics_server_version  = "3.12.2"