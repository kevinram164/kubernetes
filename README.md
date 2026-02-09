# Kubernetes – Học chuyên sâu

Repo dùng để học và thực hành Kubernetes (K8s) từ cơ bản đến nâng cao.

## 🗂 Cấu trúc 

```
kubernetes/
├── kubernetes-the-hard-way/  # Học K8s từ đầu: CA, etcd, control plane, workers (xem README bên trong)
├── 01-fundamentals/     # Pods, Deployments, Services
├── 02-config-storage/   # ConfigMap, Secret, PV/PVC
├── 03-networking/       # Ingress, NetworkPolicy, DNS
├── 04-security/        # RBAC, Pod Security, NetworkPolicy
├── 05-observability/   # Logs, Metrics, Tracing
├── 06-advanced/        # Operators, CRD, Helm, Kustomize
├── 07-cloud/           # Phase 6: Cloud & Managed K8s (EKS, GKE, AKS)
├── 08-troubleshooting/ # Debug, events, best practices
├── labs/               # Bài lab thực hành end-to-end
└── cheatsheets/        # Lệnh & YAML thường dùng
```

## 📚 Lộ trình học gợi ý

### Phase 1: Nền tảng
- [ ] Hiểu kiến trúc K8s (Control Plane vs Worker Nodes)
- [ ] Cài cluster: minikube / kind / k3s (local) hoặc cloud (EKS, GKE, AKS)
- [ ] Làm quen `kubectl`: get, describe, logs, exec

### Phase 2: Workloads & Networking
- [ ] **Pods**: lifecycle, probes (liveness, readiness, startup) → [01-fundamentals/](01-fundamentals/), `pod-example.yaml`, `pod-with-startup-probe.yaml`
- [ ] **Deployments**: rolling update, rollback → [01-fundamentals/](01-fundamentals/), `deployment-rolling-update.yaml`
- [ ] **Services**: ClusterIP, NodePort, LoadBalancer → [01-fundamentals/](01-fundamentals/), `service-nodeport.yaml`, `service-loadbalancer.yaml`
- [ ] **Ingress**: routing HTTP/HTTPS → [03-networking/](03-networking/), [labs/02-phase2-workloads-ingress/](labs/02-phase2-workloads-ingress/)

### Phase 3: Config & Storage
- [ ] **ConfigMap**, **Secret** → [02-config-storage/](02-config-storage/), `configmap-example.yaml`, `secret-example.yaml`, `deployment-with-config-secret.yaml`
- [ ] **PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass** → [02-config-storage/](02-config-storage/), `pv-pvc-example.yaml`, `storageclass-example.yaml`, `deployment-with-pvc.yaml`, [labs/03-phase3-config-storage/](labs/03-phase3-config-storage/)

### Phase 4: Security & Production (chuyên sâu)
- [ ] **RBAC** (Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount, least privilege) → [04-security/RBAC.md](04-security/RBAC.md), [04-security/rbac/](04-security/rbac/)
- [ ] **Pod Security** (PSS privileged/baseline/restricted, Pod Security Admission, securityContext) → [04-security/Pod-Security.md](04-security/Pod-Security.md), [04-security/pod-security/](04-security/pod-security/)
- [ ] **NetworkPolicy** (default deny, ingress/egress, podSelector, namespaceSelector) → [04-security/NetworkPolicy.md](04-security/NetworkPolicy.md), [04-security/networkpolicy/](04-security/networkpolicy/), [labs/04-phase4-security/](labs/04-phase4-security/)

### Phase 5: Nâng cao (tooling)
- [ ] **Helm** charts → [06-advanced/Helm.md](06-advanced/Helm.md), [06-advanced/helm/](06-advanced/helm/)
- [ ] **Kustomize** → [06-advanced/Kustomize.md](06-advanced/Kustomize.md), [06-advanced/kustomize/](06-advanced/kustomize/)
- [ ] **Operators & CRD** → [06-advanced/Operators-CRD.md](06-advanced/Operators-CRD.md), [06-advanced/crd-example/](06-advanced/crd-example/)
- [ ] **GitOps** (Argo CD / Flux) → [06-advanced/GitOps.md](06-advanced/GitOps.md), [06-advanced/gitops/](06-advanced/gitops/), [labs/05-phase5-advanced/](labs/05-phase5-advanced/)

### Phase 6: Cloud & Managed Kubernetes (chuyển từ on-prem lên cloud)
- [ ] **Managed K8s:** EKS (AWS), GKE (Google), AKS (Azure) – tạo cluster, kubeconfig, so sánh với on-prem
- [ ] **IAM & RBAC:** Gắn IAM cloud với ServiceAccount (IRSA, Workload Identity, AAD Pod Identity)
- [ ] **Storage trên cloud:** CSI driver (EBS, Persistent Disk, Azure Disk), StorageClass dynamic provisioning
- [ ] **LoadBalancer & Ingress:** Cloud Load Balancer, Ingress controller (ALB/NLB, GKE Ingress, AKS App Gateway)
- [ ] **Networking:** VPC, CNI (VPC CNI, Calico trên cloud), Private cluster
- [ ] **Chi phí & vận hành:** Node pool, autoscaling, spot/preemptible, monitoring tích hợp

→ [07-cloud/](07-cloud/): [Managed-K8s.md](07-cloud/Managed-K8s.md), [IAM-RBAC.md](07-cloud/IAM-RBAC.md), [Storage-CSI.md](07-cloud/Storage-CSI.md), [LB-Ingress.md](07-cloud/LB-Ingress.md), [labs/06-phase6-cloud/](labs/06-phase6-cloud/)

### Phase 7: Troubleshooting & vận hành
- [ ] **Debug:** describe, logs, exec, kubectl debug → [08-troubleshooting/Debug.md](08-troubleshooting/Debug.md)
- [ ] **Events:** get events, điều tra Pending, CrashLoopBackOff → [08-troubleshooting/Events.md](08-troubleshooting/Events.md)
- [ ] **Checklist & best practices** → [08-troubleshooting/Checklist.md](08-troubleshooting/Checklist.md), [labs/07-phase7-troubleshooting/](labs/07-phase7-troubleshooting/)

## 🛠 Môi trường thực hành

| Công cụ | Mục đích |
|--------|----------|
| **minikube** | Cluster 1 node trên máy local |
| **kind** | Cluster trong Docker, phù hợp CI |
| **k3s** | K8s nhẹ, dễ cài trên Raspberry Pi / VPS |
| **Play with K8s** | Lab trên trình duyệt (miễn phí có giới hạn) |

## 🏗 Kubernetes The Hard Way

Nếu muốn **hiểu sâu từng thành phần** (CA, etcd, API server, kubelet, CNI...), làm tutorial **[Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)**. Trong repo này có sẵn:

- **[kubernetes-the-hard-way/](kubernetes-the-hard-way/)** – Hướng dẫn học, checklist 13 lab, link tới từng bước gốc, và file `notes.md` để ghi chú khi làm.

## 📖 Tài liệu tham khảo

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) – hiểu sâu từng bước
- [CNCF Landscape](https://landscape.cncf.io/) – hệ sinh thái quanh K8s

## ✅ Cách dùng repo này

1. Tạo thư mục theo từng chủ đề (ví dụ `01-fundamentals/`).
2. Mỗi thư mục chứa: file YAML mẫu + ghi chú (markdown) giải thích.
3. Làm lab trong `labs/`, mỗi lab một thư mục có README mô tả mục tiêu và bước làm.
4. Dùng `cheatsheets/` để lưu lệnh và snippet hay dùng.

Chúc bạn học K8s hiệu quả.
