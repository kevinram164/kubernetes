# ------------------------------------------------------------------------------
# Output EKS – dùng cho kubeconfig và script
# ------------------------------------------------------------------------------

output "cluster_name" {
  description = "Tên EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint API server"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA cert (dùng trong kubeconfig)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "aws_region" {
  description = "Region AWS"
  value       = var.aws_region
}

output "kubeconfig_command" {
  description = "Lệnh cập nhật kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
