# ------------------------------------------------------------------------------
# Biến EKS
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "Region AWS (ví dụ ap-southeast-1)"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "Tên EKS cluster"
  type        = string
  default     = "my-eks"
}

variable "kubernetes_version" {
  description = "Phiên bản Kubernetes"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR cho private subnet (3 subnet, mỗi AZ một cái)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR cho public subnet"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "node_instance_types" {
  description = "Loại EC2 cho node (ví dụ t3.medium)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Số node tối thiểu (autoscaling)"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Số node tối đa (autoscaling)"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Số node mong muốn lúc đầu"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tag chung cho resource"
  type        = map(string)
  default     = {}
}
