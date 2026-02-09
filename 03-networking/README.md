# 03 – Networking (Phase 2: Ingress)

Phase 2 bổ sung **Ingress** – routing HTTP/HTTPS vào các Service trong cluster.

---

## Ingress là gì?

- **Ingress** = API resource để mô tả cách route traffic từ bên ngoài (HTTP/HTTPS) vào **Service** trong cluster.
- **Ingress controller** = thành phần thực thi: đọc Ingress, cấu hình reverse proxy (Nginx, Traefik, …) và nhận traffic (thường qua LoadBalancer hoặc NodePort).

**Lưu ý:** Chỉ tạo Ingress resource **chưa đủ** – cluster phải có **Ingress controller** đã cài (ví dụ ingress-nginx, Traefik).

---

## Cài Ingress controller (ví dụ: ingress-nginx)

```bash
# Ví dụ: ingress-nginx qua kubectl
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.0/deploy/static/provider/baremetal/deploy.yaml

# Hoặc Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.type=NodePort
```

Sau khi controller Running, tạo **Ingress** resource trỏ tới Service của bạn.

---

## Ingress – ví dụ

- **Host-based:** Route theo hostname (`app.example.com` → Service A, `api.example.com` → Service B).
- **Path-based:** Route theo path (`/web` → Service web, `/api` → Service api).
- **TLS:** Chỉ định `secret` chứa certificate để bật HTTPS.

Xem: `ingress-example.yaml`, `ingress-tls-example.yaml`.

---

## Thực hành

```bash
# Áp dụng Ingress (đã có Deployment + Service tương ứng)
kubectl apply -f ingress-example.yaml
kubectl get ingress
kubectl describe ingress <name>
```

Truy cập: nếu controller dùng NodePort, gọi `http://<NodeIP>:<NodePort>` và set header `Host` theo host trong Ingress; hoặc thêm `/etc/hosts` trỏ domain tới NodeIP.

---

## Các chủ đề khác (Phase 4)

- **NetworkPolicy** – giới hạn traffic giữa Pod (xem 04-security hoặc mở rộng 03-networking).
- **DNS** – CoreDNS, `svc.namespace.svc.cluster.local` (cluster tự có khi đã chạy).
