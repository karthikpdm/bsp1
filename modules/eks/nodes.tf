# # # EKS Node Group Resource
# # resource "aws_eks_node_group" "node-grp" {
# #   cluster_name    = aws_eks_cluster.eks.name
# #   node_group_name = "${var.project_name}-eks-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
# #   node_role_arn   = var.worker_role_arn
# #   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

# #   scaling_config {
# #     desired_size = var.desired_size
# #     max_size     = var.max_size
# #     min_size     = var.min_size
# #   }

# #   update_config {
# #     max_unavailable = var.max_unavailable
# #   }
  
# #   ami_type              = "CUSTOM"
# #   force_update_version  = true
  
# #   launch_template {
# #     version = aws_launch_template.eks-node.latest_version
# #     name    = aws_launch_template.eks-node.name
# #   }

# #   tags = merge(
# #     { "Name"    = "${var.project_name}-node-group-${var.env}" },
# #     { "karpenter.sh/discovery/${aws_eks_cluster.eks.name}" = aws_eks_cluster.eks.name },
# #     { "karpenter.k8s.aws/cluster"                          = var.env }, 
# #     var.map_tagging
# #   )
  
# #   lifecycle {
# #     create_before_destroy = true
# #     ignore_changes        = [node_group_name]
# #   }
# # }

# # data "aws_ami" "eks-worker-ami" {
# #   filter {
# #     name   = "name"
# #     values = ["amazon-eks-node-${var.eks_version}-*"]
# #   }

# #   most_recent = true
# #   owners      = ["601401143451"] # Amazon Account ID
# # }

# # resource "aws_launch_template" "eks-node" {
# #   name = "${var.project_name}-eks-nodes-${var.env}"

# #   metadata_options {
# #     http_endpoint               = "enabled"
# #     http_tokens                 = "required"
# #     http_put_response_hop_limit = 1
# #     instance_metadata_tags      = "disabled"
# #   }

# #   network_interfaces {
# #     associate_public_ip_address = false
# #     #security_groups             = [var.eks_worker_sg_id]
# #   }

# #   monitoring {
# #     enabled = true
# #   }

# #   image_id      = data.aws_ami.eks-worker-ami.id
# #   instance_type = var.instance_type

# #   user_data = base64encode(local.node-userdata)
  
# #   block_device_mappings {
# #     device_name = "/dev/xvda" # Default root volume device name for Amazon Linux and Ubuntu
# #     ebs {
# #       delete_on_termination = true
# #       encrypted             = true
# #       volume_size           = var.disk_size             # Root volume size in GiB
# #       volume_type           = "gp3"          # General Purpose SSD
# #     }
# #   }

# #   tags = {
# #     Name                                                 = "${var.project_name}-eks-nodes-${var.env}"
# #     "karpenter.k8s.aws/cluster"                          = var.env
# #     "karpenter.sh/discovery/${aws_eks_cluster.eks.name}" = aws_eks_cluster.eks.name
# #     "kubernetes.io/cluster/clusterName"                  = "owned"
# #   }
  
# #   tag_specifications {
# #     resource_type = "instance"
    
# #     tags = merge(
# #     { "Name"    = "${var.project_name}-eks-node-${var.env}" },
# #     var.map_tagging
# #     )
# #   }
  
# #   tag_specifications {
# #     resource_type = "volume"
    
# #     tags = merge(
# #     { "Name"    = "${var.project_name}-eks-node-volume-${var.env}" },
# #     var.map_tagging
# #     )
# #   }
# # }

# # data "aws_autoscaling_groups" "eks_asg" {
# #   filter {
# #     name   = "tag:eks:nodegroup-name"
# #     values = [aws_eks_node_group.node-grp.node_group_name]
# #   }
# # }

# # resource "aws_autoscaling_group_tag" "eks_asg_extra_tags" {

# #   for_each = var.map_tagging
  
# #   autoscaling_group_name = tolist(data.aws_autoscaling_groups.eks_asg.names)[0]
  
# #   tag {
# #     key                 = each.key
# #     value               = each.value
# #     propagate_at_launch = true
# #   }
# # }




##########################################################################################################################################################################################







# Creation of the EC2 instance for hosting Istio + Keycloak
resource "aws_eks_node_group" "osdu_ir_istio_node" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "pw-eks-istio-node-${var.env}"
  node_role_arn   = var.worker_role_arn
  subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["m5.xlarge"]
  disk_size = 80

  ami_type      = "AL2_x86_64"
  capacity_type = "ON_DEMAND"

  # Add labels for node scheduling
  labels = {
    "node-role"     = "osdu-istio-keycloak"
    "workload-type" = "istio"
    "component"     = "service-mesh"
    # Required for Calico CNI
    "kubernetes.io/os"                                = "linux"
    "projectcalico.org/operator-node-migration"       = "migrated"
  }

  # Add taints to ensure only Istio/Keycloak pods run here
  # taint {
  #   key    = "node-role"
  #   value  = "osdu-istio-keycloak"
  #   effect = "NO_SCHEDULE"
  # }

  tags = {
    Name                                        = "osdu-ir-istio-worker-node"
    "kubernetes.io/cluster/" = "owned"
  }

  # depends_on = [
  #   aws_eks_cluster.osdu-ir-eks-cluster,
  #   aws_iam_role_policy_attachment.osdu-ir-worker-node-policy-attach,
  #   aws_iam_role_policy_attachment.osdu-ir-eks-cni-policy-attach,
  #   aws_iam_role_policy_attachment.osdu-ir-eks-registry-policy-attach
  # ]
}

# Creation of the EC2 instance for hosting MinIO + PostgreSQL + Elasticsearch + RabbitMQ
resource "aws_eks_node_group" "osdu_ir_backend_node" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "pw-eks-backend-nodes-${var.env}"
  # name = "${var.project_name}-eks-backend-nodes-${var.env}"
  node_role_arn   = var.worker_role_arn
  subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

   instance_types = ["m5.xlarge"]
  disk_size = 80

  ami_type      = "AL2_x86_64"
  capacity_type = "ON_DEMAND"

  # Add labels for node scheduling
  labels = {
    "node-role"         = "osdu-backend"
    "workload-type"     = "database"
    "component"         = "backend-services"
    "storage-optimized" = "true"
    # Required for Calico CNI
    "kubernetes.io/os"                                = "linux"
    "projectcalico.org/operator-node-migration"       = "migrated"
  }

  # # Add taints for backend workloads
  # taint {
  #   key    = "node-role"
  #   value  = "osdu-backend"
  #   effect = "NO_SCHEDULE"
  # }

  tags = {
    Name                                        = "osdu-ir-backend-worker-node"
    "kubernetes.io/cluster/" = "owned"
  }

  # depends_on = [
  #   aws_eks_cluster.osdu-ir-eks-cluster,
  #   aws_iam_role_policy_attachment.osdu-ir-worker-node-policy-attach,
  #   aws_iam_role_policy_attachment.osdu-ir-eks-cni-policy-attach,
  #   aws_iam_role_policy_attachment.osdu-ir-eks-registry-policy-attach
  # ]
}

# ✅ OPTIMIZED: Creation of the EC2 instance for hosting OSDU Microservices + Airflow + Redis (UNTAINTED)
resource "aws_eks_node_group" "osdu_ir_frontend_node" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "pw-eks-frontend-node-${var.env}"
  node_role_arn   = var.worker_role_arn
  subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["m5.xlarge"]
  disk_size = 80

  ami_type      = "AL2_x86_64"
  capacity_type = "ON_DEMAND"

  # Add labels for node scheduling
  labels = {
    "node-role"         = "osdu-frontend"
    "workload-type"     = "microservices"
    "component"         = "osdu-apis"
    "compute-optimized" = "true"
    # Required for Calico CNI
    "kubernetes.io/os"                                = "linux"
    "projectcalico.org/operator-node-migration"       = "migrated"
  }

  # ✅ OPTIMIZED: No taints on frontend nodes - allows flexible scheduling for all OSDU microservices
  # This ensures OSDU microservices can schedule here without needing specific tolerations

  tags = {
    Name                                        = "osdu-ir-frontend-worker-node"
    "kubernetes.io/cluster/" = "owned"
  }

  # depends_on = [
  #   aws_eks_cluster.osdu-ir-eks-cluster,
  #   aws_iam_role_policy_attachment.osdu-ir-worker-node-policy-attach,
  #   aws_iam_role_policy_attachment.osdu-ir-eks-cni-policy-attach,
  #   aws_iam_role_policy_attachment.osdu-ir-eks-registry-policy-attach
  # ]
}

































# #################################################################################################################################################################




# # Creation of the EC2 instance for hosting Istio + Keycloak
# resource "aws_eks_node_group" "osdu_ir_istio_node" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "pw-eks-istio-node-${var.env}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   # Use launch template for Calico optimization
#   launch_template {
#     name    = aws_launch_template.calico_istio_template.name
#     version = aws_launch_template.calico_istio_template.latest_version
#   }

#   # Note: When using launch_template, these are defined in the template
#   # instance_types = ["m5.xlarge"]
#   # disk_size = 80
#   # ami_type      = "AL2_x86_64"
  
#   capacity_type = "ON_DEMAND"

#   # Add labels for node scheduling + Calico support
#   labels = {
#     "node-role"     = "osdu-istio-keycloak"
#     "workload-type" = "istio"
#     "component"     = "service-mesh"
    
#     # Required for Calico CNI
#     "kubernetes.io/os"                                = "linux"
#     "projectcalico.org/operator-node-migration"       = "migrated"
#   }

#   # Add taints to ensure only Istio/Keycloak pods run here
#   # taint {
#   #   key    = "node-role"
#   #   value  = "osdu-istio-keycloak"
#   #   effect = "NO_SCHEDULE"
#   # }

#   tags = merge(
#     {
#       Name = "osdu-ir-istio-worker-node"
#       "kubernetes.io/cluster/${aws_eks_cluster.eks.name}" = "owned"
#     },
#     var.map_tagging
#   )

#   # Ensure Calico is installed before creating nodes
#   depends_on = [
#     aws_eks_cluster.eks,
#     helm_release.calico,
#     aws_launch_template.calico_istio_template
#   ]
# }

# # Creation of the EC2 instance for hosting MinIO + PostgreSQL + Elasticsearch + RabbitMQ
# resource "aws_eks_node_group" "osdu_ir_backend_node" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "pw-eks-backend-nodes-${var.env}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   # Use launch template for Calico optimization
#   launch_template {
#     name    = aws_launch_template.calico_backend_template.name
#     version = aws_launch_template.calico_backend_template.latest_version
#   }

#   # Note: When using launch_template, these are defined in the template
#   # instance_types = ["m5.xlarge"]
#   # disk_size = 80
#   # ami_type      = "AL2_x86_64"
  
#   capacity_type = "ON_DEMAND"

#   # Add labels for node scheduling + Calico support
#   labels = {
#     "node-role"         = "osdu-backend"
#     "workload-type"     = "database"
#     "component"         = "backend-services"
#     "storage-optimized" = "true"
    
#     # Required for Calico CNI
#     "kubernetes.io/os"                                = "linux"
#     "projectcalico.org/operator-node-migration"       = "migrated"
#   }

#   # # Add taints for backend workloads
#   # taint {
#   #   key    = "node-role"
#   #   value  = "osdu-backend"
#   #   effect = "NO_SCHEDULE"
#   # }

#   tags = merge(
#     {
#       Name = "osdu-ir-backend-worker-node"
#       "kubernetes.io/cluster/${aws_eks_cluster.eks.name}" = "owned"
#     },
#     var.map_tagging
#   )

#   # Ensure Calico is installed before creating nodes
#   depends_on = [
#     aws_eks_cluster.eks,
#     helm_release.calico,
#     aws_launch_template.calico_backend_template
#   ]
# }

# # ✅ OPTIMIZED: Creation of the EC2 instance for hosting OSDU Microservices + Airflow + Redis (UNTAINTED)
# resource "aws_eks_node_group" "osdu_ir_frontend_node" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "pw-eks-frontend-node-${var.env}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   # Use launch template for Calico optimization
#   launch_template {
#     name    = aws_launch_template.calico_frontend_template.name
#     version = aws_launch_template.calico_frontend_template.latest_version
#   }

#   # Note: When using launch_template, these are defined in the template
#   # instance_types = ["m5.xlarge"]
#   # disk_size = 80
#   # ami_type      = "AL2_x86_64"
  
#   capacity_type = "ON_DEMAND"

#   # Add labels for node scheduling + Calico support
#   labels = {
#     "node-role"         = "osdu-frontend"
#     "workload-type"     = "microservices"
#     "component"         = "osdu-apis"
#     "compute-optimized" = "true"
    
#     # Required for Calico CNI
#     "kubernetes.io/os"                                = "linux"
#     "projectcalico.org/operator-node-migration"       = "migrated"
#   }

#   # ✅ OPTIMIZED: No taints on frontend nodes - allows flexible scheduling for all OSDU microservices
#   # This ensures OSDU microservices can schedule here without needing specific tolerations

#   tags = merge(
#     {
#       Name = "osdu-ir-frontend-worker-node"
#       "kubernetes.io/cluster/${aws_eks_cluster.eks.name}" = "owned"
#     },
#     var.map_tagging
#   )

#   # Ensure Calico is installed before creating nodes
#   depends_on = [
#     aws_eks_cluster.eks,
#     helm_release.calico,
#     aws_launch_template.calico_frontend_template
#   ]
# }

# ########################################################################################################################################################################
# ########################################################### NODE GROUP LAUNCH TEMPLATES ##############################################################################
# ########################################################################################################################################################################

# # Data source for the latest EKS-optimized AMI
# data "aws_ssm_parameter" "eks_ami_release_version" {
#   name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks.version}/amazon-linux-2/recommended/release_version"
# }

# # Launch template for Istio nodes
# resource "aws_launch_template" "calico_istio_template" {
#   name_prefix   = "calico-istio-${var.env}-"
#   image_id      = data.aws_ssm_parameter.eks_ami_release_version.value
#   instance_type = "m5.xlarge"

#   vpc_security_group_ids = "sg-0fb75ddafc87b1356"

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = 80
#       volume_type = "gp3"
#       iops        = 3000
#       throughput  = 125
#       encrypted   = true
#       delete_on_termination = true
#     }
#   }

#   user_data = base64encode(templatefile("${path.module}/calico-node-userdata.sh", {
#     cluster_name        = aws_eks_cluster.eks.name
#     cluster_endpoint    = aws_eks_cluster.eks.endpoint
#     cluster_ca_data     = aws_eks_cluster.eks.certificate_authority[0].data
#     bootstrap_arguments = "--container-runtime containerd"
#     node_role          = "istio"
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(
#       {
#         Name = "calico-istio-node-${var.env}"
#         NodeRole = "istio"
#       },
#       var.map_tagging
#     )
#   }

#   tags = var.map_tagging
# }

# # Launch template for Backend nodes
# resource "aws_launch_template" "calico_backend_template" {
#   name_prefix   = "calico-backend-${var.env}-"
#   image_id      = data.aws_ssm_parameter.eks_ami_release_version.value
#   instance_type = "m5.xlarge"

#   vpc_security_group_ids = "sg-0fb75ddafc87b1356"

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = 80
#       volume_type = "gp3"
#       iops        = 3000
#       throughput  = 125
#       encrypted   = true
#       delete_on_termination = true
#     }
#   }

#   user_data = base64encode(templatefile("${path.module}/calico-node-userdata.sh", {
#     cluster_name        = aws_eks_cluster.eks.name
#     cluster_endpoint    = aws_eks_cluster.eks.endpoint
#     cluster_ca_data     = aws_eks_cluster.eks.certificate_authority[0].data
#     bootstrap_arguments = "--container-runtime containerd"
#     node_role          = "backend"
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(
#       {
#         Name = "calico-backend-node-${var.env}"
#         NodeRole = "backend"
#       },
#       var.map_tagging
#     )
#   }

#   tags = var.map_tagging
# }

# # Launch template for Frontend nodes
# resource "aws_launch_template" "calico_frontend_template" {
#   name_prefix   = "calico-frontend-${var.env}-"
#   image_id      = data.aws_ssm_parameter.eks_ami_release_version.value
#   instance_type = "m5.xlarge"

#   vpc_security_group_ids = "sg-0fb75ddafc87b1356"

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = 80
#       volume_type = "gp3"
#       iops        = 3000
#       throughput  = 125
#       encrypted   = true
#       delete_on_termination = true
#     }
#   }

#   user_data = base64encode(templatefile("${path.module}/calico-node-userdata.sh", {
#     cluster_name        = aws_eks_cluster.eks.name
#     cluster_endpoint    = aws_eks_cluster.eks.endpoint
#     cluster_ca_data     = aws_eks_cluster.eks.certificate_authority[0].data
#     bootstrap_arguments = "--container-runtime containerd"
#     node_role          = "frontend"
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(
#       {
#         Name = "calico-frontend-node-${var.env}"
#         NodeRole = "frontend"
#       },
#       var.map_tagging
#     )
#   }

#   tags = var.map_tagging
# }































########################################################################################################################################################################
########################################################### OUTPUT VARIABLES ##########################################################################################
########################################################################################################################################################################

# Output the node group information
output "node_groups" {
  description = "EKS node group information"
  value = {
    istio_node_group = {
      name         = aws_eks_node_group.osdu_ir_istio_node.node_group_name
      arn          = aws_eks_node_group.osdu_ir_istio_node.arn
      capacity     = aws_eks_node_group.osdu_ir_istio_node.scaling_config[0]
      instance_types = aws_eks_node_group.osdu_ir_istio_node.instance_types
    }
    backend_node_group = {
      name         = aws_eks_node_group.osdu_ir_backend_node.node_group_name
      arn          = aws_eks_node_group.osdu_ir_backend_node.arn
      capacity     = aws_eks_node_group.osdu_ir_backend_node.scaling_config[0]
      instance_types = aws_eks_node_group.osdu_ir_backend_node.instance_types
    }
    frontend_node_group = {
      name         = aws_eks_node_group.osdu_ir_frontend_node.node_group_name
      arn          = aws_eks_node_group.osdu_ir_frontend_node.arn
      capacity     = aws_eks_node_group.osdu_ir_frontend_node.scaling_config[0]
      instance_types = aws_eks_node_group.osdu_ir_frontend_node.instance_types
    }
  }
}

# Output total cluster capacity
output "cluster_capacity" {
  description = "Total cluster capacity and IP usage"
  value = {
    total_nodes = 3
    total_vpc_ips_used = 3
    available_vpc_ips = 17  # Assuming 20 total VPC IPs
    overlay_network_range = "172.16.0.0/16"
    max_pods_per_cluster = "unlimited (overlay network)"
  }
}










###########################################################################################################################################################























# # ✅ OPTIMIZED: Updated labeling for Frontend nodes (NO TAINTS APPLIED)
# resource "null_resource" "label_and_taint_frontend_nodes" {
#   depends_on = [
#     aws_eks_node_group.osdu_ir_frontend_node
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       #!/bin/bash
#       set -e
      
#       echo "Updating kubeconfig..."
#       aws eks update-kubeconfig --region us-east-1 --name osdu-ir-eks-cluster
      
#       echo "Getting frontend nodes..."
#       nodes=$(kubectl get nodes -l eks.amazonaws.com/nodegroup=osdu-ir-frontend-worker-node -o jsonpath="{.items[*].metadata.name}")
      
#       if [ -n "$nodes" ]; then
#         for node in $nodes; do
#           echo "Labeling node (NO TAINTS): $node"
#           # kubectl label node $node node-role=osdu-frontend --overwrite
#           # ✅ OPTIMIZED: Removing any existing taints to ensure untainted state
#           # kubectl taint node $node node-role=osdu-frontend:NoSchedule- || true
#         done
#         echo "Frontend nodes labeled successfully (untainted for flexible scheduling)"
#       else
#         echo "No frontend nodes found"
#       fi
#     EOT
    
#     interpreter = ["/bin/bash", "-c"]
#   }
# }

# # Linux-compatible labeling for Istio nodes (backup/verification)
# resource "null_resource" "label_and_taint_istio_keycloak_nodes" {
#   depends_on = [
#     aws_eks_node_group.osdu_ir_istio_node
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       #!/bin/bash
#       set -e
      
#       echo "Updating kubeconfig..."
#       aws eks update-kubeconfig --region us-east-1 --name osdu-ir-eks-cluster
      
#       echo "Getting Istio nodes..."
#       nodes=$(kubectl get nodes -l eks.amazonaws.com/nodegroup=osdu-ir-istio-worker-node -o jsonpath="{.items[*].metadata.name}")
      
#       if [ -n "$nodes" ]; then
#         for node in $nodes; do
#           echo "Labeling and tainting node: $node"
#           kubectl label node $node node-role=osdu-istio-keycloak --overwrite
#           kubectl taint node $node node-role=osdu-istio-keycloak:NoSchedule --overwrite || true
#         done
#         echo "Istio nodes labeled and tainted successfully"
#       else
#         echo "No Istio nodes found"
#       fi
#     EOT
    
#     interpreter = ["/bin/bash", "-c"]
#   }
# }

# # Linux-compatible labeling for Backend nodes (backup/verification)
# resource "null_resource" "label_and_taint_backend_nodes" {
#   depends_on = [
#     aws_eks_node_group.osdu_ir_backend_node
#   ]

#   provisioner "local-exec" {
#     command = <<-EOT
#       #!/bin/bash
#       set -e
      
#       echo "Updating kubeconfig..."
#       aws eks update-kubeconfig --region us-east-1 --name osdu-ir-eks-cluster
      
#       echo "Getting backend nodes..."
#       nodes=$(kubectl get nodes -l eks.amazonaws.com/nodegroup=osdu-ir-backend-worker-node -o jsonpath="{.items[*].metadata.name}")
      
#       if [ -n "$nodes" ]; then
#         for node in $nodes; do
#           echo "Labeling and tainting node: $node"
#           kubectl label node $node node-role=osdu-backend --overwrite
#           kubectl taint node $node node-role=osdu-backend:NoSchedule --overwrite || true
#         done
#         echo "Backend nodes labeled and tainted successfully"
#       else
#         echo "No backend nodes found"
#       fi
#     EOT
    
#     interpreter = ["/bin/bash", "-c"]
#   }
# }





















# #########################################################################
# # SHARED RESOURCES - AMI AND BASE CONFIGURATIONS
# #########################################################################

# # Amazon EKS-optimized AMI (shared across all node groups)
# data "aws_ami" "eks-worker-amis" {
#   # Try the current Ubuntu EKS AMI naming pattern first
#   filter {
#     name   = "name"
#     values = ["ubuntu-eks/k8s_${var.eks_version}/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   most_recent = true
#   owners      = ["099710109477"] # Canonical's Account ID for Ubuntu AMIs
# }
# #########################################################################
# # NODE GROUP 1: ISTIO + KEYCLOAK NODES (TAINTED)
# #########################################################################

# resource "aws_launch_template" "eks-istio-node" {
#   name = "${var.project_name}-eks-istio-nodes-${var.env}"

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     # instance_metadata_tags      = "disabled"
#     instance_metadata_tags      = "enabled"
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     delete_on_termination       = true
#   }

#   monitoring {
#     enabled = true
#   }

#   image_id      = data.aws_ami.eks-worker-amis.id
#   instance_type = "m5.xlarge"  # Hardcoded value

#   user_data = base64encode(local.base-node-userdata)

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       delete_on_termination = true
#       encrypted             = true
#       volume_size           = 100  # Hardcoded value
#       volume_type           = "gp3"
#       # iops                  = 3000
#       # throughput            = 115
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-eks-istio-nodes-${var.env}"
#   }

#   tag_specifications {
#     resource_type = "instance"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-istio-node-${var.env}" },
#       var.map_tagging
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-istio-node-volume-${var.env}" },
#       var.map_tagging
#     )
#   }
# }

# resource "aws_eks_node_group" "istio-node-grp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-eks-istio-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

#   scaling_config {
#     desired_size = 1  # Hardcoded value
#     max_size     = 1  # Hardcoded value
#     min_size     = 1  # Hardcoded value
#   }

#   update_config {
#     max_unavailable = 1  # Hardcoded value
#   }

#   ami_type             = "CUSTOM"
#   capacity_type         = "ON_DEMAND"
#   force_update_version = true

#   launch_template {
#     version = aws_launch_template.eks-istio-node.latest_version
#     name    = aws_launch_template.eks-istio-node.name
#   }

#   # Node labels for Istio workloads
#   labels = {
#     "node-role"        = "osdu-istio-keycloak"
#     "workload-type"    = "istio"
#     "component"        = "service-mesh"
#     "istio-injection"     = "enabled"
#   }

#   # # Taint for Istio nodes
#   # taint {
#   #   key    = "node-role"
#   #   value  = "osdu-istio-keycloak"
#   #   effect = "NO_SCHEDULE"
#   # }

#   tags = merge(
#     { "Name" = "${var.project_name}-istio-node-group-${var.env}" },
#     var.map_tagging
#   )

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [node_group_name]
#   }

#   depends_on = [aws_eks_cluster.eks]
# }

# #########################################################################
# # NODE GROUP 1: BACKEND DATABASE NODES (TAINTED)
# #########################################################################

# resource "aws_launch_template" "eks-backend-node" {
#   name = "${var.project_name}-eks-backend-nodes-${var.env}"

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     # instance_metadata_tags      = "disabled"
#     instance_metadata_tags      = "enabled"
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     delete_on_termination       = true
#   }

#   monitoring {
#     enabled = true
#   }

#   image_id      = data.aws_ami.eks-worker-amis.id
#   instance_type = "m5.xlarge"  # Hardcoded value

#   user_data = base64encode(local.base-node-userdata)

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       delete_on_termination = true
#       encrypted             = true
#       volume_size           = 100 # Hardcoded value
#       volume_type           = "gp3"
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-eks-backend-nodes-${var.env}"
#   }

#   tag_specifications {
#     resource_type = "instance"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-backend-node-${var.env}" },
#       var.map_tagging
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-backend-node-volume-${var.env}" },
#       var.map_tagging
#     )
#   }
# }

# resource "aws_eks_node_group" "backend-node-grp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-eks-backend-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

#   scaling_config {
#     desired_size = 1  # Hardcoded value
#     max_size     = 1  # Hardcoded value
#     min_size     = 1  # Hardcoded value
#   }

#   update_config {
#     max_unavailable = 1  # Hardcoded value
#   }

#   ami_type             = "CUSTOM"
#   force_update_version = true

#   launch_template {
#     version = aws_launch_template.eks-backend-node.latest_version
#     name    = aws_launch_template.eks-backend-node.name
#   }

#   # Node labels for backend workloads
#   labels = {
#     "node-role"        = "osdu-backend"
#     "workload-type"    = "database"
#     "component"        = "backend-services"
#   }

#   # Taint for backend nodes
#   # taint {
#   #   key    = "node-role"
#   #   value  = "osdu-backend"
#   #   effect = "NO_SCHEDULE"
#   # }

#   tags = merge(
#     { "Name" = "${var.project_name}-backend-node-group-${var.env}" },
#     var.map_tagging
#   )

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [node_group_name]
#   }
# }

# #########################################################################
# # NODE GROUP 3: FRONTEND NODES (NO TAINTS)
# #########################################################################

# resource "aws_launch_template" "eks-frontend-node" {
#   name = "${var.project_name}-eks-frontend-nodes-${var.env}"

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     instance_metadata_tags      = "enabled"
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     delete_on_termination       = true
#   }

#   monitoring {
#     enabled = true
#   }

#   image_id      = data.aws_ami.eks-worker-amis.id
#   instance_type = "m5.xlarge"  # Hardcoded value

#   user_data = base64encode(local.base-node-userdata)

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       delete_on_termination = true
#       encrypted             = true
#       volume_size           = 100  # Hardcoded value
#       volume_type           = "gp3"
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-eks-frontend-nodes-${var.env}"
#   }

#   tag_specifications {
#     resource_type = "instance"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-frontend-node-${var.env}" },
#       var.map_tagging
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-frontend-node-volume-${var.env}" },
#       var.map_tagging
#     )
#   }
# }

# resource "aws_eks_node_group" "frontend-node-grp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-eks-frontend-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

#   scaling_config {
#     desired_size = 1 # Hardcoded value
#     max_size     = 1  # Hardcoded value
#     min_size     = 1  # Hardcoded value
#   }

#   update_config {
#     max_unavailable = 1  # Hardcoded value
#   }

#   ami_type             = "CUSTOM"
#   force_update_version = true

#   launch_template {
#     version = aws_launch_template.eks-frontend-node.latest_version
#     name    = aws_launch_template.eks-frontend-node.name
#   }

#   # Node labels for frontend workloads
#   labels = {
#     "node-role"        = "osdu-frontend"
#     "workload-type"    = "microservices"
#     "component"        = "osdu-apis"
#   }

#   # NO TAINTS - Allow any pods to schedule here

#   tags = merge(
#     { "Name" = "${var.project_name}-frontend-node-group-${var.env}" },
#     var.map_tagging
#   )

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [node_group_name]
#   }
# }

# #########################################################################
# # USER DATA CONFIGURATIONS
# #########################################################################

# locals {
#   # Base user data for all nodes
#   base-node-userdata = <<-EOT
# #!/bin/bash
# set -o xtrace

# # EKS bootstrap
# /etc/eks/bootstrap.sh ${aws_eks_cluster.eks.name} \
#   --b64-cluster-ca '${aws_eks_cluster.eks.certificate_authority[0].data}' \
#   --api-server-endpoint '${aws_eks_cluster.eks.endpoint}' \
#   --container-runtime containerd
# EOT


# }






















# #########################################################################
# # SHARED RESOURCES - AMI AND BASE CONFIGURATIONS
# #########################################################################

# # Amazon EKS-optimized AMI (shared across all node groups)
# data "aws_ami" "eks-worker-amis" {
#   filter {
#     name   = "name"
#     values = ["ubuntu-eks/k8s_${var.eks_version}/images/hvm-ssd/ubuntu-jammy-11.04-amd64-server-*"]
#   }

#   most_recent = true
#   owners      = ["099710109477"] # Canonical's Account ID for Ubuntu AMIs
# }

# #########################################################################
# # NODE GROUP 1: ISTIO + KEYCLOAK NODES (TAINTED)
# #########################################################################

# resource "aws_launch_template" "eks-istio-node" {
#   name = "${var.project_name}-eks-istio-nodes-${var.env}"

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     instance_metadata_tags      = "enabled"
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     delete_on_termination       = true
#   }

#   monitoring {
#     enabled = true
#   }

#   image_id      = data.aws_ami.eks-worker-amis.id
#   instance_type = "m5.xlarge"  # Hardcoded value

#   user_data = base64encode(local.base-node-userdata)

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       delete_on_termination = true
#       encrypted             = true
#       volume_size           = 110  # ✅ CHANGED: From 80GB to 110GB
#       volume_type           = "gp3"
#       iops                  = 3000      # ✅ ADDED: Better performance
#       throughput            = 115       # ✅ ADDED: Better throughput
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-eks-istio-nodes-${var.env}"
#   }

#   tag_specifications {
#     resource_type = "instance"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-istio-node-${var.env}" },
#       var.map_tagging
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-istio-node-volume-${var.env}" },
#       var.map_tagging
#     )
#   }
# }

# resource "aws_eks_node_group" "istio-node-grp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-eks-istio-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

#   scaling_config {
#     desired_size = 1  # ✅ CHANGED: From 1 to 1 nodes for HA
#     max_size     = 3  # ✅ CHANGED: From 1 to 3 for scaling
#     min_size     = 1  # Hardcoded value
#   }

#   update_config {
#     max_unavailable = 1  # Hardcoded value
#   }

#   ami_type             = "CUSTOM"
#   capacity_type        = "ON_DEMAND"
#   force_update_version = true

#   launch_template {
#     version = aws_launch_template.eks-istio-node.latest_version
#     name    = aws_launch_template.eks-istio-node.name
#   }

#   # Node labels for Istio workloads
#   labels = {
#     "node-role"           = "osdu-istio-keycloak"
#     "workload-type"       = "istio"
#     "component"           = "service-mesh"
#     "istio-injection"     = "enabled"
#   }

#   # Taint for Istio nodes
#   taint {
#     key    = "node-role"
#     value  = "osdu-istio-keycloak"
#     effect = "NO_SCHEDULE"
#   }

#   tags = merge(
#     { "Name" = "${var.project_name}-istio-node-group-${var.env}" },
#     var.map_tagging
#   )

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [node_group_name]
#   }

#   depends_on = [aws_eks_cluster.eks]
# }

# #########################################################################
# # NODE GROUP 1: BACKEND DATABASE NODES (TAINTED)
# #########################################################################

# resource "aws_launch_template" "eks-backend-node" {
#   name = "${var.project_name}-eks-backend-nodes-${var.env}"

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     instance_metadata_tags      = "enabled"
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     delete_on_termination       = true
#   }

#   monitoring {
#     enabled = true
#   }

#   image_id      = data.aws_ami.eks-worker-amis.id
#   instance_type = "m5.1xlarge"  # ✅ CHANGED: From m5.xlarge to m5.1xlarge for databases

#   user_data = base64encode(local.base-node-userdata)

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       delete_on_termination = true
#       encrypted             = true
#       volume_size           = 100  # ✅ CHANGED: From 80GB to 100GB for databases
#       volume_type           = "gp3"
#       iops                  = 3000      # ✅ ADDED: Better performance for databases
#       throughput            = 115       # ✅ ADDED: Better throughput
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-eks-backend-nodes-${var.env}"
#   }

#   tag_specifications {
#     resource_type = "instance"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-backend-node-${var.env}" },
#       var.map_tagging
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-backend-node-volume-${var.env}" },
#       var.map_tagging
#     )
#   }
# }

# resource "aws_eks_node_group" "backend-node-grp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-eks-backend-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

#   scaling_config {
#     desired_size = 3  # ✅ CHANGED: From 1 to 3 nodes for better load distribution
#     max_size     = 5  # ✅ CHANGED: From 1 to 5 for scaling
#     min_size     = 1  # Hardcoded value
#   }

#   update_config {
#     max_unavailable = 1  # Hardcoded value
#   }

#   ami_type             = "CUSTOM"
#   force_update_version = true

#   launch_template {
#     version = aws_launch_template.eks-backend-node.latest_version
#     name    = aws_launch_template.eks-backend-node.name
#   }

#   # Node labels for backend workloads
#   labels = {
#     "node-role"        = "osdu-backend"
#     "workload-type"    = "database"
#     "component"        = "backend-services"
#   }

#   # ✅ ADDED: Taint for backend nodes (was commented out)
#   taint {
#     key    = "node-role"
#     value  = "osdu-backend"
#     effect = "NO_SCHEDULE"
#   }

#   tags = merge(
#     { "Name" = "${var.project_name}-backend-node-group-${var.env}" },
#     var.map_tagging
#   )

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [node_group_name]
#   }
# }

# #########################################################################
# # NODE GROUP 3: FRONTEND NODES (NO TAINTS)
# #########################################################################

# resource "aws_launch_template" "eks-frontend-node" {
#   name = "${var.project_name}-eks-frontend-nodes-${var.env}"

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     instance_metadata_tags      = "enabled"
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     delete_on_termination       = true
#   }

#   monitoring {
#     enabled = true
#   }

#   image_id      = data.aws_ami.eks-worker-amis.id
#   instance_type = "m5.xlarge"  # Hardcoded value

#   user_data = base64encode(local.base-node-userdata)

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       delete_on_termination = true
#       encrypted             = true
#       volume_size           = 110  # ✅ CHANGED: From 100GB to 110GB
#       volume_type           = "gp3"
#       iops                  = 3000      # ✅ ADDED: Better performance
#       throughput            = 115       # ✅ ADDED: Better throughput
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-eks-frontend-nodes-${var.env}"
#   }

#   tag_specifications {
#     resource_type = "instance"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-frontend-node-${var.env}" },
#       var.map_tagging
#     )
#   }

#   tag_specifications {
#     resource_type = "volume"
    
#     tags = merge(
#       { "Name" = "${var.project_name}-eks-frontend-node-volume-${var.env}" },
#       var.map_tagging
#     )
#   }
# }

# resource "aws_eks_node_group" "frontend-node-grp" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "${var.project_name}-eks-frontend-node-group-${var.env}-${formatdate("DD-MM-YYYY-hh-mm", timestamp())}"
#   node_role_arn   = var.worker_role_arn
#   subnet_ids      = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az1.id]

#   scaling_config {
#     desired_size = 3  # ✅ CHANGED: From 1 to 3 nodes for better distribution
#     max_size     = 10 # ✅ CHANGED: From 1 to 10 for high scaling
#     min_size     = 1  # Hardcoded value
#   }

#   update_config {
#     max_unavailable = 1  # Hardcoded value
#   }

#   ami_type             = "CUSTOM"
#   force_update_version = true

#   launch_template {
#     version = aws_launch_template.eks-frontend-node.latest_version
#     name    = aws_launch_template.eks-frontend-node.name
#   }

#   # Node labels for frontend workloads
#   labels = {
#     "node-role"        = "osdu-frontend"
#     "workload-type"    = "microservices"
#     "component"        = "osdu-apis"
#   }

#   # NO TAINTS - Allow any pods to schedule here

#   tags = merge(
#     { "Name" = "${var.project_name}-frontend-node-group-${var.env}" },
#     var.map_tagging
#   )

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [node_group_name]
#   }
# }

# #########################################################################
# # USER DATA CONFIGURATIONS
# #########################################################################

# locals {
#   # Base user data for all nodes
#   base-node-userdata = <<-EOT
# #!/bin/bash
# set -o xtrace

# # EKS bootstrap
# /etc/eks/bootstrap.sh ${aws_eks_cluster.eks.name} \
#   --b64-cluster-ca '${aws_eks_cluster.eks.certificate_authority[0].data}' \
#   --api-server-endpoint '${aws_eks_cluster.eks.endpoint}' \
#   --container-runtime containerd
# EOT


# }