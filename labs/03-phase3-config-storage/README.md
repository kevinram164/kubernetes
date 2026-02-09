# Lab 03: Phase 3 – Config & Storage

**Mục tiêu:** Thực hành ConfigMap, Secret, PV, PVC, StorageClass và Pod/Deployment dùng chúng.

**Yêu cầu:** Cluster K8s đang chạy (minikube/kind/k3s hoặc cluster tự dựng).

---

## Phần 1: ConfigMap

### 1.1 Tạo ConfigMap

```bash
kubectl apply -f ../../02-config-storage/configmap-example.yaml
kubectl get configmap app-config
kubectl describe configmap app-config
```

### 1.2 Xem dùng trong Pod (qua env + volume)

```bash
kubectl apply -f ../../02-config-storage/deployment-with-config-secret.yaml
kubectl get pods -l app=app-with-config
kubectl logs -l app=app-with-config
# Phải thấy APP_ENV=development, LOG_LEVEL=info, DB_PASS=secret123 và nội dung app.conf
```

---

## Phần 2: Secret

### 2.1 Tạo Secret (YAML hoặc kubectl)

```bash
kubectl apply -f ../../02-config-storage/secret-example.yaml
kubectl get secret app-secret
kubectl get secret app-secret -o jsonpath='{.data.db-password}' | base64 -d
echo
```

### 2.2 Secret đã được dùng trong deployment-with-config-secret (env DB_PASSWORD)

Kiểm tra log ở Phần 1.2: biến DB_PASS in ra giá trị từ Secret.

---

## Phần 3: PV và PVC

### 3.1 Lưu ý môi trường

- **Minikube:** hostPath PV dùng path trên node (minikube VM). Có thể đổi `path` trong PV sang `/tmp/app-data` nếu không có quyền tạo `/data/app`.
- **Kind:** hostPath nằm trên Docker host; path ví dụ `/data/app` cần tồn tại hoặc dùng `DirectoryOrCreate`.
- **K3s / cluster thật:** Có thể dùng NFS hoặc CSI; PV mẫu dùng hostPath cho đơn giản.

### 3.2 Tạo PV + PVC

```bash
kubectl apply -f ../../02-config-storage/pv-pvc-example.yaml
kubectl get pv
kubectl get pvc
# PVC phải Bound với PV (STATUS=Bound)
```

Nếu PVC **Pending:** kiểm tra storageClassName, accessModes, capacity có khớp PV; trên minikube đảm bảo hostPath path hợp lệ.

### 3.3 Deployment dùng PVC

```bash
kubectl apply -f ../../02-config-storage/deployment-with-pvc.yaml
kubectl get pods -l app=app-with-pvc
kubectl logs -l app=app-with-pvc
# Phải thấy nội dung hello.txt (hello)
```

### 3.4 Kiểm tra dữ liệu tồn tại sau khi xóa Pod

```bash
kubectl delete pod -l app=app-with-pvc
kubectl apply -f ../../02-config-storage/deployment-with-pvc.yaml
kubectl logs -l app=app-with-pvc
# Log có thể thấy "hello" hai lần (append lại) – chứng tỏ volume giữ dữ liệu
```

---

## Phần 4: StorageClass (tham khảo)

```bash
kubectl get storageclass
# Minikube/kind thường có sẵn default StorageClass
kubectl apply -f ../../02-config-storage/storageclass-example.yaml
kubectl get storageclass
```

StorageClass `local-storage` dùng với PV tạo thủ công (provisioner: no-provisioner). Dynamic provisioning cần provisioner phù hợp (ví dụ EBS CSI trên AWS).

---

## Dọn dẹp

```bash
kubectl delete -f ../../02-config-storage/deployment-with-pvc.yaml
kubectl delete -f ../../02-config-storage/deployment-with-config-secret.yaml
kubectl delete -f ../../02-config-storage/pv-pvc-example.yaml
kubectl delete -f ../../02-config-storage/secret-example.yaml
kubectl delete -f ../../02-config-storage/configmap-example.yaml
kubectl delete -f ../../02-config-storage/storageclass-example.yaml 2>/dev/null || true
```
