output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority" {
  description = "EKS cluster certificate authority"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "node_group_config" {
  description = "EKS node group configuration values"
  value       = module.eks.eks_managed_node_groups
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "update_kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = aws_iam_role.ebs_csi_role.arn
}

output "node_specs" {
  description = "Node group specifications"
  value = {
    instance_type  = "c6i.large"
    disk_size_gb   = 50
    disk_type      = "gp3"
    disk_iops      = 3000
    disk_throughput = "125 MB/s"
    min_nodes      = 2
    desired_nodes  = 3
    max_nodes      = 5
    cpu_per_node   = "2 vCPU"
    memory_per_node = "4 GB"
  }
}

output "cluster_deployment_info" {
  description = "Complete deployment information for the cluster"
  value = {
    cluster_name    = module.eks.cluster_name
    region          = var.aws_region
    kubernetes_version = module.eks.cluster_version
    node_group_name = "sock-shop-node-group"
    environment     = var.environment
    storage_type    = "EBS gp3"
    storage_config  = "See kubernetes/storage/ for PVC and StorageClass definitions"
  }
}
