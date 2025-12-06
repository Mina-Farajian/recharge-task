#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")"; pwd)

echo "Ensuring Minikube is running..."
minikube status >/dev/null 2>&1 || minikube start --driver=docker

echo "Building app image on host Docker..."
docker build -t app:latest "$ROOT/app"

echo "Loading image into Minikube..."
minikube image load app:latest

echo "Starting moto_server (AWS mock) on port 5000..."
if ! pgrep -f moto_server >/dev/null; then
    moto_server --host 0.0.0.0 --port 5000 elbv2 cloudfront waf &
    sleep 3
fi

echo "Running Terraform..."
pushd "$ROOT/terraform"
terraform init -upgrade
terraform apply -auto-approve
popd
