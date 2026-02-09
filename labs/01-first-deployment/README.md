# Lab 01: First Deployment

**Mục tiêu:** Deploy một ứng dụng web đơn giản, expose qua Service, và thử scale + rolling update.

## Yêu cầu

- Cluster K8s đang chạy (minikube / kind / k3s).
- `kubectl` đã cấu hình đúng context.

## Bước 1: Deploy app

Dùng manifest trong `../01-fundamentals/deployment-example.yaml`:

```bash
kubectl apply -f ../../01-fundamentals/deployment-example.yaml
```

Kiểm tra:

- `kubectl get pods` – 3 pod Running
- `kubectl get svc` – service `nginx-service` tồn tại

## Bước 2: Truy cập từ trong cluster

Chạy pod tạm và curl từ trong cluster:

```bash
kubectl run curl --rm -it --image=curlimages/curl -- sh
# Trong shell: curl http://nginx-service.default.svc.cluster.local
```

## Bước 3: Scale

```bash
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods
```

## Bước 4: Rolling update

Đổi image sang phiên bản khác:

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.26-alpine
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
```

Rollback nếu cần:

```bash
kubectl rollout undo deployment/nginx-deployment
```

## Dọn dẹp

```bash
kubectl delete -f ../../01-fundamentals/deployment-example.yaml
```

## Ghi chú

- Thay `default` trong URL bằng namespace của bạn nếu khác.
- Có thể dùng `kubectl port-forward svc/nginx-service 8080:80` để truy cập từ máy local: `http://localhost:8080`.
