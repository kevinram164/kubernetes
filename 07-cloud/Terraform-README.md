# Triển khai EKS, GKE, AKS bằng Terraform

Hướng dẫn **chi tiết** tạo cluster Kubernetes trên cloud (EKS, GKE, AKS) bằng **Terraform**: giải thích từng bước, provider, resource và cách chạy.

---

## 1. Chuẩn bị

### 1.1 Cài đặt

| Công cụ | Mục đích |
|---------|----------|
| **Terraform** | >= 1.0. Cài: [terraform.io/downloads](https://www.terraform.io/downloads) hoặc `choco install terraform` (Windows). |
| **Cloud CLI** | `aws`, `gcloud`, `az` – xác thực và (tùy chọn) lấy thông tin project/region. |
| **kubectl** | Kết nối cluster sau khi tạo. |

### 1.2 Xác thực cloud

- **AWS:** `aws configure` (Access Key, Secret Key, region) hoặc biến môi trường `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`.
- **GCP:** `gcloud auth application-default login` (hoặc service account key); set project: `gcloud config set project PROJECT_ID`.
- **Azure:** `az login`; set subscription: `az account set --subscription "Subscription Name"`.

### 1.3 Cấu trúc thư mục Terraform trong repo

```
07-cloud/terraform/
├── README.md           # File này (tổng quan)
├── eks/                # EKS
│   ├── README.md       # Hướng dẫn từng bước EKS
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── gke/                # GKE
│   ├── README.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── aks/                # AKS
    ├── README.md
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars.example
```

Mỗi thư mục (`eks/`, `gke/`, `aks/`) **độc lập**: chạy `terraform init` và `terraform apply` trong từng thư mục.

---

## 2. Thứ tự làm

1. Chọn **một** cloud (EKS / GKE / AKS).
2. Đọc **README.md** trong thư mục tương ứng (giải thích từng resource).
3. Copy `terraform.tfvars.example` → `terraform.tfvars`, chỉnh project/region/cluster name.
4. Chạy `terraform init` → `terraform plan` → `terraform apply`.
5. Lấy kubeconfig (output hướng dẫn) và `kubectl get nodes`.

---

## 3. Lưu ý chung

- **State:** Terraform lưu state (file `terraform.tfstate`). Dùng **remote state** (S3, GCS, Azure Storage) khi làm việc nhóm hoặc CI/CD.
- **Secret:** Không commit `terraform.tfvars` nếu chứa secret; dùng biến môi trường hoặc secret manager.
- **Chi phí:** Cluster và node tốn tiền; nhớ `terraform destroy` khi không dùng.

Chi tiết từng cloud (giải thích từng resource, biến, bước chạy):

| Cloud | Thư mục | README |
|-------|---------|--------|
| **EKS** | [terraform/eks/](terraform/eks/) | [README.md](terraform/eks/README.md) – VPC (module), EKS cluster + node group (module), kubeconfig |
| **GKE** | [terraform/gke/](terraform/gke/) | [README.md](terraform/gke/README.md) – Bật API, VPC + subnet (secondary range Pod/Service), GKE cluster + node pool |
| **AKS** | [terraform/aks/](terraform/aks/) | [README.md](terraform/aks/README.md) – Resource Group, VNet, subnet, AKS cluster + default node pool |
