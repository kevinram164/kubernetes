# Helm – Phase 5

Helm là **package manager** cho Kubernetes: đóng gói manifest thành **chart**, cấu hình qua **values**, cài/ nâng cấp / rollback bằng lệnh.

---

## 1. Khái niệm

| Khái niệm | Ý nghĩa |
|-----------|--------|
| **Chart** | Gói chứa template YAML (Deployment, Service, …) + values mặc định. |
| **Release** | Một lần cài chart (tên release, namespace). |
| **Values** | Biến thay thế trong template (số replica, image, …). |
| **Repository** | Nơi lưu chart (HTTPS, OCI). |

---

## 2. Lệnh cơ bản

```bash
# Thêm repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Cài chart
helm install my-nginx bitnami/nginx -n default
helm install my-nginx bitnami/nginx -f values.yaml --set replicaCount=2

# Liệt kê release
helm list -A
helm status my-nginx -n default

# Nâng cấp
helm upgrade my-nginx bitnami/nginx -n default --set replicaCount=3

# Rollback
helm rollback my-nginx 1 -n default
helm history my-nginx -n default

# Gỡ
helm uninstall my-nginx -n default
```

---

## 3. Cấu trúc chart (tạo mới)

```bash
helm create mychart
# mychart/
#   Chart.yaml      # metadata, version
#   values.yaml     # giá trị mặc định
#   templates/      # *.yaml go template
#   charts/         # dependency (subchart)
```

Template dùng cú pháp **Go template** + hàm Helm: `{{ .Values.replicaCount }}`, `{{ .Release.Name }}`, `{{ include "mychart.name" . }}`.

---

## 4. Values và override

- **values.yaml** trong chart: mặc định.
- **-f values.yaml**: override từ file.
- **--set key=value**: override từng giá trị (dòng lệnh).
- Thứ tự ưu tiên: --set > -f > values.yaml trong chart.

---

## 5. Ví dụ và lab

- **helm/** – Hướng dẫn tạo chart đơn giản, dùng chart có sẵn (bitnami/nginx).
- Lab: **[labs/05-phase5-advanced/](../labs/05-phase5-advanced/)** (phần Helm).

Tài liệu: [Helm Docs](https://helm.sh/docs/).
