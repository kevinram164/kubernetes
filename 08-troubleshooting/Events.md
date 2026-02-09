# Events và điều tra – Phase 7

**Events** là bản ghi ngắn về thay đổi trong cluster (Pod scheduled, container started, failed, …). Dùng để điều tra **tại sao** Pod Pending, Failed, hoặc Service/Ingress không hoạt động.

---

## 1. Xem events

- **kubectl get events** – Events trong namespace hiện tại (mặc định sort theo thời gian).
- **kubectl get events -A** – Events toàn cluster.
- **kubectl get events --sort-by='.lastTimestamp'** – Sort theo thời gian mới nhất.
- **kubectl get events --field-selector type=Warning** – Chỉ events cảnh báo/lỗi.
- **kubectl get events --field-selector involvedObject.name=&lt;pod-name&gt;** – Events liên quan một Pod.

Events có **Reason** (ví dụ Failed, Scheduled, Pulled) và **Message** (mô tả ngắn). Đọc Message để biết lý do lỗi.

---

## 2. Một số Reason thường gặp

| Reason | Ý nghĩa ngắn |
|--------|----------------|
| **Scheduled** | Pod đã được schedule lên node. |
| **Pulled** | Image đã pull xong. |
| **Created** / **Started** | Container đã tạo/start. |
| **Failed** | Lỗi (thường kèm Message: OOMKilled, Error, BackOff). |
| **BackOff** | Restart backoff (CrashLoopBackOff). |
| **FailedScheduling** | Scheduler không tìm được node phù hợp (resource, node selector, taint, node không Ready). |
| **FailedMount** | Mount volume thất bại (PVC chưa Bound, secret/configmap không tồn tại). |
| **Unhealthy** | Probe (liveness/readiness) fail. |

---

## 3. Điều tra theo trạng thái Pod

### Pending

- **kubectl describe pod &lt;name&gt;** → phần Events.
- Nếu **FailedScheduling**: kiểm tra resource request (node có đủ CPU/memory?), nodeSelector, affinity, taint/toleration.
- Nếu **FailedMount**: kiểm tra PVC (get pvc), Secret/ConfigMap tồn tại, quyền (CSI, storage class).

### CrashLoopBackOff

- **kubectl logs &lt;pod&gt; --previous** – Log lần chạy trước khi crash.
- **kubectl describe pod** – Reason (OOMKilled, Error), exit code.
- Kiểm tra: command/args, env, volume mount path, securityContext (readOnlyRootFilesystem, runAsUser), resource limit (OOM).

### Running nhưng không Ready

- **kubectl describe pod** – readiness probe; có event Unhealthy không.
- **kubectl logs** – Ứng dụng có lỗi không; port health check có đúng không.
- **kubectl exec** – Curl tới port readiness từ trong Pod.

---

## 4. Điều tra Service / Ingress

- **Service không có endpoint:** get endpoints &lt;svc&gt;; get pods -l &lt;label&gt;. Đảm bảo Pod có label khớp selector của Service và Pod đang Running/Ready.
- **Ingress 502/503:** describe ingress; curl từ Pod tới ClusterIP Service; kiểm tra backend Pod ready và port đúng.

Xem thêm: [Debug.md](Debug.md), [Checklist.md](Checklist.md).
