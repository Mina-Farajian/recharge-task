# Recharge - Local Terraform + Minikube Solution

## Overview
Local setup that:
- Installs Istio (Helm) into Minikube
- Deploys an App (Helm chart, ClusterIP)
- Configures Istio Gateway on NodePort 30080
- Routes only requests with Host header `api.app.com` to the app
- App responds on GET /info with Pod IP and `X-Pod-IP` header

## Quick run (Ubuntu 24)
1. Install prerequisites (Docker, minikube, kubectl, helm, terraform, python3, pip).
2. Build & deploy:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh


```
recharge-terraform/
├─ app/
│  ├─ app.py
│  ├─ requirements.txt
│  └─ Dockerfile
├─ charts/
│  └─ app-chart/
│     ├─ Chart.yaml
│     ├─ values.yaml
│     └─ templates/
│        ├─ deployment.yaml
│        └─ service.yaml
├─ k8s/
│  ├─ istio-gateway.yaml
│  └─ istio-virtualservice.yaml
├─ terraform/
│  ├─ providers.tf
│  ├─ istio-values.yaml
│  ├─ helm_istio.tf
│  ├─ helm_app.tf
│  └─ main.tf
├─ deploy.sh
└─ README.md
```
