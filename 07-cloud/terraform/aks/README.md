# AKS với Terraform – Hướng dẫn chi tiết

Tạo **Azure Kubernetes Service (AKS)** bằng Terraform: Resource Group, VNet (tùy chọn), AKS cluster, node pool, và cấu hình kubeconfig.

---

## 1. Tổng quan kiến trúc

- **AKS cluster**: Control plane do Azure quản lý; cluster chạy trong **Virtual Network (VNet)** và **resource group** bạn chọn.
- **Node pool**: Nhóm VM (worker node); Terraform tạo **default_node_pool** (trong azurerm_kubernetes_cluster) hoặc **azurerm_kubernetes_cluster_node_pool** riêng.
- **VNet**: Có thể dùng VNet có sẵn hoặc tạo mới (subnet). AKS cần subnet (có thể ủy quyền subnet cho AKS).

Trong ví dụ này ta dùng **azurerm_kubernetes_cluster** với **default_node_pool** và **azurerm_resource_group**, **azurerm_virtual_network**, **azurerm_subnet** (VNet riêng cho AKS) để rõ từng bước.

---

## 2. Giải thích từng file Terraform

### 2.1 Provider (main.tf)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}
```

- **required_providers**: Tải provider **azurerm** (Azure).
- **provider "azurerm"**: Cấu hình Azure; credential lấy từ `az login` (hoặc biến môi trường cho service principal). **subscription** có thể set trong provider hoặc biến môi trường.

### 2.2 Resource Group (main.tf)

```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
```

- **azurerm_resource_group**: Nhóm chứa mọi resource (VNet, AKS). **location** = region Azure (ví dụ Southeast Asia).

### 2.3 VNet và Subnet (main.tf)

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}
```

- **azurerm_virtual_network**: VNet với **address_space** (ví dụ 10.0.0.0/16).
- **azurerm_subnet**: Subnet cho AKS; **address_prefixes** (ví dụ 10.0.1.0/24). AKS sẽ đặt node và Pod trong subnet này (hoặc subnet do AKS tạo nếu dùng subnet ủy quyền).

### 2.4 AKS Cluster (main.tf)

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    vm_size             = var.node_vm_size
    node_count          = var.node_count
    vnet_subnet_id      = azurerm_subnet.aks.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = var.node_min_count
    max_count           = var.node_max_count
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}
```

- **azurerm_kubernetes_cluster**: Tạo AKS cluster.
- **name, location, resource_group_name**: Tên cluster, region, resource group.
- **dns_prefix**: Prefix cho FQDN API server (ví dụ my-aks-xxx.eastasia.azmk8s.io).
- **kubernetes_version**: Phiên bản K8s (ví dụ 1.28).
- **default_node_pool**: Node pool mặc định: **vm_size** (ví dụ Standard_D2s_v3), **node_count** (hoặc dùng **enable_auto_scaling** với min_count/max_count), **vnet_subnet_id** (subnet đã tạo). **type = VirtualMachineScaleSets** dùng VMSS (scale set). **enable_auto_scaling** = true thì **min_count / max_count** có hiệu lực; có thể bỏ node_count khi bật autoscaling.
- **identity**: **SystemAssigned** = Azure tạo Managed Identity cho cluster (dùng cho pull image, Azure Disk, …).
- **network_profile**: **network_plugin = "azure"** (Azure CNI; Pod dùng IP trong VNet). **load_balancer_sku = "standard"** cho Service type LoadBalancer.

### 2.5 Output và kubeconfig

- Sau **terraform apply**, lấy credential:
  ```bash
  az aks get-credentials --resource-group <rg> --name <cluster_name>
  ```
- Output: resource_group_name, cluster_name, kube_config (sensitive).

---

## 3. Biến (variables.tf)

| Biến | Ý nghĩa | Mặc định |
|------|--------|----------|
| **resource_group_name** | Tên Resource Group | rg-aks-demo |
| **location** | Region Azure (ví dụ southeastasia) | southeastasia |
| **cluster_name** | Tên AKS cluster | my-aks |
| **kubernetes_version** | Phiên bản K8s | 1.28 |
| **vnet_address_space** | CIDR VNet | 10.0.0.0/16 |
| **subnet_address_prefix** | CIDR subnet AKS | 10.0.1.0/24 |
| **node_vm_size** | Loại VM (ví dụ Standard_D2s_v3) | Standard_D2s_v3 |
| **node_count / node_min_count / node_max_count** | Số node, autoscaling | 2; 1; 3 |

**Lưu ý:** **subscription_id** có thể set qua biến hoặc `az account set`; provider dùng subscription mặc định.

---

## 4. Các bước chạy

### Bước 1: Xác thực Azure

```bash
az login
az account set --subscription "Tên hoặc ID subscription"
```

### Bước 2: Tạo file biến

```bash
cp terraform.tfvars.example terraform.tfvars
# Chỉnh resource_group_name, location, cluster_name
```

### Bước 3: Init, Plan, Apply

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Bước 4: Kubeconfig

```bash
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw cluster_name)
kubectl get nodes
```

### Bước 5: Destroy

```bash
terraform destroy
```

---

## 5. Lưu ý

- **Chi phí**: AKS control plane miễn phí; tính phí theo node (VM). VNet, subnet không tính thêm theo dung lượng.
- **Managed Identity**: SystemAssigned dùng cho ACR pull, Azure Disk; có thể thêm **azure_rbac** (Azure AD integration) cho RBAC.
- Tài liệu: [AKS Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster), [AKS](https://learn.microsoft.com/en-us/azure/aks/).
