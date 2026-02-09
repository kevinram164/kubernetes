# Kustomize – Phase 5

Kustomize quản lý **base** manifest + **overlay** (patch) theo môi trường (dev, staging, prod) mà **không sửa** file YAML gốc.

---

## 1. Khái niệm

| Khái niệm | Ý nghĩa |
|-----------|--------|
| **base** | Thư mục chứa kustomization.yaml + manifest gốc (deployment, service, …). |
| **overlay** | Thư mục kế thừa base, thêm patch (namespace, replica, image, label). |
| **kustomization.yaml** | Khai báo resources, namespace, commonLabels, images, patches. |

---

## 2. Cấu trúc ví dụ

```
base/
  kustomization.yaml
  deployment.yaml
  service.yaml
overlays/
  dev/
    kustomization.yaml   # tham chiếu ../../base, namespace: dev, replica: 1
  prod/
    kustomization.yaml   # tham chiếu ../../base, namespace: prod, replica: 3
```

---

## 3. Lệnh cơ bản

```bash
# Build YAML (in ra stdout)
kubectl kustomize overlays/dev
kustomize build overlays/dev

# Áp dụng lên cluster
kubectl apply -k overlays/dev
kubectl apply -k overlays/prod

# Diff trước khi apply
kubectl diff -k overlays/prod
```

---

## 4. kustomization.yaml thường dùng

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: my-namespace
resources:
  - deployment.yaml
  - service.yaml
commonLabels:
  env: prod
images:
  - name: nginx
    newName: nginx
    newTag: "1.26-alpine"
replicas:
  - name: nginx-deployment
    count: 3
patches:
  - path: patch-replica.yaml
```

---

## 5. So sánh với Helm

| | Kustomize | Helm |
|---|-----------|------|
| **Cách làm** | Base + overlay, patch YAML | Template + values, render YAML |
| **Tích hợp** | `kubectl apply -k` (built-in) | Cần cài helm CLI |
| **Dùng khi** | Nhiều môi trường, ít biến | Chart có sẵn, nhiều biến, release version |

---

## 6. Ví dụ và lab

- **kustomize/** – Base + overlay dev/prod mẫu.
- Lab: **[labs/05-phase5-advanced/](../labs/05-phase5-advanced/)** (phần Kustomize).

Tài liệu: [Kustomize](https://kustomize.io/), [Kubectl Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).
