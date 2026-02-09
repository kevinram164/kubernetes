# Kubernetes The Hard Way – Từng bước thực hiện

Hướng dẫn chi tiết theo **IP và hostname** của bạn:

| Máy      | IP           | Hostname trong tutorial | Ghi chú |
|----------|--------------|--------------------------|--------|
| jumpbox  | 192.168.1.10 | jumpbox                  | Máy làm việc (chạy lệnh từ đây) |
| master   | 192.168.1.11 | **server**               | Control plane (etcd, API server, scheduler, controller-manager) |
| worker01 | 192.168.1.12 | **node-0**               | Worker 1, Pod subnet 10.200.0.0/24 |
| worker02 | 192.168.1.13 | **node-1**               | Worker 2, Pod subnet 10.200.1.0/24 |

**Lưu ý:** Tutorial gốc dùng hostname `server`, `node-0`, `node-1` (trùng với tên trong certificate và config). Bạn sẽ cấu hình hostname và `/etc/hosts` để các máy của bạn (master, worker01, worker02) tương ứng với các tên đó.

---

## Lab 00 – Chuẩn bị và file machines.txt

**Thực hiện trên:** jumpbox (SSH vào `192.168.1.10`).

### Bước 0.1 – Đăng nhập jumpbox

```bash
ssh root@192.168.1.10
# hoặc: ssh root@jumpbox   (sau khi đã thêm /etc/hosts)
```

### Bước 0.2 – Tạo file machines.txt

Tạo file `machines.txt` trong thư mục làm việc (sau này sẽ là thư mục `~/kubernetes-the-hard-way`). File này dùng cho mọi lab.

```bash
mkdir -p ~/kubernetes-the-hard-way
cd ~/kubernetes-the-hard-way

cat > machines.txt << 'EOF'
192.168.1.11 server.kubernetes.local server
192.168.1.12 node-0.kubernetes.local node-0 10.200.0.0/24
192.168.1.13 node-1.kubernetes.local node-1 10.200.1.0/24
EOF

cat machines.txt
```

### Bước 0.3 – Bật SSH root và copy SSH key (nếu chưa có)

Trên **mỗi máy** (master, worker01, worker02) nếu chưa cho phép root SSH:

```bash
# Trên từng máy (192.168.1.11, 192.168.1.12, 192.168.1.13):
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
# Ubuntu: service thường tên là ssh (không phải sshd): systemctl restart ssh
```

Trên **jumpbox**, tạo SSH key và copy sang 3 máy:

```bash
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

for IP in 192.168.1.11 192.168.1.12 192.168.1.13; do
  ssh-copy-id root@${IP}
done
```

Kiểm tra SSH không cần mật khẩu:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n -o StrictHostKeyChecking=no root@${IP} hostname
done < machines.txt
```

Kỳ vọng in ra: `server`, `node-0`, `node-1`.

### Bước 0.4 – Gán hostname và /etc/hosts trên từng máy

**Trên jumpbox**, chạy (đọc từ `machines.txt`):

```bash
cd ~/kubernetes-the-hard-way

# Gán hostname cho server, node-0, node-1
while read IP FQDN HOST SUBNET; do
  ssh -n root@${IP} "sed -i 's/^127.0.1.1.*/127.0.1.1\t'${FQDN}' '${HOST}'/' /etc/hosts"
  ssh -n root@${IP} "hostnamectl set-hostname ${HOST}"
  ssh -n root@${IP} "systemctl restart systemd-hostnamed 2>/dev/null || true"
done < machines.txt
```

Tạo file `hosts` và thêm vào `/etc/hosts` trên jumpbox:

```bash
echo "" > hosts
echo "# Kubernetes The Hard Way" >> hosts
while read IP FQDN HOST SUBNET; do
  echo "${IP} ${FQDN} ${HOST}" >> hosts
done < machines.txt
cat hosts >> /etc/hosts
```

Copy `hosts` sang server, node-0, node-1 và append vào `/etc/hosts`:

```bash
while read IP FQDN HOST SUBNET; do
  scp hosts root@${HOST}:~/
  ssh -n root@${HOST} "cat ~/hosts >> /etc/hosts"
done < machines.txt
```

Kiểm tra: từ jumpbox có thể SSH bằng hostname:

```bash
for host in server node-0 node-1; do ssh root@${host} hostname; done
# Kỳ vọng: server, node-0, node-1
```

---

## Lab 01 – Jumpbox: cài công cụ và clone repo

**Tất cả lệnh trong lab này chạy trên jumpbox**, trong thư mục `~/kubernetes-the-hard-way`.

### Bước 1.1 – Cài package

```bash
apt-get update
apt-get -y install wget curl vim openssl git
```

### Bước 1.2 – Clone repo Kubernetes The Hard Way

```bash
cd ~
git clone --depth 1 https://github.com/kelseyhightower/kubernetes-the-hard-way.git
cd kubernetes-the-hard-way
pwd
# Phải là: /root/kubernetes-the-hard-way (hoặc /home/<user>/kubernetes-the-hard-way)
```

**Quan trọng:** Nếu bạn đã tạo `machines.txt` ở thư mục khác (ví dụ `~/kubernetes-the-hard-way` trước khi clone), hãy copy `machines.txt` vào đúng thư mục repo vừa clone:

```bash
# Nếu machines.txt nằm chỗ khác:
cp /path/to/machines.txt ~/kubernetes-the-hard-way/
```

### Bước 1.3 – Tải binary

Kiến trúc (amd64 hoặc arm64):

```bash
cat downloads-$(dpkg --print-architecture).txt
```

Tải:

```bash
wget -q --show-progress --https-only --timestamping \
  -P downloads \
  -i downloads-$(dpkg --print-architecture).txt
```

Giải nén và sắp xếp (dùng đúng kiến trúc `amd64` hoặc `arm64`):

```bash
ARCH=$(dpkg --print-architecture)
mkdir -p downloads/{client,cni-plugins,controller,worker}
tar -xvf downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz -C downloads/worker/
tar -xvf downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz --strip-components 1 -C downloads/worker/
tar -xvf downloads/cni-plugins-linux-${ARCH}-v1.6.2.tgz -C downloads/cni-plugins/
tar -xvf downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz -C downloads/ --strip-components 1 etcd-v3.6.0-rc.3-linux-${ARCH}/etcdctl etcd-v3.6.0-rc.3-linux-${ARCH}/etcd
mv downloads/etcdctl downloads/client/
mv downloads/kubectl downloads/client/
mv downloads/etcd downloads/controller/
mv downloads/kube-apiserver downloads/controller/
mv downloads/kube-controller-manager downloads/controller/
mv downloads/kube-scheduler downloads/controller/
mv downloads/kubelet downloads/worker/
mv downloads/kube-proxy downloads/worker/
mv downloads/runc.${ARCH} downloads/worker/runc
```

(Xem `downloads-$(dpkg --print-architecture).txt` trong repo; nếu phiên bản file thay đổi thì chỉnh tên file trong lệnh `tar` cho khớp.)

Xóa file nén và gán quyền thực thi:

```bash
rm -rf downloads/*.gz downloads/*.tgz
chmod +x downloads/{client,cni-plugins,controller,worker}/*
```

### Bước 1.4 – Cài kubectl trên jumpbox

```bash
cp downloads/client/kubectl /usr/local/bin/
kubectl version --client
```

---

## Lab 02 – Bỏ qua (Compute Resources)

Lab 03 gốc là “Provisioning Compute Resources” (network, firewall). Với môi trường local (192.168.1.x), bạn đã có sẵn 4 máy và mạng. Chỉ cần đảm bảo:

- Từ jumpbox có thể `ping` và `ssh root@server`, `ssh root@node-0`, `ssh root@node-1`.
- Các máy có thể resolve hostname `server`, `node-0`, `node-1` (đã làm ở Lab 00).

---

## Lab 03 – CA và TLS Certificates

**Chạy trên jumpbox**, trong `~/kubernetes-the-hard-way`.

### Bước 3.1 – Tạo CA

```bash
cd ~/kubernetes-the-hard-way
openssl genrsa -out ca.key 4096
openssl req -x509 -new -sha512 -noenc \
  -key ca.key -days 3653 \
  -config ca.conf \
  -out ca.crt
ls -la ca.crt ca.key
```

### Bước 3.2 – Tạo certificate cho từng component

```bash
certs=(
  "admin" "node-0" "node-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)

for i in ${certs[*]}; do
  openssl genrsa -out "${i}.key" 4096
  openssl req -new -key "${i}.key" -sha256 -config ca.conf -section ${i} -out "${i}.csr"
  openssl x509 -req -days 3653 -in "${i}.csr" -copy_extensions copyall \
    -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial -out "${i}.crt"
done

ls -1 *.crt *.key *.csr
```

### Bước 3.3 – Copy certificate sang node-0, node-1

```bash
for host in node-0 node-1; do
  ssh root@${host} mkdir -p /var/lib/kubelet/
  scp ca.crt root@${host}:/var/lib/kubelet/
  scp ${host}.crt root@${host}:/var/lib/kubelet/kubelet.crt
  scp ${host}.key root@${host}:/var/lib/kubelet/kubelet.key
done
```

### Bước 3.4 – Copy certificate sang server (master)

```bash
scp ca.key ca.crt \
  kube-api-server.key kube-api-server.crt \
  service-accounts.key service-accounts.crt \
  root@server:~/
```

---

## Lab 04 – Kubernetes config (kubeconfig)

**Chạy trên jumpbox**, trong thư mục có `ca.crt` và các file `.crt`/`.key` (ví dụ `~/kubernetes-the-hard-way`).

### Bước 4.1 – Kubeconfig cho node-0, node-1 (kubelet)

```bash
for host in node-0 node-1; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=${host}.kubeconfig

  kubectl config set-credentials system:node:${host} \
    --client-certificate=${host}.crt \
    --client-key=${host}.key \
    --embed-certs=true \
    --kubeconfig=${host}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${host} \
    --kubeconfig=${host}.kubeconfig

  kubectl config use-context default --kubeconfig=${host}.kubeconfig
done
```

### Bước 4.2 – Kubeconfig cho kube-proxy

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://server.kubernetes.local:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.crt \
  --client-key=kube-proxy.key \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

### Bước 4.3 – Kubeconfig cho kube-controller-manager

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.crt \
  --client-key=kube-controller-manager.key \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
```

### Bước 4.4 – Kubeconfig cho kube-scheduler

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.crt \
  --client-key=kube-scheduler.key \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
```

### Bước 4.5 – Kubeconfig cho admin

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.crt \
  --client-key=admin.key \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig
```

### Bước 4.6 – Phân phối kubeconfig

Copy kubelet + kube-proxy sang node-0, node-1:

```bash
for host in node-0 node-1; do
  ssh root@${host} "mkdir -p /var/lib/kube-proxy /var/lib/kubelet"
  scp kube-proxy.kubeconfig root@${host}:/var/lib/kube-proxy/kubeconfig
  scp ${host}.kubeconfig root@${host}:/var/lib/kubelet/kubeconfig
done
```

Copy admin, kube-controller-manager, kube-scheduler sang server:

```bash
scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig root@server:~/
```

---

## Lab 05 – Data encryption config

**Trên jumpbox:**

```bash
cd ~/kubernetes-the-hard-way
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
envsubst < configs/encryption-config.yaml > encryption-config.yaml
scp encryption-config.yaml root@server:~/
```

---

## Lab 06 – Bootstrapping etcd

### Bước 6.1 – Copy binary và unit từ jumpbox sang server

**Trên jumpbox:**

```bash
cd ~/kubernetes-the-hard-way
scp downloads/controller/etcd downloads/client/etcdctl units/etcd.service root@server:~/
```

### Bước 6.2 – Cấu hình và chạy etcd trên server

**Đăng nhập server:**

```bash
ssh root@server
```

**Trên server:**

```bash
mv etcd etcdctl /usr/local/bin/
mkdir -p /etc/etcd /var/lib/etcd
chmod 700 /var/lib/etcd
cp ca.crt kube-api-server.key kube-api-server.crt /etc/etcd/
mv etcd.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
etcdctl member list
```

Kỳ vọng thấy 1 member. Sau đó thoát về jumpbox: `exit`.

---

## Lab 07 – Bootstrapping Control Plane (API server, controller-manager, scheduler)

### Bước 7.1 – Copy binary và config từ jumpbox sang server

**Trên jumpbox:**

```bash
cd ~/kubernetes-the-hard-way
scp \
  downloads/controller/kube-apiserver \
  downloads/controller/kube-controller-manager \
  downloads/controller/kube-scheduler \
  downloads/client/kubectl \
  units/kube-apiserver.service \
  units/kube-controller-manager.service \
  units/kube-scheduler.service \
  configs/kube-scheduler.yaml \
  configs/kube-apiserver-to-kubelet.yaml \
  root@server:~/
```

### Bước 7.2 – Cấu hình và start control plane trên server

**Đăng nhập server:** `ssh root@server`

**Trên server:**

```bash
mkdir -p /etc/kubernetes/config /var/lib/kubernetes
mv ca.crt ca.key kube-api-server.key kube-api-server.crt \
   service-accounts.key service-accounts.crt encryption-config.yaml \
   /var/lib/kubernetes/
mv kube-apiserver.service /etc/systemd/system/
mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
mv kube-controller-manager.service /etc/systemd/system/
mv kube-scheduler.kubeconfig /var/lib/kubernetes/
mv kube-scheduler.yaml /etc/kubernetes/config/
mv kube-scheduler.service /etc/systemd/system/
mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
systemctl daemon-reload
systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

Chờ vài giây, kiểm tra:

```bash
systemctl is-active kube-apiserver kube-controller-manager kube-scheduler
kubectl cluster-info --kubeconfig /root/admin.kubeconfig
```

### Bước 7.3 – RBAC cho Kubelet (trên server)

**Trên server:**

```bash
kubectl apply -f kube-apiserver-to-kubelet.yaml --kubeconfig /root/admin.kubeconfig
exit
```

### Bước 7.4 – Kiểm tra từ jumpbox

**Trên jumpbox:**

```bash
cd ~/kubernetes-the-hard-way
curl --cacert ca.crt https://server.kubernetes.local:6443/version
```

Phải trả về JSON version.

---

## Lab 08 – Bootstrapping Worker Nodes (node-0, node-1)

### Bước 8.1 – Copy file từ jumpbox sang từng worker

**Trên jumpbox:**

```bash
cd ~/kubernetes-the-hard-way
```

Tạo config CNI và kubelet theo từng node (đọc subnet từ `machines.txt`):

```bash
for HOST in node-0 node-1; do
  SUBNET=$(grep ${HOST} machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" configs/10-bridge.conf > 10-bridge.conf
  sed "s|SUBNET|$SUBNET|g" configs/kubelet-config.yaml > kubelet-config.yaml
  scp 10-bridge.conf kubelet-config.yaml root@${HOST}:~/
done
```

```bash
for HOST in node-0 node-1; do
  scp downloads/worker/* downloads/client/kubectl \
    configs/99-loopback.conf configs/containerd-config.toml configs/kube-proxy-config.yaml \
    units/containerd.service units/kubelet.service units/kube-proxy.service \
    root@${HOST}:~/
done
```

```bash
for HOST in node-0 node-1; do
  ssh root@${HOST} "mkdir -p ~/cni-plugins"
  scp downloads/cni-plugins/* root@${HOST}:~/cni-plugins/
done
```

### Bước 8.2 – Cài đặt trên từng worker (làm cho node-0, sau đó node-1)

**Đăng nhập worker:** `ssh root@node-0` (sau đó làm tương tự cho `ssh root@node-1`).

**Trên mỗi worker (node-0 rồi node-1):**

```bash
apt-get update
apt-get -y install socat conntrack ipset kmod
swapoff -a
mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes
mv crictl kube-proxy kubelet runc /usr/local/bin/
mv containerd containerd-shim-runc-v2 containerd-stress /bin/ 2>/dev/null || true
mv cni-plugins/* /opt/cni/bin/
mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
modprobe br-netfilter
echo "br-netfilter" >> /etc/modules-load.d/modules.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
mkdir -p /etc/containerd
mv containerd-config.toml /etc/containerd/config.toml
mv containerd.service /etc/systemd/system/
mv kubelet-config.yaml /var/lib/kubelet/
mv kubelet.service /etc/systemd/system/
mv kube-proxy-config.yaml /var/lib/kube-proxy/
mv kube-proxy.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable containerd kubelet kube-proxy
systemctl start containerd kubelet kube-proxy
systemctl is-active kubelet
exit
```

Làm lại toàn bộ bước 8.2 cho **node-1** (ssh root@node-1).

### Bước 8.3 – Kiểm tra từ jumpbox

**Trên jumpbox:**

```bash
ssh root@server "kubectl get nodes --kubeconfig /root/admin.kubeconfig"
```

Kỳ vọng thấy `node-0` và `node-1` ở trạng thái Ready (có thể mất vài chục giây).

---

## Lab 09 – Cấu hình kubectl từ xa (trên jumpbox)

**Trên jumpbox:**

```bash
cd ~/kubernetes-the-hard-way
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://server.kubernetes.local:6443

kubectl config set-credentials admin \
  --client-certificate=admin.crt \
  --client-key=admin.key

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way
kubectl version
kubectl get nodes
```

---

## Lab 10 – Pod network routes (mạng cho Pod)

Pod trên node-0 dùng subnet 10.200.0.0/24, trên node-1 dùng 10.200.1.0/24. Cần đảm bảo **server** (và các node) biết route tới hai subnet này.

**Trên server (master) – thêm route tới Pod subnet của từng worker:**

```bash
ssh root@server
ip route add 10.200.0.0/24 via 192.168.1.12 dev eth0 2>/dev/null || true
ip route add 10.200.1.0/24 via 192.168.1.13 dev eth0 2>/dev/null || true
exit
```

(Nếu interface mạng không phải `eth0`, thay bằng interface đúng, ví dụ `ens18`.)

**Trên jumpbox** (để `kubectl` từ jumpbox có thể truy cập Pod qua network):

```bash
# Trên jumpbox (192.168.1.10), thêm route tới Pod subnet (tùy chọn)
ip route add 10.200.0.0/24 via 192.168.1.12 2>/dev/null || true
ip route add 10.200.1.0/24 via 192.168.1.13 2>/dev/null || true
```

**Trên từng worker:** đảm bảo node-0 biết route tới 10.200.1.0/24 và node-1 biết 10.200.0.0/24 (để Pod cross-node giao tiếp):

```bash
ssh root@node-0 "ip route add 10.200.1.0/24 via 192.168.1.13 2>/dev/null || true"
ssh root@node-1 "ip route add 10.200.0.0/24 via 192.168.1.12 2>/dev/null || true"
```

Route tạm thời; sau reboot mất. Để lưu vĩnh viễn tùy distro (netplan, /etc/network/interfaces, hoặc systemd-networkd).

---

## Lab 11 – Smoke test

**Tất cả trên jumpbox**, đã dùng `kubectl` trỏ tới cluster (Lab 09).

### Encryption at rest

```bash
kubectl create secret generic kubernetes-the-hard-way --from-literal="mykey=mydata"
ssh root@server 'ETCDCTL_API=3 etcdctl get /registry/secrets/default/kubernetes-the-hard-way | hexdump -C'
```

Trong output phải thấy `k8s:enc:aescbc:v1:key1`.

### Deployment và Port-forward

```bash
kubectl create deployment nginx --image=nginx:latest
kubectl get pods -l app=nginx
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:80
```

Mở terminal khác: `curl -I http://127.0.0.1:8080` → HTTP 200.

### Logs và Exec

```bash
kubectl logs $POD_NAME
kubectl exec -ti $POD_NAME -- nginx -v
```

### Service NodePort

```bash
kubectl expose deployment nginx --port 80 --type NodePort
NODE_PORT=$(kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')
NODE_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].spec.nodeName}")
curl -I http://${NODE_NAME}:${NODE_PORT}
```

`NODE_NAME` sẽ là `node-0` hoặc `node-1`; từ jumpbox đã có /etc/hosts nên resolve được. Nếu gọi từ máy khác, dùng IP: `curl -I http://192.168.1.12:${NODE_PORT}` hoặc `http://192.168.1.13:${NODE_PORT}`.

---

## Tóm tắt IP và hostname

| Máy của bạn | IP           | Hostname dùng trong tutorial |
|-------------|--------------|------------------------------|
| jumpbox     | 192.168.1.10 | jumpbox                      |
| master      | 192.168.1.11 | server, server.kubernetes.local |
| worker01    | 192.168.1.12 | node-0                       |
| worker02    | 192.168.1.13 | node-1                       |

Nếu gặp lỗi: kiểm tra lại `machines.txt`, `/etc/hosts` trên cả 4 máy, và đảm bảo mọi lệnh `scp`/`ssh` dùng đúng hostname (server, node-0, node-1). Chúc bạn làm lab thành công.
