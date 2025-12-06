#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

#check existing a command
if ! command -v minikube >/dev/null; then
  echo "Install minikube first."
  exit 1
fi

#check return code
if ! minikube status >/dev/null 2>&1; then
  echo "Starting minikube..."
  minikube start
fi

echo "Switching Minikube to use local Docker daemon..."
#executes outputs of command as shell commands
# app image MUST be built into Minikube’s Docker, NOT host system.
#Otherwise Kubernetes cannot find image
eval "$(minikube docker-env)"

echo "Building app image into minikube..."
minikube image build -t app:latest -f "${ROOT}/app/Dockerfile" "${ROOT}/app"


if ! pgrep -f "moto_server" >/dev/null 2>&1; then
  echo "Starting moto_server (AWS mock) on port 5000..."
  moto_server --host 0.0.0.0 --port 5000 elbv2 cloudfront waf &> "${ROOT}/moto.log" &
  sleep 2
fi


pushd "${ROOT}/terraform" >/dev/null
if [ ! -d ".terraform" ]; then
  terraform init
fi


terraform apply #-auto-approve
popd >/dev/null


NODE_IP="$(minikube ip)"
echo "Done. Test with:"
echo "curl -v -H 'Host: api.app.com' http://${NODE_IP}:30080/info"
