# 07 – Cloud & Managed Kubernetes (Phase 6)

Phase 6 dành cho **chuyển từ on-prem / local lên cloud**: dùng managed Kubernetes (EKS, GKE, AKS) và các tích hợp cloud (IAM, storage, load balancer, networking).

---

## Tại sao Phase 6 là Cloud?

- **Phase 1–4** tập trung trên **on-prem / local** (minikube, kind, k3s, hoặc K8s-the-hard-way): bạn đã nắm workload, config, storage, security trên một cluster “thuần” K8s.
- **Phase 5** bổ sung **tooling** (Helm, Kustomize, Operators, GitOps) – dùng được cả on-prem lẫn cloud.
- **Phase 6** là bước **đưa workload lên cloud**: managed control plane, IAM cloud gắn với K8s, storage/load balancer/networking do cloud cung cấp. Hợp lý khi đã vững Phase 1–4 và có thể dùng Phase 5 để deploy.

---

## Nội dung Phase 6

| Chủ đề | Mô tả ngắn | File |
|--------|-------------|------|
| **Managed K8s** | EKS, GKE, AKS: tạo cluster, kubeconfig, so sánh on-prem | [Managed-K8s.md](Managed-K8s.md) |
| **IAM & RBAC** | IRSA (EKS), Workload Identity (GKE/AKS). Pod gọi API cloud không cần secret | [IAM-RBAC.md](IAM-RBAC.md) |
| **Storage** | CSI: EBS, Persistent Disk, Azure Disk. StorageClass dynamic provisioning | [Storage-CSI.md](Storage-CSI.md) |
| **LoadBalancer & Ingress** | Cloud LB, ALB Ingress (EKS), GKE Ingress, AKS AGIC | [LB-Ingress.md](LB-Ingress.md) |
| **Networking** | VPC, CNI, private cluster (đề cập trong Managed-K8s). |
| **Vận hành & chi phí** | Node pool, autoscaling, spot, monitoring (đề cập trong Managed-K8s). |

---

## Thứ tự học gợi ý

1. Chọn **một** cloud (AWS / GCP / Azure) và tạo **managed cluster** (EKS / GKE / AKS).
2. Làm quen **kubeconfig**, deploy workload đơn giản (Deployment + Service + Ingress) giống on-prem.
3. Bật **IAM integration** (IRSA / Workload Identity) và thử Pod gọi API cloud.
4. Tạo **PVC** dùng StorageClass cloud (dynamic provisioning).
5. Cấu hình **LoadBalancer / Ingress** do cloud cung cấp.
6. (Tùy chọn) Private cluster, autoscaling, spot node, monitoring.

---

## Tài liệu tham khảo

- **EKS:** [AWS EKS Docs](https://docs.aws.amazon.com/eks/), IRSA, VPC CNI, EBS CSI.
- **GKE:** [GKE Docs](https://cloud.google.com/kubernetes-engine/docs), Workload Identity, GKE Ingress.
- **AKS:** [AKS Docs](https://learn.microsoft.com/en-us/azure/aks/), Workload Identity, Azure Disk CSI.

**Triển khai bằng Terraform (chi tiết):** **[Terraform-README.md](Terraform-README.md)** – Hướng dẫn tạo EKS, GKE, AKS bằng Terraform (VPC, cluster, node pool, kubeconfig). Thư mục **[terraform/eks/](terraform/eks/)**, **[terraform/gke/](terraform/gke/)**, **[terraform/aks/](terraform/aks/)** chứa code và README từng bước.

Lab tổng hợp (tạo cluster cloud, IAM, PVC, Ingress): **[labs/06-phase6-cloud/](../labs/06-phase6-cloud/)** (khi có cluster EKS/GKE/AKS).
