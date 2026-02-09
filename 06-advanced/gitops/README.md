# GitOps – Cấu trúc repo mẫu

Repo Git làm source of truth; Argo CD hoặc Flux sync cluster theo path.

## Cấu trúc gợi ý

```
repo/
  apps/
    myapp/
      base/           # Kustomize base hoặc raw YAML
      overlays/
        dev/
        prod/
  clusters/
    prod/
      kustomization.yaml   # Flux: tham chiếu apps/myapp/overlays/prod
```

## Argo CD – Tạo Application

```bash
argocd app create myapp \
  --repo https://github.com/user/repo \
  --path apps/myapp/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod
argocd app sync myapp
```

## Flux – Bootstrap (ghi vào Git)

```bash
flux bootstrap github --owner=user --repo=repo --path=clusters/prod --personal
flux create kustomization myapp --source=GitRepository/flux-system --path="./apps/myapp/overlays/prod" --prune=true
```
