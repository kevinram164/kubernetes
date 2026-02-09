# GitOps – Phase 5

**GitOps**: Git repo là **source of truth** cho trạng thái cluster; tool (Argo CD, Flux) **sync** cluster theo manifest trong Git (branch/tag, path).

---

## 1. Nguyên tắc

- **Declarative**: Mô tả desired state trong Git (YAML, Helm, Kustomize).
- **Sync**: Tool so sánh cluster với Git và apply thay đổi (auto hoặc manual).
- **Rollback**: Đổi Git (revert commit, đổi branch) rồi sync lại.

---

## 2. Argo CD

- **Application** = một repo (hoặc Helm chart) + path + cluster + namespace.
- UI + CLI: xem sync status, diff, sync, rollback.
- Cài: `kubectl create namespace argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`.

```bash
# Login (lấy password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login <server>
argocd app create myapp --repo https://github.com/user/repo --path kustomize/overlays/prod --dest-server https://kubernetes.default.svc --dest-namespace prod
argocd app sync myapp
argocd app list
```

---

## 3. Flux

- **GitOps toolkit**: Flux đọc Git (và Helm repo, OCI) và reconcile cluster (Kustomize, Helm, raw YAML).
- Cài: `flux bootstrap github --owner=user --repo=repo --path=clusters/prod`.
- Không có UI mặc định (có Flux Dashboard hoặc dùng Grafana).

```bash
flux get kustomizations
flux reconcile source git flux-system
flux reconcile kustomization myapp
```

---

## 4. So sánh nhanh

| | Argo CD | Flux |
|---|---------|------|
| **UI** | Có sẵn | Cần add-on |
| **Cài** | Manifest / Helm | flux bootstrap (ghi vào Git) |
| **Sync** | Pull (Argo CD hỏi Git) | Push (Flux chạy trong cluster, pull Git) |

Cả hai đều hỗ trợ Kustomize, Helm, raw manifest.

---

## 5. Ví dụ và lab

- **gitops/** – Cấu trúc repo mẫu (thư mục app, overlays), link cài Argo CD / Flux.
- Lab: **[labs/05-phase5-advanced/](../labs/05-phase5-advanced/)** (phần GitOps – cài Argo CD, tạo Application trỏ repo).

Tài liệu: [Argo CD](https://argo-cd.readthedocs.io/), [Flux](https://fluxcd.io/docs/).
