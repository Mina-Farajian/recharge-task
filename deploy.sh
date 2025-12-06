#!/bin/bash
set -euo pipefail

VERSION="1.0.0"
IMAGE_NAME="app"
ROOT=$(pwd)

echo "Ensuring Minikube is running..."
STAT=$(minikube status | grep host | cut -f2 -d: | tr -d ' ')

echo "Minikube host status: $STAT"
if [ "$STAT" = "Stopped" ]; then
    echo "Minikube is stopped. Starting Minikube..."
    minikube start
else
    echo "Minikube is already running."
fi
echo "Building app image on host Docker..."
docker build -t "$IMAGE_NAME:$VERSION" "$ROOT/app"

echo "Loading image into Minikube..."
minikube image load "$IMAGE_NAME:$VERSION"

echo "Exporting Minikube IP..."
export MINIKUBE_IP=$(minikube ip)
echo "Minikube IP = $MINIKUBE_IP"

echo "Starting moto_server (AWS mock) on port 5000..."
if ! pgrep -f moto_server >/dev/null; then
    moto_server --host 0.0.0.0 --port 5000 elbv2 cloudfront waf &
    sleep 3
fi

cat > "$ROOT/terraform/terraform.tfvars" <<EOF
minikube_ip = "$MINIKUBE_IP"
docker_image = "$IMAGE_NAME:$VERSION"
EOF

echo "Running Terraform..."
pushd "$ROOT/terraform" >/dev/null
terraform init -upgrade
terraform apply -auto-approve
popd >/dev/null

echo "Deployment completed successfully!"
