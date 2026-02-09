# Checklist và best practices – Phase 7

Checklist nhanh khi **Pod không chạy**, **Service không kết nối**, **Ingress không vào**; và một số best practices vận hành.

---

## 1. Pod không Running / không Ready

- [ ] **kubectl describe pod &lt;name&gt;** – Đọc Events (FailedScheduling, FailedMount, BackOff, Unhealthy).
- [ ] **kubectl get events** – Events gần đây trong namespace.
- [ ] Image tồn tại và pull được? (ImagePullBackOff → image name, tag, pull secret.)
- [ ] Resource request/limit: node có đủ CPU/memory? (kubectl describe node.)
- [ ] PVC: **kubectl get pvc** – PVC Bound chưa? (Pending → StorageClass, capacity.)
- [ ] Secret/ConfigMap được tham chiếu có tồn tại không?
- [ ] Init container: log init container (kubectl logs &lt;pod&gt; -c &lt;init-container&gt;) hoặc describe.
- [ ] Liveness/readiness probe: path và port đúng? (exec vào Pod, curl localhost:port/path.)
- [ ] securityContext: runAsNonRoot, readOnlyRootFilesystem có gây lỗi không? (PSS enforce.)
- [ ] **kubectl logs &lt;pod&gt; --previous** nếu CrashLoopBackOff.

---

## 2. Service không kết nối được

- [ ] **kubectl get endpoints &lt;svc&gt;** – Có địa chỉ Pod không? (Rỗng = selector không khớp Pod.)
- [ ] **kubectl get pods -l &lt;label&gt;** – Pod có đúng label với Service selector không?
- [ ] Pod đang Running và Ready? (readiness probe pass.)
- [ ] Port: Service **targetPort** có trùng **containerPort** (hoặc port ứng dụng listen) không?
- [ ] NetworkPolicy: có policy chặn traffic tới Pod/Service không? (get networkpolicy.)

---

## 3. Ingress không vào / 502 / 503

- [ ] Ingress controller đã cài và Running? (get pods -n ingress-nginx hoặc namespace controller.)
- [ ] **kubectl describe ingress &lt;name&gt;** – Backend Service có đúng không? (Admitted, backend.)
- [ ] Service backend có endpoint không? (get endpoints.)
- [ ] Pod backend Ready và trả 200 cho path Ingress trỏ tới?
- [ ] TLS: Secret cert có tồn tại và đúng namespace không?
- [ ] Curl từ **trong cluster** (Pod) tới Service: curl http://&lt;svc&gt;.&lt;ns&gt;.svc.cluster.local.

---

## 4. Best practices vận hành

- **Resource:** Đặt request/limit cho Pod để tránh OOM và giúp scheduler đúng.
- **Probe:** Bật liveness và readiness; startupProbe nếu app khởi động chậm.
- **Log:** Chuẩn hóa log (stdout/stderr); dùng sidecar hoặc DaemonSet thu thập log nếu cần.
- **RBAC:** Least privilege cho ServiceAccount; tránh cluster-admin trừ khi cần.
- **NetworkPolicy:** Default deny trong namespace nhạy cảm; mở từng luồng cần thiết.
- **Backup:** etcd backup (control plane); backup dữ liệu ứng dụng (volume snapshot, DB backup).
- **Monitoring:** Metrics (Prometheus), alert (khi Pod crash, node NotReady); dashboard (Grafana).

---

## 5. Cheatsheet lệnh

Xem **[cheatsheets/kubectl.md](../cheatsheets/kubectl.md)** và **[cheatsheets/rbac-security.md](../cheatsheets/rbac-security.md)**.
