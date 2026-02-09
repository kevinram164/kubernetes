# GKE với Terraform – Hướng dẫn chi tiết

Tạo **Google Kubernetes Engine (GKE)** bằng Terraform: VPC (tùy chọn), cluster, node pool, và cấu hình kubeconfig.

---

## 1. Tổng quan kiến trúc

- **GKE cluster**: Control plane do Google quản lý; cluster chạy trong **VPC** (Google Cloud VPC) và **region/zone** bạn chọn.
- **Node pool**: Nhóm VM (worker node); Terraform tạo **google_container_node_pool** gắn với cluster.
- **VPC**: Có thể dùng VPC mặc định hoặc tạo VPC mới (subnet). GKE cần subnet với secondary range cho Pod và Service (alias IP).

Trong ví dụ này ta dùng **google_container_cluster** và **google_container_node_pool** (resource chuẩn) kèm **google_compute_network** / **google_compute_subnetwork** (VPC tùy chọn) để bạn hiểu rõ từng resource. Có thể thay bằng module [terraform-google-modules/kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest) nếu muốn gọn hơn.

---

## 2. Giải thích từng file Terraform

### 2.1 Provider (main.tf)

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

- **required_providers**: Tải provider **google** (hashicorp/google).
- **provider "google"**: Cấu hình project và region. Credential lấy từ `gcloud auth application-default login` hoặc biến `GOOGLE_APPLICATION_CREDENTIALS` (file JSON service account).

### 2.2 Bật API (main.tf)

```hcl
resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_dependent_services = true
}
```

- **google_project_service**: Bật **Kubernetes Engine API** (container.googleapis.com) cho project. Terraform sẽ chờ API bật xong rồi mới tạo cluster.
- **disable_dependent_services = true**: Khi destroy, cho phép tắt API (có thể ảnh hưởng resource khác trong project).

### 2.3 VPC và subnet (main.tf)

```hcl
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_secondary_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_secondary_cidr
  }
}
```

- **google_compute_network**: Tạo VPC; **auto_create_subnetworks = false** để tự tạo subnet (GKE cần secondary range trên subnet).
- **google_compute_subnetwork**: Subnet trong region; **secondary_ip_range** bắt buộc cho GKE: **pods** (dải IP cho Pod), **services** (dải IP cho Service ClusterIP). Tránh trùng với subnet chính và với nhau.

### 2.4 GKE cluster (main.tf)

```hcl
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  ...
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  ...
}
```

- **google_container_cluster**: Tạo GKE cluster.
- **name, location**: Tên cluster và **region** (regional cluster) hoặc **zone** (zonal cluster). Dùng region để HA (nhiều zone).
- **network, subnetwork**: VPC và subnet đã tạo; GKE dùng secondary range (pods, services) đã khai báo trên subnet.
- **ip_allocation_policy**: Cấu hình dùng secondary range cho cluster (không cần block nếu dùng subnet có secondary range; GKE tự dùng).
- **remove_default_node_pool = true**: Cluster tạo **không** kèm default node pool; ta tạo node pool riêng (resource **google_container_node_pool**) để cấu hình instance type, disk size.
- **initial_node_count**: Bắt buộc khi remove_default_node_pool; đặt 1 (sẽ xóa sau khi add node pool).

### 2.5 Node pool (main.tf)

```hcl
resource "google_container_node_pool" "main" {
  name       = "main"
  location   = google_container_cluster.primary.location
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
    min_node_count = var.node_min_count
    max_node_count = var.node_max_count
  }
}
```

- **google_container_node_pool**: Node pool gắn với cluster.
- **node_count**: Số node (khi không dùng autoscaling). Khi bật **autoscaling** thì **min_node_count / max_node_count** có hiệu lực; có thể bỏ node_count hoặc đặt = min.
- **node_config**: Loại VM (machine_type), dung lượng disk; **oauth_scopes** = cloud-platform để node gọi GCP API (pull image, logging, monitoring).
- **autoscaling**: Min/max node (cluster autoscaler).

### 2.6 Output và kubeconfig

- **output**: cluster name, endpoint, region. Cấu hình kubectl:
  ```bash
  gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>
  ```

---

## 3. Biến (variables.tf)

| Biến | Ý nghĩa | Mặc định |
|------|--------|----------|
| **project_id** | GCP Project ID (bắt buộc) | (không có) |
| **region** | Region (ví dụ asia-southeast1) | asia-southeast1 |
| **cluster_name** | Tên GKE cluster | my-gke |
| **subnet_cidr** | CIDR subnet chính | 10.0.0.0/20 |
| **pods_secondary_cidr** | Dải IP Pod (secondary) | 10.4.0.0/14 |
| **services_secondary_cidr** | Dải IP Service (secondary) | 10.8.0.0/20 |
| **node_machine_type** | Loại VM (ví dụ e2-medium) | e2-medium |
| **node_count / node_min_count / node_max_count** | Số node, autoscaling | 2; 1; 3 |

**Lưu ý:** **project_id** phải set (terraform.tfvars hoặc biến môi trường TF_VAR_project_id).

---

## 4. Các bước chạy

### Bước 1: Xác thực GCP

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### Bước 2: Tạo file biến

```bash
cp terraform.tfvars.example terraform.tfvars
# Chỉnh project_id, region, cluster_name
```

### Bước 3: Init, Plan, Apply

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Bước 4: Kubeconfig

```bash
gcloud container clusters get-credentials $(terraform output -raw cluster_name) --region $(terraform output -raw region) --project $(terraform output -raw project_id)
kubectl get nodes
```

### Bước 5: Destroy

```bash
terraform destroy
```

---

## 5. Lưu ý

- **Chi phí**: GKE control plane miễn phí (standard cluster); tính phí theo node (VM). Secondary range (pods, services) không tạo thêm VM.
- **Private cluster**: Có thể bật **private_cluster_config** (endpoint private, node không public IP); cần VPC peering / Cloud NAT để truy cập từ ngoài.
- Tài liệu: [GKE Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster), [GKE](https://cloud.google.com/kubernetes-engine/docs).
