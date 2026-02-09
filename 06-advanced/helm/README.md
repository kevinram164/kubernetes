# Helm – Ví dụ và lệnh

## Dùng chart có sẵn (Bitnami Nginx)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/nginx
helm install my-nginx bitnami/nginx -n default --set replicaCount=2
helm list -n default
helm status my-nginx -n default
helm upgrade my-nginx bitnami/nginx -n default --set replicaCount=3
helm rollback my-nginx 1 -n default
helm uninstall my-nginx -n default
```

## Tạo chart mới

```bash
helm create mychart
cd mychart
# Chỉnh templates/ và values.yaml
helm install my-release . -n default
helm template my-release .   # In ra YAML không cài
```

Cấu trúc: `Chart.yaml`, `values.yaml`, `templates/*.yaml` (Go template).
