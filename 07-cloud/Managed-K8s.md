# Managed Kubernetes (EKS, GKE, AKS) – Phase 6

**Managed Kubernetes**: Cloud provider quản lý **control plane** (API server, etcd, scheduler, controller-manager); bạn quản lý **node pool** (hoặc dùng serverless node như Fargate, GKE Autopilot).

---

## 1. So sánh nhanh

| | **EKS (AWS)** | **GKE (Google)** | **AKS (Azure)** |
|---|----------------|------------------|-----------------|
| **Tạo cluster** | `eksctl create cluster` hoặc Terraform/Console | `gcloud container clusters create` | `az aks create` |
| **Kubeconfig** | `aws eks update-kubeconfig --name <cluster>` | `gcloud container clusters get-credentials <cluster>` | `az aks get-credentials --resource-group <rg> --name <cluster>` |
| **IAM gắn SA** | IRSA (IAM Role for Service Account) | Workload Identity | Workload Identity (AAD) |
| **Storage CSI** | EBS CSI, EFS CSI | Persistent Disk (pd.csi.storage.gke.io) | Azure Disk, Azure File |
| **LoadBalancer** | NLB/ALB (type LoadBalancer) | GCP Network LB / Ingress | Azure LB / Application Gateway |
| **CNI mặc định** | VPC CNI (Pod dùng IP VPC) | GKE Dataplane V2 / Calico | Azure CNI / Kubenet |

---

## 2. Tạo cluster (ví dụ)

### EKS (eksctl)

```bash
eksctl create cluster --name mycluster --region ap-southeast-1 --nodegroup-name ng1 --node-type t3.medium --nodes 2
aws eks update-kubeconfig --name mycluster --region ap-southeast-1
kubectl get nodes
```

### GKE

```bash
gcloud container clusters create mycluster --zone asia-southeast1-a --num-nodes 2
gcloud container clusters get-credentials mycluster --zone asia-southeast1-a
kubectl get nodes
```

### AKS

```bash
az group create --name myRG --location southeastasia
az aks create --resource-group myRG --name mycluster --node-count 2
az aks get-credentials --resource-group myRG --name mycluster
kubectl get nodes
```

---

## 3. Khác biệt so với on-prem

| Khía cạnh | On-prem / local | Managed cloud |
|-----------|-----------------|---------------|
| **Control plane** | Bạn cài và maintain (hoặc kubeadm) | Cloud quản lý, không truy cập trực tiếp |
| **Node** | VM/physical do bạn quản lý | Node pool trong VPC cloud; có thể autoscaling, spot |
| **Storage** | PV hostPath, NFS, hoặc CSI tự cài | CSI do cloud cung cấp (EBS, Persistent Disk, Azure Disk) |
| **LoadBalancer** | MetalLB hoặc NodePort | Service type LoadBalancer tạo LB cloud |
| **Networking** | Bạn cấu hình CNI, route | VPC, subnet; CNI tích hợp (VPC CNI, …) |

---

## 4. Chi phí và vận hành

- **Control plane**: EKS tính phí theo cluster/giờ; GKE/AKS có tier free (GKE Autopilot tính theo Pod).
- **Node**: Tính theo instance type và số giờ chạy; spot/preemptible giảm chi phí.
- **Add-on**: Ingress controller, CSI driver thường có sẵn hoặc cài qua Helm; monitor qua CloudWatch/Stackdriver/Azure Monitor.

Tài liệu: [EKS](https://docs.aws.amazon.com/eks/), [GKE](https://cloud.google.com/kubernetes-engine/docs), [AKS](https://learn.microsoft.com/en-us/azure/aks/).
