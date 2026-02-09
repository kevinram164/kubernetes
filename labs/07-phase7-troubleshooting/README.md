# Lab 07: Phase 7 – Troubleshooting

**Mục tiêu:** Thực hành debug Pod Pending, CrashLoopBackOff, Service không kết nối, xem events.

**Yêu cầu:** Cluster K8s đang chạy.

---

## Phần 1: Pod Pending (FailedScheduling)

### 1.1 Tạo Pod request vượt quá node

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: too-big
spec:
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: "999"
          memory: "999Gi"
EOF
kubectl get pod too-big
kubectl describe pod too-big
# Events: FailedScheduling (0/X nodes available: insufficient cpu/memory)
kubectl delete pod too-big
```

---

## Phần 2: CrashLoopBackOff

### 2.1 Tạo Pod crash ngay (command exit 1)

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: crash-pod
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "exit 1"]
EOF
kubectl get pod crash-pod -w
# Trạng thái: CrashLoopBackOff
kubectl describe pod crash-pod
kubectl logs crash-pod --previous
kubectl delete pod crash-pod
```

---

## Phần 3: Service không có endpoint

### 3.1 Service selector không khớp Pod

```bash
kubectl run nginx --image=nginx --restart=Never
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: no-endpoint
spec:
  selector:
    app: not-exist
  ports:
    - port: 80
      targetPort: 80
EOF
kubectl get endpoints no-endpoint
# Không có địa chỉ (selector không khớp)
kubectl get pods -l app=not-exist
kubectl delete pod nginx
kubectl delete svc no-endpoint
```

---

## Phần 4: Events

```bash
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
kubectl get events --field-selector type=Warning
```

---

## Tài liệu

- [08-troubleshooting/Debug.md](../../08-troubleshooting/Debug.md)
- [08-troubleshooting/Events.md](../../08-troubleshooting/Events.md)
- [08-troubleshooting/Checklist.md](../../08-troubleshooting/Checklist.md)
