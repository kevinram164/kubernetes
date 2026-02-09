# Lab 02: Phase 2 – Workloads & Ingress

**Mục tiêu:** Thực hành Pod probes, Deployment rolling update/rollback, Service (ClusterIP/NodePort), và Ingress.

**Yêu cầu:** Cluster K8s đang chạy, `kubectl` đã cấu hình.

---

## Phần 1: Probes và Rolling update

### 1.1 Pod với liveness + readiness

```bash
kubectl apply -f ../../01-fundamentals/pod-example.yaml
kubectl get pods -w
kubectl describe pod nginx-pod
# Kiểm tra Events: liveness/readiness probe
kubectl delete pod nginx-pod
```

### 1.2 Pod với startupProbe

```bash
kubectl apply -f ../../01-fundamentals/pod-with-startup-probe.yaml
kubectl get pods
kubectl describe pod nginx-startup-probe
kubectl delete pod nginx-startup-probe
```

### 1.3 Deployment + Rolling update

```bash
kubectl apply -f ../../01-fundamentals/deployment-example.yaml
kubectl get pods,deploy
kubectl set image deployment/nginx-deployment nginx=nginx:1.26-alpine
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
```

---

## Phần 2: Service types

### 2.1 ClusterIP (đã có trong deployment-example.yaml)

```bash
kubectl get svc nginx-service
kubectl run curl --rm -it --image=curlimages/curl -- sh
# Trong shell: curl http://nginx-service.default.svc.cluster.local
```

### 2.2 NodePort

```bash
# Cần Service selector trùng với Deployment (app: nginx)
kubectl apply -f ../../01-fundamentals/service-nodeport.yaml
kubectl get svc nginx-nodeport
# Truy cập từ máy có thể tới node: http://<NodeIP>:30080
```

### 2.3 LoadBalancer (tùy chọn)

Trên cloud (GKE/EKS/AKS) hoặc bare metal có MetalLB:

```bash
kubectl apply -f ../../01-fundamentals/service-loadbalancer.yaml
kubectl get svc nginx-loadbalancer
```

---

## Phần 3: Ingress

### 3.1 Cài Ingress controller (nếu chưa có)

Ví dụ ingress-nginx (bare metal / NodePort):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.0/deploy/static/provider/baremetal/deploy.yaml
kubectl get pods -n ingress-nginx -w
```

### 3.2 Tạo Ingress

Ingress mẫu trỏ tới Service **nginx-service** (từ `01-fundamentals/deployment-example.yaml`). Áp dụng Deployment + Service trước, sau đó Ingress:

```bash
kubectl apply -f ../../01-fundamentals/deployment-example.yaml
kubectl apply -f ../../03-networking/ingress-example.yaml
kubectl get ingress
```

### 3.3 Truy cập qua Ingress

- Nếu controller dùng NodePort: lấy port từ `kubectl get svc -n ingress-nginx`, gọi `http://<NodeIP>:<port>`.
- Set header Host: `curl -H "Host: app.example.com" http://<NodeIP>:<port>`
- Hoặc thêm vào `/etc/hosts`: `<NodeIP> app.example.com`

---

## Dọn dẹp

```bash
kubectl delete -f ../../01-fundamentals/deployment-example.yaml
kubectl delete -f ../../01-fundamentals/service-nodeport.yaml
kubectl delete -f ../../03-networking/ingress-example.yaml
# Pod đơn lẻ đã xóa ở trên
```
