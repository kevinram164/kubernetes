# Lab 05: Phase 5 – Advanced (Helm, Kustomize, CRD, GitOps)

**Mục tiêu:** Thực hành Kustomize, Helm, CRD, và (tùy chọn) Argo CD / Flux.

**Yêu cầu:** Cluster K8s đang chạy, `kubectl` đã cấu hình.

---

## Phần 1: Kustomize

### 1.1 Build và apply overlay dev

```bash
cd ../../06-advanced/kustomize
kubectl kustomize overlays/dev
kubectl apply -k overlays/dev
kubectl get all -n dev
```

### 1.2 Apply overlay prod

```bash
kubectl apply -k overlays/prod
kubectl get all -n prod
# So sánh replica, namespace với dev
```

### 1.3 Dọn

```bash
kubectl delete -k overlays/dev
kubectl delete -k overlays/prod
```

---

## Phần 2: Helm

### 2.1 Cài chart Bitnami Nginx

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-nginx bitnami/nginx -n default --set replicaCount=2
helm list -n default
kubectl get pods,svc -l app.kubernetes.io/name=nginx
helm status my-nginx -n default
```

### 2.2 Upgrade và rollback

```bash
helm upgrade my-nginx bitnami/nginx -n default --set replicaCount=3
kubectl get pods -l app.kubernetes.io/name=nginx
helm rollback my-nginx 1 -n default
helm history my-nginx -n default
```

### 2.3 Dọn

```bash
helm uninstall my-nginx -n default
```

---

## Phần 3: CRD

### 3.1 Tạo CRD và instance

```bash
kubectl apply -f ../../06-advanced/crd-example/hello-crd.yaml
kubectl get crd hellos.example.com
kubectl apply -f ../../06-advanced/crd-example/hello-instance.yaml
kubectl get hellos
kubectl get hello my-hello -o yaml
```

### 3.2 Dọn

```bash
kubectl delete -f ../../06-advanced/crd-example/hello-instance.yaml
kubectl delete -f ../../06-advanced/crd-example/hello-crd.yaml
```

---

## Phần 4: GitOps (Argo CD – tùy chọn)

### 4.1 Cài Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=120s
```

### 4.2 Lấy password admin

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### 4.3 Port-forward và login (tùy chọn)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Mở https://localhost:8080, login admin / <password>
# Tạo Application trỏ repo Git (path Kustomize/Helm) và sync
```

### 4.4 Dọn

```bash
kubectl delete namespace argocd
```
