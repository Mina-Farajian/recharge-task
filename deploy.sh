#!/usr/bin/env bash

# Install Docker
if docker doesnt exist:

    sudo apt update
    sudo apt install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc


  "  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
      Types: deb
      URIs: https://download.docker.com/linux/ubuntu
      Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
      Components: stable
      Signed-By: /etc/apt/keyrings/docker.asc
    EOF
"
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo systemctl start docker
###################################################################################################
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

# Start minikube if needed
if ! command -v minikube >/dev/null; then
  echo "Install minikube first."
  exit 1
fi

if ! minikube status >/dev/null 2>&1; then
  echo "Starting minikube..."
  minikube start --driver=docker --cpus=4 --memory=8192
fi

# Use minikube's docker for building image
eval "$(minikube docker-env)"

echo "Building app image into minikube..."
minikube image build -t app:latest -f "${ROOT}/app/Dockerfile" "${ROOT}/app"

# Start moto (optional)
if ! pgrep -f "moto_server" >/dev/null 2>&1; then
  echo "Starting moto_server (AWS mock) on port 5000..."
  # background moto for elbv2/waf/cloudfront (coverage limited)
  moto_server --host 0.0.0.0 --port 5000 elbv2 cloudfront waf &> "${ROOT}/moto.log" &
  sleep 2
fi

# Terraform apply
pushd "${ROOT}/terraform" >/dev/null
if [ ! -d ".terraform" ]; then
  terraform init
fi

terraform apply -auto-approve
popd >/dev/null

# After apply: sanity checks & instructions
NODE_IP="$(minikube ip)"
echo "Done. Test with:"
echo "curl -v -H 'Host: api.app.com' http://${NODE_IP}:30080/info"
