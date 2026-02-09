# LoadBalancer & Ingress trên Cloud – Phase 6

Trên managed K8s, **Service type LoadBalancer** tạo **cloud Load Balancer** (NLB/ALB, GCP LB, Azure LB). **Ingress** có thể dùng controller do cloud cung cấp (GKE Ingress, ALB Ingress Controller) hoặc Nginx/Traefik.

---

## 1. Service type LoadBalancer

| Cloud | Hành vi | Ghi chú |
|-------|--------|--------|
| **EKS** | Tạo NLB (Classic) hoặc NLB (network); có thể dùng annotation để tạo ALB | Annotation `service.beta.kubernetes.io/aws-load-balancer-type: nlb` |
| **GKE** | Tạo Network Load Balancer (L4) hoặc qua Ingress (L7) | Service LoadBalancer → L4; Ingress → L7 (HTTP(S)) |
| **AKS** | Tạo Azure Load Balancer (Standard) | Có thể dùng Application Gateway Ingress Controller (AGIC) |

- Trên on-prem: LoadBalancer thường cần MetalLB hoặc tương đương; trên cloud **không cần** MetalLB.

---

## 2. Ingress

| Cloud | Ingress controller | Ghi chú |
|-------|--------------------|--------|
| **EKS** | AWS Load Balancer Controller (ALB Ingress) | Ingress → ALB; annotation để chỉ định scheme (internal/internet-facing), cert ARN. |
| **GKE** | GKE Ingress (built-in) | Ingress resource → GCP HTTP(S) LB; có thể dùng Nginx Ingress nếu muốn. |
| **AKS** | Application Gateway Ingress Controller (AGIC) hoặc Nginx Ingress | AGIC dùng Azure Application Gateway. |

- **TLS**: Cert lưu Secret (tls.crt, tls.key) hoặc dùng cert manager (Let’s Encrypt) + annotation (cert ARN trên AWS, …).

---

## 3. Ví dụ Ingress (EKS + ALB)

- Cài AWS Load Balancer Controller (Helm hoặc manifest).
- Ingress với annotation `kubernetes.io/ingress.class: alb`, `alb.ingress.kubernetes.io/scheme: internet-facing`, …
- Ingress → ALB được tạo; DNS trỏ CNAME tới ALB.

Tài liệu: [AWS LB Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/), [GKE Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress), [AKS AGIC](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview).
