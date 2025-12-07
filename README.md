# Recharge - Local Terraform + Minikube Solution

## Overview
Local setup that:
- Installs Istio (Helm) into Minikube
- Deploys an App (Helm chart, ClusterIP)
- Configures Istio Gateway on NodePort 30080
- Routes only requests with Host header `api.app.com` to the app
- App responds on GET /info with Pod IP and `X-Pod-IP` header

## Quick run (Ubuntu)
1. Install prerequisites (Docker, minikube, kubectl, helm, terraform, python3, pip, pipx, moto[server]).
2. Build & deploy:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh


```
recharge-task/
├─ app/                   
│  ├─ app.py
│  ├─ requirements.txt
│  └─ Dockerfile
│
├─ charts/                 # Helm chart for the app
│  ├─ Chart.yaml
│  ├─ values.yaml
│  └─ templates/
│     ├─ deployment.yaml
│     └─ service.yaml
│
├─ k8s/                    # Istio CRDs
│  ├─ istio-gateway.yaml
│  └─ istio-virtualservice.yaml
│
├─ terraform/             
│  ├─ providers.tf
│  ├─ istio-values.yaml
│  ├─ main.tf              
│  ├─ variables.tf
│  └─ outputs.tf
│
├─ deploy.sh               # Automated deploy script
└─ README.md               

```
