# Lab 04: Phase 4 – Security & Production

**Mục tiêu:** Thực hành RBAC, Pod Security (PSS/PSA), Security Context, và NetworkPolicy.

**Yêu cầu:** Cluster K8s đang chạy. NetworkPolicy **chỉ có hiệu lực** nếu CNI hỗ trợ (Calico, Cilium, …).

---

## Phần 1: RBAC

### 1.1 Đọc tài liệu

Đọc **[04-security/RBAC.md](../../04-security/RBAC.md)** – nắm Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount, rule (apiGroups, resources, verbs).

### 1.2 Tạo ServiceAccount và Role (read-only)

```bash
kubectl create serviceaccount reader -n default
kubectl apply -f ../../04-security/rbac/role-read-only.yaml
kubectl apply -f ../../04-security/rbac/rolebinding-read-only.yaml
```

### 1.3 Kiểm tra quyền

```bash
# SA "reader" phải get/list được pods trong default
kubectl auth can-i get pods --as=system:serviceaccount:default:reader -n default
kubectl auth can-i create pods --as=system:serviceaccount:default:reader -n default
# Kỳ vọng: yes, no
```

### 1.4 Chạy Pod dùng SA "reader" và test từ trong Pod

```bash
kubectl run reader-pod --restart=Never --image=curlimages/curl --serviceaccount=reader -- sleep 3600
kubectl exec reader-pod -- sh -c 'curl -sk https://kubernetes.default.svc.cluster.local/api/v1/namespaces/default/pods'
# Phải thấy list pods (200). Thử create pod từ trong Pod (sẽ 403).
```

### 1.5 Pattern deploy-bot (chỉ deploy trong namespace)

```bash
kubectl apply -f ../../04-security/rbac/serviceaccount-deploy.yaml
kubectl apply -f ../../04-security/rbac/role-deploy-in-namespace.yaml
kubectl apply -f ../../04-security/rbac/rolebinding-deploy.yaml
kubectl auth can-i create deployments --as=system:serviceaccount:default:deploy-bot -n default
kubectl auth can-i get pods --as=system:serviceaccount:default:deploy-bot -n kube-system
# Kỳ vọng: yes, no
```

### 1.6 Dọn RBAC (tùy chọn)

```bash
kubectl delete pod reader-pod
kubectl delete rolebinding read-only-binding deployer-binding -n default
kubectl delete role read-only deployer -n default
kubectl delete serviceaccount reader deploy-bot -n default
```

---

## Phần 2: Pod Security (PSS / PSA)

### 2.1 Đọc tài liệu

Đọc **[04-security/Pod-Security.md](../../04-security/Pod-Security.md)** – PSS (privileged, baseline, restricted), Pod Security Admission (label namespace), securityContext.

### 2.2 Namespace với enforce baseline

```bash
kubectl apply -f ../../04-security/pod-security/namespace-baseline.yaml
kubectl run test-baseline -n app-baseline --image=nginx:alpine --restart=Never
kubectl get pods -n app-baseline
# Pod có thể chạy (baseline cho phép nhiều hơn restricted)
kubectl delete pod test-baseline -n app-baseline
```

### 2.3 Namespace với enforce restricted

```bash
kubectl apply -f ../../04-security/pod-security/namespace-restricted.yaml
kubectl run test-restricted -n app-restricted --image=nginx:alpine --restart=Never
# Có thể bị reject (nginx mặc định chạy root). Dùng Pod có securityContext:
kubectl apply -f ../../04-security/pod-security/pod-security-context.yaml -n app-restricted
# Sửa metadata.namespace trong file thành app-restricted hoặc apply vào default
kubectl apply -f ../../04-security/pod-security/deployment-restricted.yaml -n app-restricted
# Sửa metadata.namespace trong file thành app-restricted
kubectl get pods -n app-restricted
```

### 2.4 Pod với securityContext (trong default)

```bash
kubectl apply -f ../../04-security/pod-security/pod-security-context.yaml
kubectl get pods safe-pod
kubectl exec safe-pod -- id
# Phải thấy uid=1000, gid=1000
kubectl delete pod safe-pod
```

---

## Phần 3: NetworkPolicy

**Lưu ý:** NetworkPolicy **chỉ có hiệu lực** khi CNI hỗ trợ (Calico, Cilium, Weave, …). Trên minikube: `minikube addons enable network-policy` (dùng CNI hỗ trợ). Trên kind/ cluster khác: cài Calico hoặc Cilium.

### 3.1 Đọc tài liệu

Đọc **[04-security/NetworkPolicy.md](../../04-security/NetworkPolicy.md)** – default deny, ingress/egress, podSelector, namespaceSelector.

### 3.2 Default deny (nếu CNI hỗ trợ)

```bash
kubectl apply -f ../../04-security/networkpolicy/default-deny-all.yaml
# Sau khi apply: Pod trong namespace default không gửi/nhận được (trừ khi có policy khác mở)
# Mở DNS egress để Pod vẫn resolve:
kubectl apply -f ../../04-security/networkpolicy/allow-dns-egress.yaml
```

### 3.3 Cho phép ingress từ Pod cùng namespace

```bash
kubectl apply -f ../../04-security/networkpolicy/allow-same-namespace.yaml
# Pod trong default có thể gọi nhau (ingress từ podSelector {})
```

### 3.4 Backend chỉ nhận từ frontend

```bash
# Cần có Pod label app=api và Pod label app=frontend
kubectl apply -f ../../04-security/networkpolicy/example-backend-from-frontend.yaml
# Chỉ Pod app=frontend mới gọi được Pod app=api:8080
```

### 3.5 Dọn NetworkPolicy

```bash
kubectl delete networkpolicy default-deny-all allow-dns-egress allow-same-namespace example-backend-from-frontend -n default
```

---

## Dọn dẹp tổng hợp

```bash
kubectl delete namespace app-baseline app-restricted 2>/dev/null || true
kubectl delete -f ../../04-security/pod-security/pod-security-context.yaml 2>/dev/null || true
kubectl delete -f ../../04-security/networkpolicy/default-deny-all.yaml 2>/dev/null || true
kubectl delete -f ../../04-security/networkpolicy/allow-dns-egress.yaml 2>/dev/null || true
kubectl delete -f ../../04-security/networkpolicy/allow-same-namespace.yaml 2>/dev/null || true
```
