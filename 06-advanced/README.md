# 06 – Advanced (Phase 5)

Phase 5 tập trung **tooling nâng cao**: Helm, Kustomize, Operators & CRD, GitOps (Argo CD / Flux).

---

## Nội dung

| Chủ đề | Mô tả | File / thư mục |
|--------|--------|----------------|
| **Helm** | Package manager cho K8s: chart, values, install/upgrade/rollback | [Helm.md](Helm.md), [helm/](helm/) |
| **Kustomize** | Overlay base + patch (namespace, replica, image) không sửa YAML gốc | [Kustomize.md](Kustomize.md), [kustomize/](kustomize/) |
| **Operators & CRD** | Custom Resource Definition, controller, Operator pattern | [Operators-CRD.md](Operators-CRD.md), [crd-example/](crd-example/) |
| **GitOps** | Argo CD / Flux: sync cluster từ Git repo | [GitOps.md](GitOps.md), [gitops/](gitops/) |

---

## Thứ tự học gợi ý

1. **Kustomize** – Đơn giản, tích hợp `kubectl apply -k`; dùng để quản lý nhiều môi trường (dev/staging/prod).
2. **Helm** – Chart có sẵn (ingress-nginx, cert-manager, …); tạo chart cho app của bạn.
3. **GitOps** – Argo CD hoặc Flux: repo Git là source of truth, cluster tự sync.
4. **Operators & CRD** – Khi cần resource tự viết và controller (database, middleware).

Lab tổng hợp: **[labs/05-phase5-advanced/](../labs/05-phase5-advanced/)**.
