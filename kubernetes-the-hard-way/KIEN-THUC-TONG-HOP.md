# Tổng hợp kiến thức – Kubernetes The Hard Way

File tham chiếu nhanh sau khi dựng xong cluster. Dùng khi ôn lại hoặc khi chuyển sang Cilium.

---

## 1. Thông tin máy và hostname

| Máy của bạn | IP | Hostname trong tutorial | Vai trò |
|-------------|-----|--------------------------|--------|
| jumpbox | 192.168.1.10 | jumpbox | Máy làm việc (chạy lệnh, kubectl) |
| master | 192.168.1.11 | **server**, server.kubernetes.local | Control plane (etcd, API server, scheduler, controller-manager) |
| worker01 | 192.168.1.12 | **node-0** | Worker 1 |
| worker02 | 192.168.1.13 | **node-1** | Worker 2 |

Tutorial dùng hostname **server**, **node-0**, **node-1** trong certificate và config; không đổi thành master/worker01/worker02 trong cert.

---

## 2. Các dải IP trong cluster

| Mục đích | Dải | Ghi chú |
|----------|-----|--------|
| **IP máy (host)** | 192.168.1.10 – 192.168.1.13 | IP vật lý của 4 máy |
| **Pod (CNI cấp)** | **10.200.0.0/24** (node-0), **10.200.1.0/24** (node-1) | Mỗi node một /24; Pod nhận IP từ dải này |
| **Service (ClusterIP)** | 10.32.0.0/24 hoặc 10.96.0.0/12 | Do API server/controller-manager; dùng cho Service |

**Pod CIDR (10.200.x.0/24):**

- Là dải IP **private** (RFC 1918), chỉ dùng **trong cluster** cho Pod.
- Mỗi node được gán một subnet riêng để không trùng IP và để cluster biết route: 10.200.0.x → node-0 (192.168.1.12), 10.200.1.x → node-1 (192.168.1.13).

---

## 3. CNI trong K8s-the-hard-way

- **Không** dùng Cilium hay Calico.
- Dùng **reference CNI plugins** từ [containernetworking/plugins](https://github.com/containernetworking/plugins):
  - **Bridge** – plugin chính: tạo bridge, gán IP Pod theo subnet (10.200.x.0/24).
  - **Loopback** – loopback trong container.
- File tải: `cni-plugins-linux-amd64-v1.6.2.tgz` (hoặc arm64).
- Cấu hình: `10-bridge.conf` (subnet = SUBNET từ machines.txt), `99-loopback.conf`.

CNI này dùng **đúng** dải Pod 10.200.0.0/24 và 10.200.1.0/24 đã khai báo trong `machines.txt`.

---

## 4. VXLAN vs Direct routing (khi chuyển sang Cilium)

**Vấn đề:** Pod trên node-0 (10.200.0.x) cần nói chuyện với Pod trên node-1 (10.200.1.x); hai dải không cùng mạng vật lý (192.168.1.x).

| | **Direct routing** | **VXLAN** |
|---|-------------------|-----------|
| **Ý tưởng** | Mạng vật lý có route tới từng dải Pod (10.200.x.0/24); gói đi trực tiếp qua IP node. | Gói Pod được bọc (encapsulate) trong UDP, đích = IP node; tạo “mạng ảo” trên nền 192.168.1.x. |
| **Cần route 10.200.x.0/24?** | **Có** – giống Lab 10 (route 10.200.0.0/24 → 192.168.1.12, 10.200.1.0/24 → 192.168.1.13). | **Không** – chỉ cần các node ping được nhau qua 192.168.1.x. |
| **Ưu** | Ít overhead, hiệu năng tốt. | Không cần cấu hình route Pod trên hạ tầng; dùng tốt trên cloud. |
| **Nhược** | Phải cấu hình route (tĩnh/BGP) trên mạng. | Tốn thêm băng thông và CPU (encapsulation). |

Sau khi cài Cilium: chọn **tunnel: vxlan** hoặc **tunnel: disabled** (direct routing) tùy môi trường.

---

## 5. Chuyển sang Cilium sau khi dựng xong

### 5.1 Chuẩn bị

- Cluster K8s-the-hard-way đã chạy ổn (smoke test OK).
- `kubectl` từ jumpbox trỏ đúng cluster.

### 5.2 Cài Cilium

Trên **jumpbox**, cài theo [tài liệu Cilium](https://docs.cilium.io/en/stable/installation/k8s-install-default/), ví dụ bằng Helm:

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --namespace kube-system
```

Hoặc dùng manifest (xem trang install của Cilium). Có thể chỉnh thêm:

- **tunnel: vxlan** – không cần route Pod (Lab 10 có thể bỏ).
- **tunnel: disabled** + **autoDirectNodeRoutes: true** – direct routing; vẫn cần route 10.200.0.0/24, 10.200.1.0/24 (giống hiện tại).

### 5.3 Gỡ CNI cũ (bridge)

Trên **từng worker** (node-0, node-1):

```bash
# Đăng nhập worker (ssh root@node-0 / ssh root@node-1)
mv /etc/cni/net.d/10-bridge.conf /etc/cni/net.d/10-bridge.conf.bak
# Hoặc xóa: rm /etc/cni/net.d/10-bridge.conf
systemctl restart kubelet
```

Cilium sẽ tạo config trong `/etc/cni/net.d/` (hoặc dùng Cilium operator). Sau khi Cilium Ready, Pod sẽ dùng Cilium.

### 5.4 Kiểm tra

```bash
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl get nodes
# Tạo Pod test, ping giữa Pod trên 2 node.
```

### 5.5 Lưu ý

- **Pod CIDR:** Cilium có thể dùng lại 10.200.0.0/24, 10.200.1.0/24 hoặc cấu hình dải khác tùy chế độ.
- **Route (Lab 10):** Nếu dùng **direct routing**, giữ route 10.200.0.0/24 và 10.200.1.0/24. Nếu dùng **VXLAN**, có thể bỏ route đó.
- Sau khi lên Cilium có thể bật thêm: NetworkPolicy, Hubble, service mesh.

---

## 6. File và thư mục quan trọng (ôn nhanh)

| Nội dung | Vị trí / file |
|----------|----------------|
| Danh sách máy | `machines.txt` (trên jumpbox, thư mục repo) |
| Hướng dẫn từng bước | `STEP-BY-STEP.md` |
| Certificate, kubeconfig | Tạo trên jumpbox (thư mục repo); copy sang server / node-0 / node-1 theo từng lab |
| CNI config (bridge) | `/etc/cni/net.d/10-bridge.conf`, `99-loopback.conf` trên mỗi worker |
| Binary CNI | `/opt/cni/bin/` trên mỗi worker |
| Route Pod (Lab 10) | Trên server: 10.200.0.0/24 via 192.168.1.12; 10.200.1.0/24 via 192.168.1.13 |

---

## 7. Tóm tắt một dòng

- **Máy:** jumpbox 192.168.1.10, server 192.168.1.11, node-0 192.168.1.12, node-1 192.168.1.13.
- **Pod IP:** 10.200.0.0/24 (node-0), 10.200.1.0/24 (node-1); CNI (bridge) dùng đúng hai dải này.
- **CNI hiện tại:** containernetworking/plugins (bridge + loopback), không phải Cilium/Calico.
- **Sau khi xong:** Cài Cilium → gỡ cấu hình bridge → restart kubelet; chọn VXLAN (không cần route Pod) hoặc direct routing (giữ route Lab 10).

Chúc bạn dựng cluster và chuyển sang Cilium thuận lợi.
