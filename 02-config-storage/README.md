# 02 – Config & Storage (Phase 3)

Cấu hình và lưu trữ: **ConfigMap**, **Secret**, **PersistentVolume (PV)**, **PersistentVolumeClaim (PVC)**, **StorageClass**.

---

## ConfigMap

- Lưu **cấu hình không nhạy cảm** (key-value): biến môi trường, file cấu hình.
- Pod dùng ConfigMap qua **env** (từng key hoặc toàn bộ) hoặc **volume** (mount file).

| Cách dùng | Ghi chú |
|-----------|--------|
| **envFrom** | Inject toàn bộ ConfigMap thành biến môi trường. |
| **env.valueFrom** | Lấy một key cụ thể làm biến môi trường. |
| **volume** | Mount ConfigMap thành file trong container (path tùy chọn). |

Xem: `configmap-example.yaml`, `deployment-with-config-secret.yaml`.

---

## Secret

- Lưu **dữ liệu nhạy cảm** (mật khẩu, token, cert). Base64 encode trong YAML; K8s decode khi mount/env.
- Pod dùng Secret qua **env** hoặc **volume** (tương tự ConfigMap).

| Loại | Ghi chú |
|------|--------|
| **Opaque** (generic) | Key-value tùy ý. |
| **kubernetes.io/tls** | TLS cert + key. |
| **kubernetes.io/dockerconfigjson** | Credential pull image từ registry. |

Tạo nhanh: `kubectl create secret generic <name> --from-literal=key=value`.

Xem: `secret-example.yaml`, `deployment-with-config-secret.yaml`.

---

## PersistentVolume (PV) và PersistentVolumeClaim (PVC)

- **PV** = tài nguyên lưu trữ do admin cung cấp (disk, NFS, cloud volume…).
- **PVC** = “yêu cầu” storage từ user/workload; K8s **bind** PVC với PV phù hợp (capacity, accessMode, storageClassName).
- Pod dùng **volume** kiểu `persistentVolumeClaim` để mount storage vào container.

| Khái niệm | Ý nghĩa |
|-----------|--------|
| **accessModes** | ReadWriteOnce (RWO), ReadOnlyMany (ROX), ReadWriteMany (RWX). |
| **capacity** | Kích thước (ví dụ 1Gi, 10Gi). |
| **storageClassName** | Nhóm PV theo class; PVC chỉ định class để bind đúng loại storage. |

Xem: `pv-pvc-example.yaml`, `storageclass-example.yaml`, `deployment-with-pvc.yaml`.

---

## StorageClass

- Định nghĩa **class** storage (provisioner, parameters); cho phép **dynamic provisioning**: tạo PVC → K8s tự tạo PV (nếu cluster hỗ trợ).
- Minikube/kind thường có sẵn StorageClass `standard` hoặc `hostpath`.

Xem: `storageclass-example.yaml`.

---

## Thực hành

```bash
# ConfigMap
kubectl apply -f configmap-example.yaml
kubectl get configmap
kubectl describe configmap app-config

# Secret
kubectl apply -f secret-example.yaml
# Hoặc: kubectl create secret generic app-secret --from-literal=db-password=secret123
kubectl get secret

# PV + PVC (hostPath phù hợp minikube/kind; production dùng NFS/cloud)
kubectl apply -f pv-pvc-example.yaml
kubectl get pv,pvc

# Deployment dùng ConfigMap + Secret
kubectl apply -f deployment-with-config-secret.yaml

# Deployment dùng PVC
kubectl apply -f deployment-with-pvc.yaml
```

Lab tổng hợp: **[labs/03-phase3-config-storage/](../labs/03-phase3-config-storage/)**.
