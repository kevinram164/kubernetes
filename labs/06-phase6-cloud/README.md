# Lab 06: Phase 6 – Cloud (EKS / GKE / AKS)

**Mục tiêu:** Tạo managed cluster, deploy workload, (tùy chọn) IAM, PVC, LoadBalancer/Ingress.

**Yêu cầu:** Tài khoản AWS / GCP / Azure, CLI (aws, gcloud, az) đã cấu hình.

---

## Phần 1: Tạo cluster (chọn một cloud)

### EKS

```bash
eksctl create cluster --name phase6-demo --region ap-southeast-1 --nodegroup-name ng1 --node-type t3.medium --nodes 2
aws eks update-kubeconfig --name phase6-demo --region ap-southeast-1
kubectl get nodes
```

### GKE

```bash
gcloud container clusters create phase6-demo --zone asia-southeast1-a --num-nodes 2
gcloud container clusters get-credentials phase6-demo --zone asia-southeast1-a
kubectl get nodes
```

### AKS

```bash
az group create --name phase6-rg --location southeastasia
az aks create --resource-group phase6-rg --name phase6-demo --node-count 2
az aks get-credentials --resource-group phase6-rg --name phase6-demo
kubectl get nodes
```

---

## Phần 2: Deploy workload (giống on-prem)

```bash
kubectl apply -f ../../01-fundamentals/deployment-example.yaml
kubectl get pods,svc
kubectl apply -f ../../01-fundamentals/service-loadbalancer.yaml
kubectl get svc nginx-loadbalancer
# Chờ EXTERNAL-IP (cloud LB); curl <EXTERNAL-IP>
```

---

## Phần 3: PVC (dynamic provisioning)

```bash
kubectl get storageclass
# Tạo PVC không chỉ định storageClassName (dùng default của cloud)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
EOF
kubectl get pvc
# Gắn PVC vào Deployment (xem 02-config-storage/deployment-with-pvc.yaml)
```

---

## Phần 4: IAM (EKS IRSA / GKE Workload Identity – tùy chọn)

- **EKS:** Tạo IAM Role + OIDC trust, annotation SA, Pod dùng SA và gọi AWS CLI/SDK (S3 list).
- **GKE:** Bật Workload Identity, tạo GCP SA, bind SA K8s với GCP SA, Pod gọi gcloud/storage.

Chi tiết từng bước: xem [07-cloud/IAM-RBAC.md](../../07-cloud/IAM-RBAC.md).

---

## Dọn dẹp

```bash
# Xóa workload
kubectl delete -f ../../01-fundamentals/deployment-example.yaml
kubectl delete -f ../../01-fundamentals/service-loadbalancer.yaml
kubectl delete pvc demo-pvc

# Xóa cluster
# EKS: eksctl delete cluster --name phase6-demo --region ap-southeast-1
# GKE: gcloud container clusters delete phase6-demo --zone asia-southeast1-a
# AKS: az aks delete --resource-group phase6-rg --name phase6-demo; az group delete --name phase6-rg
```
