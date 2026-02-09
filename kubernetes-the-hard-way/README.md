# Kubernetes The Hard Way – Hướng dẫn học

Tutorial gốc: **[kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)**

Bạn sẽ **tự tay** dựng một cluster Kubernetes (không dùng kubeadm/script): cấu hình CA, TLS, etcd, API server, kubelet, networking. Mục đích là **hiểu từng thành phần** chứ không phải dùng cluster này cho production.

## Hướng dẫn từng bước (theo IP của bạn)

**→ [STEP-BY-STEP.md](STEP-BY-STEP.md)** – Hướng dẫn chi tiết từng bước với các máy:

| Máy của bạn | IP | Hostname trong tutorial |
|-------------|-----|--------------------------|
| jumpbox | 192.168.1.10 | jumpbox |
| master | 192.168.1.11 | **server** |
| worker01 | 192.168.1.12 | **node-0** |
| worker02 | 192.168.1.13 | **node-1** |

File **machines.txt.example** trong thư mục này là mẫu; khi làm lab trên jumpbox bạn tạo `machines.txt` tương ứng (hoặc copy từ STEP-BY-STEP Lab 00).

**Sau khi dựng xong:** Xem **[KIEN-THUC-TONG-HOP.md](KIEN-THUC-TONG-HOP.md)** – tổng hợp IP, Pod CIDR, CNI, VXLAN vs direct routing, và hướng dẫn chuyển sang Cilium.

---

## Yêu cầu

- **4 máy** (VM hoặc vật lý), kiến trúc **AMD64** hoặc **ARM64**
- **OS:** Debian 12 (bookworm) *hoặc* **Ubuntu 22.04 LTS / 24.04 LTS** (dùng được, xem mục [Dùng Ubuntu](#dùng-ubuntu) bên dưới)
- Cùng một mạng (có thể truy cập nhau qua IP)

| Máy      | Vai trò              | CPU | RAM  | Disk |
|----------|----------------------|-----|------|------|
| **jumpbox** | Máy làm việc (admin) | 1   | 512MB | 10GB |
| **server**  | Control plane (master) | 1 | 2GB  | 20GB |
| **node-0**  | Worker 1             | 1   | 2GB  | 20GB |
| **node-1**  | Worker 2             | 1   | 2GB  | 20GB |

**Phiên bản trong tutorial (K8s v1.32.x):**

- Kubernetes v1.32.x  
- containerd v2.1.x  
- etcd v3.6.x  
- CNI v1.6.x  

---

## Dùng Ubuntu

**Có thể dùng Ubuntu** thay cho Debian. Tutorial gốc viết cho Debian 12, nhưng Ubuntu (22.04 LTS, 24.04 LTS) tương thích rất cao vì cùng hệ Debian, dùng `apt` và systemd.

**Lưu ý khi dùng Ubuntu:**

| Nội dung | Ghi chú |
|----------|--------|
| **Lệnh `apt`** | Giống Debian (`apt-get update`, `apt-get install -y ...`). Một số package có thể tên hơi khác (ví dụ `curl`, `ca-certificates` thường đã có sẵn). |
| **Đường dẫn, systemd** | Giống Debian (`/etc/systemd/system/`, `systemctl enable --now`). |
| **Phiên bản** | Nên dùng **Ubuntu 22.04 LTS** hoặc **24.04 LTS** để gần với môi trường tutorial. |
| **Tải binary** | Tutorial dùng link tải cho Linux generic (tgz); chạy trên Ubuntu bình thường, không phụ thuộc distro. |

Nếu gặp lỗi “package not found”, kiểm tra tên package trên Ubuntu (`apt search <tên>`) hoặc cài dependency tương đương. Phần cấu hình TLS, etcd, kubelet, containerd… **không phụ thuộc** Debian hay Ubuntu.

Kiểm tra OS sau khi tạo máy:

```bash
cat /etc/os-release
# Debian 12: VERSION_CODENAME=bookworm
# Ubuntu:    VERSION_CODENAME=jammy (22.04) hoặc noble (24.04)
```

---

## Cách có 4 máy (Debian hoặc Ubuntu)

Bạn có thể chọn một trong các hướng sau:

| Cách | Mô tả |
|------|--------|
| **Vagrant** | Tạo 4 VM local bằng Vagrant + VirtualBox/VMware. Có nhiều repo “vagrant + k8s-the-hard-way” trên GitHub (Debian/Ubuntu đều có). |
| **GCP** | Dùng `gcloud` tạo 4 instance, tutorial gốc có hướng dẫn GCP. |
| **AWS / Azure / VPS** | Tạo 4 VM (Debian 12 hoặc Ubuntu 22.04/24.04), cấu hình security group/firewall cho các port cần thiết. |
| **Multipass** | Trên Windows/Mac/Linux: `multipass launch -n jumpbox -c 1 -m 512M -d 10G 22.04` — dùng **Ubuntu 22.04** rất tiện, tạo tương tự cho 4 VM. |

---

## Lộ trình 13 lab (theo tutorial gốc)

Làm **tuần tự** từ 01 → 13. Mỗi lab có link tới file gốc trên GitHub.

| # | Lab | Nội dung chính | Link gốc |
|---|-----|----------------|-----------|
| 01 | Prerequisites | Yêu cầu 4 máy, Debian 12 | [01-prerequisites.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md) |
| 02 | Jumpbox | Cài đặt công cụ trên máy admin (cfssl, kubectl, ssh...) | [02-jumpbox.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md) |
| 03 | Compute Resources | Cấu hình network, firewall (nếu dùng cloud) | [03-compute-resources.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md) |
| 04 | CA & TLS Certificates | Tạo CA và cấp certificate cho các component | [04-certificate-authority.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md) |
| 05 | Kubernetes Config Files | Tạo kubeconfig cho admin, kubelet, controller-manager, scheduler | [05-kubernetes-configuration-files.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md) |
| 06 | Data Encryption Config | Encryption key cho secret (at rest) | [06-data-encryption-keys.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/06-data-encryption-keys.md) |
| 07 | Bootstrapping etcd | Chạy etcd cluster trên control plane | [07-bootstrapping-etcd.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md) |
| 08 | Bootstrapping Control Plane | API server, controller-manager, scheduler (systemd units) | [08-bootstrapping-kubernetes-controllers.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md) |
| 09 | Bootstrapping Workers | kubelet, kube-proxy, containerd, CNI trên node-0, node-1 | [09-bootstrapping-kubernetes-workers.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md) |
| 10 | Configuring kubectl | Cấu hình kubectl từ jumpbox trỏ tới cluster | [10-configuring-kubectl.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/10-configuring-kubectl.md) |
| 11 | Pod Network Routes | Route/CNI để pod trên các node giao tiếp được | [11-pod-network-routes.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/11-pod-network-routes.md) |
| 12 | Smoke Test | Deploy ứng dụng, kiểm tra DNS, logs, port-forward | [12-smoke-test.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/12-smoke-test.md) |
| 13 | Cleaning Up | Xóa tài nguyên (VM, firewall rules...) | [13-cleanup.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/13-cleanup.md) |

---

## Checklist cá nhân (đánh dấu khi xong)

- [ ] 01 – Prerequisites (4 máy Debian 12 sẵn sàng)
- [ ] 02 – Jumpbox
- [ ] 03 – Compute Resources
- [ ] 04 – CA & TLS Certificates
- [ ] 05 – Kubernetes Config Files
- [ ] 06 – Data Encryption Config
- [ ] 07 – Bootstrapping etcd
- [ ] 08 – Bootstrapping Control Plane
- [ ] 09 – Bootstrapping Workers
- [ ] 10 – Configuring kubectl
- [ ] 11 – Pod Network Routes
- [ ] 12 – Smoke Test
- [ ] 13 – Cleaning Up

---

## Mẹo khi học

1. **Đọc kỹ từng bước** – Mỗi lệnh đều có mục đích (CA, SAN, path, user...). Đừng copy nguyên block mà không hiểu.
2. **Ghi chú** – Dùng file `notes.md` trong thư mục này để ghi lại lỗi gặp phải, cách fix, và khái niệm mới (etcd, kubelet, kubeconfig...).
3. **IP và hostname** – Tutorial dùng tên và IP mẫu. Khi dùng VM của bạn, thay đúng IP/hostname (server, node-0, node-1) trong mọi file cấu hình và lệnh.
4. **Phiên bản** – Repo gốc có thể cập nhật version (K8s, containerd, etcd). Nên dùng đúng version ghi trong từng lab để tránh lệch.
5. **Nếu kẹt** – Xem [Issues](https://github.com/kelseyhightower/kubernetes-the-hard-way/issues) của repo gốc; nhiều lỗi do sai IP, sai path, thiếu quyền.

---

## Sau khi xong

Bạn sẽ nắm được:

- **PKI trong K8s**: CA, certificate cho API server, kubelet, etc.
- **etcd**: vai trò và cách chạy cluster etcd cho control plane.
- **Control plane**: API server, controller-manager, scheduler chạy thế nào (process + cấu hình).
- **Worker**: kubelet, kube-proxy, container runtime (containerd), CNI.
- **Kubeconfig**: cấu trúc và cách kubectl dùng để gọi API server.

Có thể quay lại repo chính (`/01-fundamentals`, `/labs`) và thực hành deploy ứng dụng lên cluster “the hard way” của bạn, hoặc so sánh với cluster tạo bởi kubeadm/minikube để thấy điểm giống và khác.
