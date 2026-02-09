# ------------------------------------------------------------------------------
# Output AKS
# ------------------------------------------------------------------------------

output "resource_group_name" {
  description = "Tên Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "cluster_name" {
  description = "Tên AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_endpoint" {
  description = "Endpoint API server"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Lệnh cập nhật kubeconfig"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
