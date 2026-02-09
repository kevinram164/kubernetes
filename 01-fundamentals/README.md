# 01 – Fundamentals (Phase 1 & Phase 2)

Các workload cơ bản: Pod, Deployment, Service. Phase 2 bổ sung: probes, rolling update/rollback, Service types, và link tới Ingress (03-networking).

---

## Pod

- Đơn vị nhỏ nhất có thể deploy trong K8s.
- Một hoặc nhiều container chung network (localhost) và storage.
- Thường không tạo Pod trực tiếp mà dùng Deployment/StatefulSet.

### Lifecycle

- **Pending** → **Running** (hoặc **Succeeded** / **Failed**).
- Container có thể **Running**, **Waiting**, **Terminated**.

### Probes (Phase 2)

| Probe | Mục đích |
|-------|----------|
| **livenessProbe** | Container còn sống không? Fail → K8s restart container. |
| **readinessProbe** | Pod sẵn sàng nhận traffic chưa? Fail → Pod bị bỏ khỏi Service endpoints (không nhận request). |
| **startupProbe** | App khởi động chậm; K8s chờ startupProbe pass rồi mới bắt đầu liveness/readiness. |

Tham số thường dùng: `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, `failureThreshold`.

Xem mẫu: `pod-example.yaml` (liveness + readiness), `pod-with-startup-probe.yaml` (có startupProbe).

---

## Deployment

- Quản lý ReplicaSet → quản lý nhiều Pod giống nhau.
- Dùng cho app **stateless**.

### Rolling update & Rollback (Phase 2)

- **strategy.type: RollingUpdate** (mặc định): cập nhật dần, không downtime.
- **strategy.rollingUpdate**: `maxSurge`, `maxUnavailable` điều khiển tốc độ.
- Rollback: `kubectl rollout undo deployment/<name>` hoặc `kubectl rollout undo deployment/<name> --to-revision=<n>`.

Xem: `deployment-example.yaml`, `deployment-rolling-update.yaml`.

---

## Service

- Endpoint ổn định để truy cập Pod (selector theo label).
- **ClusterIP** (mặc định): chỉ trong cluster.
- **NodePort**: expose port trên mỗi node (30000–32767), truy cập từ ngoài qua `<NodeIP>:<NodePort>`.
- **LoadBalancer**: cloud tạo load balancer ngoài (trên bare metal cần MetalLB hoặc tương đương).

Xem: `deployment-example.yaml` (ClusterIP), `service-nodeport.yaml`, `service-loadbalancer.yaml`.

---

## Thực hành

```bash
# Áp dụng manifest
kubectl apply -f pod-example.yaml
kubectl apply -f deployment-example.yaml

# Phase 2: Rolling update
kubectl set image deployment/nginx-deployment nginx=nginx:1.26-alpine
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment

# Service
kubectl get svc
kubectl get endpoints
```

**Phase 2 tiếp:** Ingress (routing HTTP/HTTPS) → xem **[03-networking/](../03-networking/)**.
