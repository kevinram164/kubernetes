# ------------------------------------------------------------------------------
# Biến GKE
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "GCP Project ID (bắt buộc)"
  type        = string
}

variable "region" {
  description = "Region GCP (ví dụ asia-southeast1)"
  type        = string
  default     = "asia-southeast1"
}

variable "cluster_name" {
  description = "Tên GKE cluster"
  type        = string
  default     = "my-gke"
}

variable "subnet_cidr" {
  description = "CIDR cho subnet chính (primary range)"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_secondary_cidr" {
  description = "CIDR secondary cho Pod (phải không trùng subnet chính và services)"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_secondary_cidr" {
  description = "CIDR secondary cho Service (ClusterIP)"
  type        = string
  default     = "10.8.0.0/20"
}

variable "node_machine_type" {
  description = "Loại VM cho node (ví dụ e2-medium)"
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size_gb" {
  description = "Dung lượng disk mỗi node (GB)"
  type        = number
  default     = 50
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
