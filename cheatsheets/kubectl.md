# Kubectl Cheatsheet

## Context & Cluster

```bash
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl cluster-info
```

## Get & List

```bash
kubectl get pods
kubectl get pods -o wide
kubectl get pods -A
kubectl get pods -w          # watch mode
kubectl get deployment,svc,pvc
kubectl get all -n <namespace>
```

## Describe & Debug

```bash
kubectl describe pod <pod-name>
kubectl describe node <node-name>
kubectl logs <pod-name>
kubectl logs -f <pod-name>   # follow
kubectl logs <pod-name> -c <container-name>
kubectl exec -it <pod-name> -- /bin/sh
```

## Apply & Delete

```bash
kubectl apply -f manifest.yaml
kubectl apply -f ./directory/
kubectl delete -f manifest.yaml
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --grace-period=0 --force
```

## Namespace

```bash
kubectl create namespace <name>
kubectl get ns
kubectl config set-context --current --namespace=<namespace>
```

## Short names

| Resource   | Short |
|-----------|-------|
| pods      | po    |
| services  | svc   |
| deployments | deploy |
| configmaps | cm   |
| secrets   | sec   |
| persistentvolumeclaims | pvc |
| namespaces | ns   |
