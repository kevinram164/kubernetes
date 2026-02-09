# Pod Security – Chuyên sâu

Phase 4 bổ sung hai lớp: **Security Context** (quyền và capability của container) và **Pod Security Standards / Pod Security Admission** (chính sách cluster cho Pod).

---

## 1. Security Context (Pod và Container)

**Security context** giới hạn cách Pod/container chạy: user/group, filesystem, capability, privilege.

### 1.1 Cấp Pod vs cấp Container

| Cấp | Một số field quan trọng | Ghi chú |
|-----|-------------------------|--------|
| **Pod (spec.securityContext)** | `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `seccompProfile` | Áp dụng cho tất cả container trong Pod; một số field có thể bị override ở container. |
| **Container (spec.containers[].securityContext)** | `runAsNonRoot`, `runAsUser`, `runAsGroup`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`, `capabilities` | Override cho từng container. |

### 1.2 Các field quan trọng

| Field | Ý nghĩa | Ví dụ |
|-------|--------|--------|
| **runAsNonRoot** | true = không chạy UID 0 (root). | Giảm rủi ro khi bị compromise. |
| **runAsUser** / **runAsGroup** | UID/GID chạy process trong container. | Ví dụ 1000, 1000. |
| **fsGroup** | GID cho volume mount; quyền ghi file theo group. | Volume mount có group = fsGroup. |
| **readOnlyRootFilesystem** | Root filesystem chỉ đọc; ghi vào /tmp hoặc volume. | Hạn chế malware ghi hệ thống. |
| **allowPrivilegeEscalation** | false = process không leo quyền (setuid, …). | Nên false nếu không cần. |
| **capabilities** | Thêm/bớt Linux capabilities (NET_BIND_SERVICE, …). | Bỏ ALL, thêm từng cap cần thiết. |
| **seccompProfile** | Profile seccomp (RuntimeDefault, Unconfined, hoặc custom). | Giới hạn syscall. |

### 1.3 Thiết kế an toàn

- **runAsNonRoot: true** + **runAsUser** (non-zero) cho workload thường.
- **readOnlyRootFilesystem: true** nếu app không cần ghi root; ghi vào emptyDir hoặc PVC.
- **allowPrivilegeEscalation: false**.
- **capabilities:** Mặc định drop ALL, add chỉ những cap cần (ví dụ NET_BIND_SERVICE cho bind port < 1024).

---

## 2. Pod Security Standards (PSS)

PSS là **ba mức chính sách** do Kubernetes định nghĩa:

| Level | Mô tả ngắn |
|-------|------------|
| **privileged** | Không giới hạn; dùng cho system workload (node agent, CNI). |
| **baseline** | Giới hạn tối thiểu: không host namespace, không privilege escalation, không chạy root (có ngoại lệ). |
| **restricted** | Chặt hơn baseline: runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities, … |

Chi tiết từng control: [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/).

### 2.1 Áp dụng PSS: Pod Security Admission (PSA)

Từ K8s 1.23+ (beta), 1.25+ stable: **Pod Security Admission** dùng label trên **namespace** để quyết định Pod nào được tạo:

| Label | Ý nghĩa |
|-------|--------|
| **pod-security.kubernetes.io/enforce** | Chế độ **enforce**: Pod không đạt level bị **từ chối**. |
| **pod-security.kubernetes.io/audit** | Chế độ **audit**: Pod không đạt level bị ghi log (audit log). |
| **pod-security.kubernetes.io/warn** | Chế độ **warn**: Cảnh báo khi tạo Pod không đạt level. |

Giá trị label: `privileged`, `baseline`, `restricted`.

Ví dụ namespace **enforce restricted**:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

Pod tạo trong `app-prod` phải thỏa **restricted** (runAsNonRoot, readOnlyRootFilesystem, …) nếu không sẽ bị reject.

### 2.2 Migrate namespace lên PSS

- Bắt đầu với **warn** hoặc **audit** (baseline/restricted) để phát hiện Pod vi phạm.
- Sửa workload (securityContext) cho đúng level.
- Sau đó chuyển sang **enforce** (baseline rồi restricted nếu có thể).

---

## 3. Ví dụ YAML và lệnh

Xem thư mục **[pod-security/](pod-security/)**:

- `namespace-baseline.yaml` – Namespace enforce baseline.
- `namespace-restricted.yaml` – Namespace enforce restricted.
- `pod-security-context.yaml` – Pod với runAsNonRoot, readOnlyRootFilesystem, allowPrivilegeEscalation: false.
- `deployment-restricted.yaml` – Deployment thỏa PSS restricted.

Lab: **[labs/04-phase4-security/](../labs/04-phase4-security/)** (phần Pod Security).
