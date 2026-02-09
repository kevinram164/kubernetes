# NetworkPolicy – Chuyên sâu

**NetworkPolicy** là API resource để giới hạn **traffic mạng** giữa Pod (ingress/egress). API có sẵn trên mọi cluster, nhưng **chỉ có hiệu lực khi CNI hỗ trợ** (Calico, Cilium, Weave, …). Cluster dùng CNI bridge thuần (như K8s-the-hard-way) **không** áp dụng NetworkPolicy trừ khi cài controller tương thích.

---

## 1. Mô hình: Default allow vs default deny

| Mô hình | Hành vi khi không có NetworkPolicy |
|--------|------------------------------------|
| **Default allow** | Mọi Pod có thể gửi/nhận traffic tới mọi Pod (và ra ngoài). Thêm NetworkPolicy = **whitelist**: chỉ traffic khớp policy mới được phép. |
| **Default deny** | Mọi traffic bị chặn. Thêm NetworkPolicy = **mở** từng luồng cần thiết. |

Hầu hết CNI: **default allow**. Để “default deny” trong namespace: tạo NetworkPolicy **empty** (ingress/egress rỗng) chọn tất cả Pod → chặn hết; sau đó thêm policy cho phép từng luồng.

---

## 2. Cấu trúc NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: example
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from: [...]
      ports: [...]
  egress:
    - to: [...]
      ports: [...]
```

- **podSelector:** Chọn Pod **chịu ảnh hưởng** policy (policy áp dụng cho Pod khớp label).
- **policyTypes:** Chỉ định loại rule: **Ingress** (vào Pod), **Egress** (ra từ Pod). Nếu chỉ có `ingress` thì mặc định chỉ Ingress; có `egress` thì cần khai báo `policyTypes: [Ingress, Egress]` nếu muốn áp dụng cả hai.
- **ingress / egress:** Danh sách rule; mỗi rule có **from** (ingress) hoặc **to** (egress) và **ports** (tùy chọn).

---

## 3. Chọn nguồn/đích: from / to

| Thành phần | Ý nghĩa | Ví dụ |
|------------|--------|--------|
| **podSelector** | Pod trong **cùng namespace** khớp label. | `podSelector: matchLabels: app: frontend` |
| **namespaceSelector** | Mọi Pod trong namespace khớp label. | `namespaceSelector: matchLabels: name: ingress` |
| **ipBlock** | CIDR (IP range). | `ipBlock: cidr: 10.0.0.0/8`; có thể `except`. |
| **Kết hợp** | Một block `from`/`to` có nhiều điều kiện = **OR**; nhiều block = **OR**. Trong một block, podSelector + namespaceSelector = **AND** (Pod vừa khớp label vừa trong namespace). | |

**Lưu ý:** `from`/`to` có thể có nhiều phần tử; traffic khớp **bất kỳ** phần tử nào là được phép (OR).

---

## 4. Ports

- **ports:** Danh sách `port` (number hoặc name) và `protocol` (TCP/UDP). Nếu bỏ ports = cho phép **mọi port** (theo hướng ingress/egress đó).
- Egress tới **DNS (CoreDNS):** Thường cho phép egress tới port 53 UDP/TCP tới namespace `kube-system` (hoặc nơi chạy CoreDNS) để Pod resolve tên.

---

## 5. Một số pattern thường gặp

| Mục đích | Cách làm |
|----------|----------|
| **Default deny toàn namespace** | NetworkPolicy: `podSelector: {}` (chọn tất cả Pod), `ingress: []`, `egress: []` (hoặc chỉ egress DNS). |
| **Chỉ cho phép ingress từ Pod cùng namespace** | `ingress.from.podSelector: {}` (trong namespace). |
| **Chỉ cho phép ingress từ Ingress controller** | `ingress.from.namespaceSelector: matchLabels: name: ingress-nginx` (hoặc podSelector trỏ tới Pod ingress). |
| **Cho phép egress ra internet (HTTPS)** | `egress.to.ipBlock: cidr: 0.0.0.0/0; except: [10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16]` (tránh private IP) + ports 443. |
| **Cho phép egress DNS** | Egress tới namespace `kube-system` (hoặc namespace CoreDNS), port 53 UDP/TCP. |
| **Backend chỉ nhận từ frontend** | NetworkPolicy trên backend: ingress từ `podSelector: matchLabels: app: frontend`. |

---

## 6. Thứ tự và tương tác nhiều policy

- Nhiều NetworkPolicy **cùng chọn một Pod**: rule được **cộng** (OR). Traffic được phép nếu khớp **bất kỳ** policy nào.
- Để “default deny” rồi mở từng luồng: một policy **deny all** (empty ingress/egress) + policy **allow** từng luồng; allow sẽ cộng nên traffic khớp allow vẫn đi.

---

## 7. Ví dụ YAML và lệnh

Xem thư mục **[networkpolicy/](networkpolicy/)**:

- `default-deny-all.yaml` – Chặn mọi ingress/egress (trừ khi có policy khác mở).
- `allow-same-namespace.yaml` – Cho phép ingress từ Pod cùng namespace.
- `allow-dns-egress.yaml` – Cho phép egress DNS (port 53) tới kube-system.
- `allow-from-ingress.yaml` – Cho phép ingress từ namespace ingress-nginx.
- `example-backend-from-frontend.yaml` – Backend chỉ nhận từ Pod có label app=frontend.

Lab: **[labs/04-phase4-security/](../labs/04-phase4-security/)** (phần NetworkPolicy).

**Lưu ý:** Trên cluster không có CNI hỗ trợ NetworkPolicy, apply YAML vẫn thành công nhưng **không có tác dụng**; cần cài Calico/Cilium hoặc controller tương thích.
