# EKS với Terraform – Hướng dẫn chi tiết

Tạo **Amazon EKS (Elastic Kubernetes Service)** bằng Terraform: VPC (tùy chọn), cluster, node group, và cấu hình kubeconfig.

---

## 1. Tổng quan kiến trúc

- **EKS cluster**: Control plane do AWS quản lý (API server, etcd); chạy trong VPC của bạn (subnet private/public tùy cấu hình).
- **Node group**: Nhóm EC2 (worker node); Terraform tạo **eks_node_group** gắn với cluster.
- **VPC**: Có thể dùng VPC có sẵn hoặc tạo mới (subnet public/private cho EKS). EKS yêu cầu subnet có tag đặc biệt để load balancer và pod network hoạt động.

Trong ví dụ này ta dùng **module VPC có sẵn** (terraform-aws-modules/vpc/aws) và **module EKS** (terraform-aws-modules/eks/aws) để giảm boilerplate và đúng best practice.

---

## 2. Giải thích từng file Terraform

### 2.1 Provider (main.tf)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}
```

- **required_providers**: Terraform tải provider `aws` (hashicorp/aws) phiên bản ~> 5.0.
- **provider "aws"**: Cấu hình provider; `region` lấy từ biến `var.aws_region`. Credential AWS lấy từ môi trường (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) hoặc `aws configure`.

### 2.2 Data source: Availability Zones (main.tf)

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

- Lấy danh sách **Availability Zone** (AZ) trong region (ví dụ ap-southeast-1a, ap-southeast-1b). Dùng để tạo subnet trải nhiều AZ (high availability).

### 2.3 VPC (module)

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name             = "${var.cluster_name}-vpc"
  cidr             = var.vpc_cidr
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = var.private_subnet_cidrs
  public_subnets   = var.public_subnet_cidrs
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  tags = var.tags
}
```

- **terraform-aws-modules/vpc/aws**: Module tạo VPC, subnet, Internet Gateway, NAT Gateway. Dùng module giúp cấu hình subnet tag đúng cho EKS (elb, internal-elb).
- **cidr**: Dải IP VPC (ví dụ 10.0.0.0/16).
- **azs**: Chọn 3 AZ đầu tiên (slice) để tạo subnet.
- **private_subnets / public_subnets**: Dải CIDR cho từng subnet; EKS node thường đặt trong **private subnet**, load balancer có thể ở public.
- **enable_nat_gateway**: Node trong private subnet cần NAT để ra internet (pull image, gọi API).
- **single_nat_gateway = true**: Tiết kiệm chi phí (1 NAT); production có thể dùng nhiều NAT (1 per AZ).
- **public_subnet_tags / private_subnet_tags**: Tag bắt buộc để EKS và AWS Load Balancer Controller biết subnet dùng cho elb/internal-elb.

### 2.4 EKS cluster (module)

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    main = {
      name           = "main"
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }

  tags = var.tags
}
```

- **terraform-aws-modules/eks/aws**: Module tạo EKS cluster + node group, IAM role, security group.
- **cluster_name, cluster_version**: Tên cluster và phiên bản Kubernetes (ví dụ 1.28).
- **vpc_id, subnet_ids**: Cluster và node chạy trong VPC/subnet đã tạo; dùng **private_subnets** để node không public IP (bảo mật hơn).
- **cluster_endpoint_public_access / private_access**: API server có endpoint public (truy cập từ internet) và/hoặc private (chỉ trong VPC). Development thường bật public; production có thể chỉ private.
- **eks_managed_node_groups**: Định nghĩa node group tên "main": instance type (ví dụ t3.medium), min/max/desired size (autoscaling). Module tự tạo launch template, IAM role cho node (EC2), security group.

### 2.5 Output (outputs.tf)

- **cluster_id, cluster_endpoint, cluster_certificate_authority_data**: Dùng để cấu hình **kubectl** (kubeconfig). Sau `terraform apply`, chạy:
  ```bash
  aws eks update-kubeconfig --region <region> --name <cluster_name>
  ```
  Hoặc dùng output: `terraform output -raw kubeconfig_command` (nếu có output gợi ý lệnh).

---

## 3. Biến (variables.tf)

| Biến | Ý nghĩa | Mặc định |
|------|--------|----------|
| **aws_region** | Region AWS (ví dụ ap-southeast-1) | ap-southeast-1 |
| **cluster_name** | Tên EKS cluster | my-eks |
| **kubernetes_version** | Phiên bản K8s | 1.28 |
| **vpc_cidr** | CIDR VPC | 10.0.0.0/16 |
| **private_subnet_cidrs / public_subnet_cidrs** | CIDR subnet | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 (private); 10.0.101.0/24, ... (public) |
| **node_instance_types** | Loại EC2 cho node | ["t3.medium"] |
| **node_min_size / max_size / desired_size** | Autoscaling node | 1, 3, 2 |

Copy `terraform.tfvars.example` → `terraform.tfvars` và chỉnh theo project của bạn.

---

## 4. Các bước chạy

### Bước 1: Clone / vào thư mục

```bash
cd 07-cloud/terraform/eks
```

### Bước 2: Tạo file biến

```bash
cp terraform.tfvars.example terraform.tfvars
# Chỉnh: aws_region, cluster_name, (tùy chọn) vpc_cidr, node instance_types
```

### Bước 3: Init (tải provider + module)

```bash
terraform init
```

- Terraform tải provider `aws` và module `vpc`, `eks` vào thư mục `.terraform/`.

### Bước 4: Plan (xem thay đổi)

```bash
terraform plan -out=tfplan
```

- In ra danh sách resource sẽ tạo (VPC, subnet, EKS cluster, node group, IAM role, ...). Đọc kỹ trước khi apply.

### Bước 5: Apply (tạo resource)

```bash
terraform apply tfplan
```

- Hoặc `terraform apply` (nhập yes khi hỏi). Thời gian tạo EKS thường 10–15 phút.

### Bước 6: Cấu hình kubectl

```bash
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw cluster_name)
kubectl get nodes
```

- Nếu output có `aws_region` và `cluster_name`. Hoặc thay bằng region và tên cluster bạn đặt trong tfvars.

### Bước 7: Destroy (khi không dùng)

```bash
terraform destroy
```

- Xóa cluster, node group, VPC. **Mất hết workload trong cluster.**

---

## 5. Lưu ý bảo mật và chi phí

- **IAM**: Node group dùng IAM role do module tạo (quyền EKS worker). Không cần lưu access key trên node.
- **Private subnet**: Node trong private subnet an toàn hơn; cần NAT để pull image. Nếu dùng public subnet (đơn giản hơn cho lab), có thể đổi `subnet_ids` sang `module.vpc.public_subnets`.
- **Chi phí**: VPC + NAT + EKS control plane + EC2 node. NAT Gateway tốn tiền; có thể dùng `single_nat_gateway = true` để giảm. Nhớ destroy khi không dùng.

Tài liệu: [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest), [AWS EKS](https://docs.aws.amazon.com/eks/).
