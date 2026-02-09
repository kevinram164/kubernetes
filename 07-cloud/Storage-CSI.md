# Storage CSI trên Cloud – Phase 6

Trên cloud, **CSI driver** do provider cung cấp: tạo volume từ EBS, Persistent Disk, Azure Disk khi bạn tạo **PVC** (dynamic provisioning).

---

## 1. So sánh nhanh

| Cloud | CSI driver | StorageClass mặc định | Ghi chú |
|-------|------------|------------------------|--------|
| **EKS** | EBS CSI (`ebs.csi.aws.com`) | `gp3`, `gp2` | PVC → PV (EBS volume) tự tạo; có thể snapshot. |
| **GKE** | PD CSI (`pd.csi.storage.gke.io`) | `standard`, `balanced`, `ssd` | Persistent Disk; multi-writer (ReadWriteMany) dùng Filestore. |
| **AKS** | Azure Disk CSI (`disk.csi.azure.com`) | `managed-csi`, `managed-csi-premium` | Azure Disk; Azure File cho RWX. |

---

## 2. EKS – EBS CSI

- Cài EBS CSI driver (add-on hoặc Helm).
- Tạo StorageClass (hoặc dùng mặc định):

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
volumeBindingMode: WaitForFirstConsumer
```

- PVC dùng `storageClassName: ebs-gp3` → K8s tạo PV (EBS volume) khi Pod schedule.

Tài liệu: [EBS CSI](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html).

---

## 3. GKE – Persistent Disk

- GKE có sẵn CSI; StorageClass `standard-rwo`, `balanced-rwo`, `ssd-rwo`.
- PVC không chỉ định storageClassName (dùng default) hoặc chỉ định `standard-rwo`.
- volumeBindingMode: WaitForFirstConsumer (volume tạo ở zone của node).

Tài liệu: [GKE Persistent Volumes](https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes).

---

## 4. AKS – Azure Disk

- Cài Azure Disk CSI (thường có sẵn); StorageClass `managed-csi`.
- PVC với storageClassName `managed-csi` → Azure Disk được tạo và gắn vào node.

Tài liệu: [AKS Azure Disk](https://learn.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv).

---

## 5. Khác với on-prem

- **On-prem**: Thường PV tạo thủ công (hostPath, NFS) hoặc dùng StorageClass với provisioner (e.g. NFS provisioner).
- **Cloud**: CSI driver gọi API cloud (EBS, PD, Azure Disk) để tạo volume; **dynamic provisioning** chuẩn; snapshot/restore tùy provider.
