# IAM & RBAC trên Cloud – Phase 6

Pod cần gọi **API cloud** (S3, BigQuery, Azure Blob, …). Thay vì lưu access key trong Secret, dùng **IAM gắn với ServiceAccount**: Pod dùng SA → cloud nhận diện identity và cấp quyền theo IAM.

---

## 1. Cơ chế theo từng cloud

| Cloud | Cơ chế | Ghi chú |
|-------|--------|--------|
| **EKS** | **IRSA** (IAM Role for Service Account) | SA có annotation `eks.amazonaws.com/role-arn`; Pod dùng SA → assume IAM Role, nhận temporary credential. |
| **GKE** | **Workload Identity** | SA K8s gắn với GCP Service Account; Pod dùng SA → GCP SA, không cần key. |
| **AKS** | **Workload Identity** (AAD) | SA K8s gắn với Azure AD identity; Pod dùng SA → federated credential. |

---

## 2. EKS – IRSA

### Bước 1: Tạo IAM Role (trust policy cho OIDC EKS)

- EKS cluster có OIDC provider (URL issuer).
- IAM Role có trust policy: principal = OIDC provider, condition = `StringEquals` với `sub` = `system:serviceaccount:<namespace>:<sa-name>`.

### Bước 2: Gắn SA với Role

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/MyRole
```

### Bước 3: Pod dùng SA

```yaml
spec:
  serviceAccountName: my-sa
```

Pod gọi AWS API (SDK, CLI) sẽ tự nhận credential từ IRSA (không cần env AWS_ACCESS_KEY_ID).

Tài liệu: [EKS IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

---

## 3. GKE – Workload Identity

### Bước 1: Bật Workload Identity trên cluster và node pool

```bash
gcloud container clusters update mycluster --workload-pool=PROJECT_ID.svc.id.goog
```

### Bước 2: GCP Service Account + IAM binding

- Tạo GCP SA, gán IAM (ví dụ Storage Object Viewer).
- Cho phép SA K8s assume GCP SA: `gcloud iam service-accounts add-iam-policy-binding GCP_SA@PROJECT.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:PROJECT.svc.id.goog[NAMESPACE/K8S_SA]"`.

### Bước 3: Annotation trên SA K8s

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: GCP_SA@PROJECT.iam.gserviceaccount.com
```

Pod dùng SA này gọi GCP API sẽ dùng identity của GCP SA.

Tài liệu: [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).

---

## 4. AKS – Workload Identity

- Bật Workload Identity (Azure AD).
- Tạo User-Assigned Managed Identity, gán quyền (ví dụ Storage Blob Data Contributor).
- Federated credential: issuer AKS OIDC, subject `system:serviceaccount:<namespace>:<sa-name>`.
- SA K8s annotation: `azure.workload.identity.io/client-id: <managed-identity-client-id>`.
- Pod dùng SA này gọi Azure API (DefaultAzureCredential) sẽ dùng Managed Identity.

Tài liệu: [AKS Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview).

---

## 5. Tóm tắt

- **On-prem**: Pod gọi cloud API thường dùng Secret chứa access key (kém an toàn hơn).
- **Cloud managed K8s**: Dùng IRSA / Workload Identity để Pod nhận credential tạm thời hoặc federated, không lưu key trong cluster.
