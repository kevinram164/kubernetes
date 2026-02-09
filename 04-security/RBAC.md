# RBAC – Chuyên sâu

RBAC (Role-Based Access Control) là cơ chế **authorization** mặc định của Kubernetes: quyết định **ai** (User, Group, ServiceAccount) được **làm gì** (verbs) trên **resource nào** (API resources, có thể theo namespace).

---

## 1. Các thành phần RBAC

| Resource | Phạm vi | Ý nghĩa |
|----------|--------|--------|
| **Role** | Một namespace | Tập quyền (rules) trong namespace đó. |
| **ClusterRole** | Toàn cluster | Tập quyền không phụ thuộc namespace, hoặc dùng cho resource cluster-scoped (Node, PV, …). |
| **RoleBinding** | Một namespace | Gắn Role/ClusterRole với subject(s) **trong namespace** đó. |
| **ClusterRoleBinding** | Toàn cluster | Gắn ClusterRole với subject(s) **toàn cluster**. |

**Quy tắc quan trọng:**

- **Role** chỉ dùng với **RoleBinding** (cùng namespace).
- **ClusterRole** có thể dùng với **RoleBinding** (khi đó quyền bị giới hạn trong namespace của RoleBinding) hoặc **ClusterRoleBinding** (quyền toàn cluster).
- **RoleBinding** có thể reference **Role** (cùng namespace) hoặc **ClusterRole** (quyền áp dụng trong namespace của RoleBinding).

---

## 2. Subject: Ai được gán quyền?

| Kind | Ví dụ | Ghi chú |
|------|--------|--------|
| **User** | `alice`, `system:node:node-0` | Thường do external auth (OIDC, cert, …); không có resource User trong K8s. |
| **Group** | `system:masters`, `developers` | Nhóm user; `system:masters` có full quyền (cluster-admin). |
| **ServiceAccount** | `default`, `ci-bot` (trong namespace `ci`) | Identity cho Pod/process trong cluster; **dùng nhiều nhất** cho automation. |

**ServiceAccount:**

- Mỗi namespace có ServiceAccount mặc định `default`.
- Pod không chỉ định `spec.serviceAccountName` thì dùng `default`.
- Token của ServiceAccount dùng để gọi API server (kubectl trong Pod, hoặc app trong cluster).

---

## 3. Rule: Làm gì trên resource nào?

Mỗi rule có dạng:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: my-namespace
  name: pod-reader
rules:
  - apiGroups: [""]           # core API group (pods, services, configmaps, ...)
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    subresources: ["log"]
    verbs: ["get"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

- **apiGroups:** `""` = core (pods, services, configmaps, secrets, …); `"apps"` = deployments, replicasets; `"rbac.authorization.k8s.io"` = roles, rolebindings; …
- **resources:** Tên resource (số nhiều): `pods`, `deployments`, `secrets`, …
- **subresources:** Ví dụ `pods/log`, `pods/status`, `deployments/scale`.
- **verbs:** `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`, `deletecollection`. Với resourceNames có thể giới hạn `get`/`update`/`patch`/`delete` trên từng object.

**resourceNames (tùy chọn):** Giới hạn rule chỉ áp dụng cho object có tên trong list. Ví dụ: chỉ được get/update ConfigMap tên `my-config`.

---

## 4. Aggregation: Gộp ClusterRole

ClusterRole có thể **aggregate** nhiều ClusterRole khác qua labelSelector:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
        rbac.example.com/aggregate-to-monitoring: "true"
```

ClusterRole “cha” sẽ gộp tất cả rule từ các ClusterRole có label khớp. Dùng để mở rộng quyền (ví dụ admin mở thêm quyền monitoring) mà không sửa ClusterRole gốc.

---

## 5. Thiết kế least privilege

- **Namespace-scoped:** Dùng **Role** + **RoleBinding** trong từng namespace; tránh gán ClusterRole qua ClusterRoleBinding trừ khi thật cần (admin, cluster-reader).
- **ServiceAccount per workload:** Mỗi app/team dùng ServiceAccount riêng; gán Role/ClusterRole qua RoleBinding/ClusterRoleBinding.
- **Chỉ cấp verbs cần thiết:** Ví dụ CI chỉ cần `get`, `list`, `create`, `update`, `patch` trên deployments/pods trong namespace `staging`; không cấp `delete` nếu không cần.
- **Tách read vs write:** Role “read-only” (get, list, watch) và Role “deploy” (create, update, patch, delete) để dễ audit và thu hồi.

---

## 6. Một số pattern thường gặp

| Mục đích | Cách làm |
|----------|----------|
| **Read-only toàn cluster** | ClusterRole (pods, nodes, … get/list/watch) + ClusterRoleBinding → User/Group/SA. |
| **Deploy chỉ trong namespace `app-prod`** | Role trong `app-prod` (deployments, pods, … create/update/patch/delete) + RoleBinding trong `app-prod` → ServiceAccount. |
| **CI/CD chỉ trong namespace `ci`** | Role trong `ci` (deployments, pods, configmaps, …) + RoleBinding → ServiceAccount `ci-bot` trong `ci`. |
| **Xem log Pod trong namespace** | Role (pods, pods/log get/list) + RoleBinding → User/SA. |
| **Admin một namespace** | ClusterRole `admin` (K8s built-in) + RoleBinding trong namespace → User/Group (kubectl create rolebinding ... --clusterrole=admin). |

**Built-in ClusterRole (tham khảo):** `cluster-admin`, `admin`, `edit`, `view`. Dùng `kubectl get clusterrole` để xem; `view` ≈ read-only, `edit` ≈ read-write (không RBAC), `admin` = edit + RBAC trong namespace, `cluster-admin` = full cluster.

---

## 7. Troubleshooting RBAC

**Triệu chứng:** User/SA gọi API bị `403 Forbidden`.

- **Bước 1:** Xác định identity đang dùng: User hay ServiceAccount? Namespace?
- **Bước 2:** Liệt kê RoleBinding/ClusterRoleBinding có subject là identity đó:
  - `kubectl get rolebinding,clusterrolebinding -A -o yaml | grep -A5 -B5 <subject-name>`
  - Hoặc `kubectl get rolebinding -n <ns> -o wide` và kiểm tra subject.
- **Bước 3:** Xem Role/ClusterRole được bind: `kubectl get role <name> -n <ns> -o yaml` (rules có đúng apiGroups, resources, verbs?).
- **Bước 4:** Thử thêm quyền tối thiểu (một rule với resource + verb cần thiết) rồi test lại.

**Lưu ý:** Nếu cluster dùng Node authorizer, kubelet dùng certificate với CN `system:node:<node-name>`, group `system:nodes`; quyền node được định nghĩa sẵn (Node, Pod, Secret, …). Không cần gán Role cho node trừ khi mở rộng đặc biệt.

---

## 8. Ví dụ YAML và lệnh

Xem thư mục **[rbac/](rbac/)**:

- `role-read-only.yaml` – Role đọc pods, configmaps trong namespace.
- `clusterrole-read-only.yaml` – ClusterRole đọc pods, nodes (cluster-scoped).
- `rolebinding-read-only.yaml` – RoleBinding gán Role cho ServiceAccount.
- `clusterrolebinding-read-only.yaml` – ClusterRoleBinding gán ClusterRole cho Group/SA.
- `serviceaccount-ci.yaml` + `role-deploy-in-namespace.yaml` + `rolebinding-deploy.yaml` – Pattern CI chỉ deploy trong một namespace.

Lab thực hành: **[labs/04-phase4-security/](../labs/04-phase4-security/)** (phần RBAC).
