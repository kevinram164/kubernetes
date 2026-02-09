# Debug cơ bản – Phase 7

Các lệnh và cách dùng khi **Pod/Deployment/Service** lỗi.

---

## 1. describe

- **kubectl describe pod &lt;name&gt;** – Trạng thái, events, container state (Waiting/Running/Terminated), reason (Error, OOMKilled, …).
- **kubectl describe deployment &lt;name&gt;** – Replicas, events (scale, rollout).
- **kubectl describe service &lt;name&gt;** – Endpoints (danh sách Pod backend); nếu Endpoints rỗng = selector không khớp Pod.
- **kubectl describe node &lt;name&gt;** – Tài nguyên (allocatable, capacity), điều kiện (Ready, MemoryPressure, DiskPressure), Pod list.

Dùng **describe** trước để nắm events và lý do lỗi.

---

## 2. logs

- **kubectl logs &lt;pod&gt;** – Log container chính (stdout/stderr).
- **kubectl logs &lt;pod&gt; -c &lt;container&gt;** – Log container cụ thể (Pod có nhiều container).
- **kubectl logs &lt;pod&gt; --previous** – Log container trước khi restart (sau CrashLoopBackOff).
- **kubectl logs -f &lt;pod&gt;** – Follow (stream) log.
- **kubectl logs &lt;pod&gt; --all-containers=true** – Log tất cả container trong Pod.

Init container lỗi: xem log init container bằng **-c &lt;init-container-name&gt;** (nếu Pod còn tồn tại) hoặc **describe** để xem event.

---

## 3. exec

- **kubectl exec -it &lt;pod&gt; -- /bin/sh** (hoặc **/bin/bash**) – Shell vào container (container phải có shell).
- **kubectl exec &lt;pod&gt; -- env** – Xem biến môi trường.
- **kubectl exec &lt;pod&gt; -- cat /etc/resolv.conf** – Kiểm tra DNS trong Pod.

Dùng khi cần kiểm tra file, process, network từ trong container.

---

## 4. kubectl debug

- **kubectl debug &lt;pod&gt; -it --image=busybox --target=&lt;container&gt;** – Tạo Pod debug ephemeral, attach vào namespace của container (K8s 1.18+).
- **kubectl debug node/&lt;node&gt; -it --image=ubuntu** – Chạy Pod trên node với host PID/filesystem (kiểm tra node).

Dùng khi container không có shell hoặc cần debug ở cấp node.

---

## 5. Kiểm tra nhanh

| Triệu chứng | Lệnh / hướng kiểm tra |
|-------------|------------------------|
| Pod Pending | describe pod → events (thường: không schedule được: resource, node selector, taint); describe node. |
| Pod CrashLoopBackOff | describe pod → events; logs --previous; kiểm tra image, command, probe, OOM. |
| Pod Running nhưng không ready | describe pod → readiness probe; logs; exec kiểm tra port/health. |
| Service không kết nối | describe svc → Endpoints (rỗng = selector sai); get pods -l &lt;label&gt;; get endpoints. |
| Ingress 502/503 | describe ingress; curl từ Pod tới Service; kiểm tra backend Pod ready. |

Xem thêm: [Events.md](Events.md), [Checklist.md](Checklist.md).
