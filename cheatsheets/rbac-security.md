# RBAC & Security Cheatsheet

## RBAC

```bash
# Liệt kê Role, RoleBinding trong namespace
kubectl get role,rolebinding -n <namespace>

# Liệt kê ClusterRole, ClusterRoleBinding
kubectl get clusterrole,clusterrolebinding

# Xem chi tiết Role / ClusterRole
kubectl get role <name> -n <ns> -o yaml
kubectl get clusterrole <name> -o yaml

# Xem RoleBinding và subject
kubectl get rolebinding -n <ns> -o wide
kubectl describe rolebinding <name> -n <ns>

# Tạo ServiceAccount
kubectl create serviceaccount <name> -n <namespace>

# Kiểm tra quyền (auth can-i)
kubectl auth can-i get pods --as=system:serviceaccount:default:reader -n default
kubectl auth can-i create deployments --as=system:serviceaccount:default:deploy-bot -n default

# Liệt kê quyền của user/SA (kubectl-auth không có sẵn, dùng can-i lặp hoặc tool bên ngoài)
for verb in get list watch create update patch delete; do
  kubectl auth can-i $verb pods --as=system:serviceaccount:default:reader -n default
done
```

## Pod Security (namespace labels)

```bash
# Xem label PSS trên namespace
kubectl get ns <name> -o jsonpath='{.metadata.labels}' | jq

# Gắn label enforce baseline
kubectl label namespace <ns> pod-security.kubernetes.io/enforce=baseline --overwrite
```

## NetworkPolicy

```bash
# Liệt kê NetworkPolicy
kubectl get networkpolicy -n <namespace>
kubectl get netpol -n <namespace>

# Xem chi tiết
kubectl describe networkpolicy <name> -n <namespace>
```
