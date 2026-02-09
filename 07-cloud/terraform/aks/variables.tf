# ------------------------------------------------------------------------------
# Biến AKS
# ------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Tên Resource Group Azure"
  type        = string
  default     = "rg-aks-demo"
}

variable "location" {
  description = "Region Azure (ví dụ southeastasia)"
  type        = string
  default     = "southeastasia"
}

variable "cluster_name" {
  description = "Tên AKS cluster"
  type        = string
  default     = "my-aks"
}

variable "kubernetes_version" {
  description = "Phiên bản Kubernetes"
  type        = string
  default     = "1.28"
}

variable "vnet_address_space" {
  description = "CIDR cho VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR cho subnet AKS"
  type        = string
  default     = "10.0.1.0/24"
}

variable "node_vm_size" {
  description = "Loại VM cho node (ví dụ Standard_D2s_v3)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_count" {
  description = "Số node ban đầu (khi autoscaling: dùng làm initial)"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Số node tối thiểu (autoscaling)"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Số node tối đa (autoscaling)"
  type        = number
  default     = 3
}
