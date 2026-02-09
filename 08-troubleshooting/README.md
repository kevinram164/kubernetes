# 08 – Troubleshooting (Phase 7)

Phase 7 tập trung **debug và vận hành**: kubectl debug, events, logs, describe, checklist khi Pod/Deployment/Service lỗi.

---

## Nội dung

| Chủ đề | Mô tả | File |
|--------|--------|------|
| **Debug cơ bản** | describe, logs, exec, events | [Debug.md](Debug.md) |
| **Events và điều tra** | kubectl get events, sort-by, filter; điều tra Pending, CrashLoopBackOff | [Events.md](Events.md) |
| **Checklist và best practices** | Checklist khi Pod không chạy, Service không kết nối, Ingress không vào | [Checklist.md](Checklist.md) |

---

## Thứ tự dùng

1. **Pod không Running:** describe pod → events → logs (init/container) → kiểm tra image, resource, probe, securityContext.
2. **Service không kết nối:** describe svc → endpoints → pod selector và label → network policy.
3. **Ingress không vào:** describe ingress → controller, backend, TLS → curl từ trong cluster.

Lab: **[labs/07-phase7-troubleshooting/](../labs/07-phase7-troubleshooting/)**.
