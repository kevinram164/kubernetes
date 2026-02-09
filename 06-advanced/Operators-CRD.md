# Operators & CRD – Phase 5

**CRD (Custom Resource Definition)** mở rộng API Kubernetes: thêm **resource type** mới (ví dụ `CronJob` đã có sẵn là built-in, bạn có thể tạo `MyApp`). **Operator** = controller đọc resource custom và thực hiện logic (tạo Pod, gọi API ngoài, …).

---

## 1. CRD

- **CRD** định nghĩa schema (tên resource, spec, status) và API endpoint (ví dụ `api.example.com/v1`, resource `myapps`).
- Sau khi tạo CRD, dùng `kubectl get myapps`, `kubectl apply -f myapp.yaml` như resource thường.
- Dữ liệu CR lưu trong etcd; **controller** (chạy trong cluster) watch CR và thực hiện hành động.

---

## 2. Operator

- **Operator** = controller + CRD: “operator cho MySQL” = CRD `MySQL` + controller tạo StatefulSet, Service, backup, …
- Viết bằng Go (controller-runtime, client-go) hoặc Python (kopf), v.v.
- Chạy trong cluster (Deployment); dùng **watch** (Informer) để phản ứng khi CR thay đổi.

---

## 3. Khi nào dùng

- Cần **resource tự định nghĩa** (ví dụ `Database`, `Queue`) và logic phức tạp (provision, scale, backup).
- Có sẵn Operator (Postgres Operator, Prometheus Operator, …) thì cài và dùng CRD của họ.

---

## 4. Ví dụ CRD đơn giản

Xem **crd-example/** – CRD `Hello` (spec: message), không có controller (chỉ lưu trong etcd). Controller thật cần code (Go/Python) đọc CR và tạo Pod/Service.

---

## 5. Lab và tài liệu

- Lab: **[labs/05-phase5-advanced/](../labs/05-phase5-advanced/)** (phần CRD – tạo CRD, tạo CR, xem trong API).
- [Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), [Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
