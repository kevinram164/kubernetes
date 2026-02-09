# ------------------------------------------------------------------------------
# Output GKE
# ------------------------------------------------------------------------------

output "cluster_name" {
  description = "Tên GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint API server"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "region" {
  description = "Region"
  value       = var.region
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "kubeconfig_command" {
  description = "Lệnh cập nhật kubeconfig"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
