# 04 – Security & Production (Phase 4)

Phase 4 tập trung **bảo mật và vận hành production**: RBAC, Pod Security (PSS/PSA), NetworkPolicy, và Security Context.

---

## Nội dung chuyên sâu

| Chủ đề | Mô tả | File / thư mục |
|--------|--------|----------------|
| **RBAC** | Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount, thiết kế least privilege, troubleshooting | [RBAC.md](RBAC.md), [rbac/](rbac/) |
| **Pod Security** | Pod Security Standards (privileged, baseline, restricted), Pod Security Admission, securityContext | [Pod-Security.md](Pod-Security.md), [pod-security/](pod-security/) |
| **NetworkPolicy** | Default deny/allow, ingress/egress, podSelector, namespaceSelector, ipBlock, kết hợp CNI | [NetworkPolicy.md](NetworkPolicy.md), [networkpolicy/](networkpolicy/) |

---

## Thứ tự học gợi ý

1. **RBAC** – Hiểu ai được làm gì (API server authorization).
2. **Pod Security** – Giới hạn capability và quyền của container (PSS + securityContext).
3. **NetworkPolicy** – Giới hạn traffic giữa Pod (cần CNI hỗ trợ: Calico, Cilium, …).

---

## Lưu ý môi trường

- **RBAC:** Mọi cluster K8s 1.6+ đều có; chỉ cần bật authorization mode RBAC (mặc định).
- **Pod Security Admission:** K8s 1.23+ (beta), 1.25+ stable; namespace cần gắn label PSS.
- **NetworkPolicy:** API có sẵn, nhưng **chỉ có hiệu lực khi CNI hỗ trợ** (Calico, Cilium, Weave, …). Cluster dùng CNI bridge thuần (như K8s-the-hard-way) **không** áp dụng NetworkPolicy trừ khi cài controller tương thích.

---

## Lab tổng hợp

**[labs/04-phase4-security/](../labs/04-phase4-security/)** – Thực hành RBAC, PSS, NetworkPolicy theo từng bước.
