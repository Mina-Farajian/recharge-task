#!/bin/bash

set -e
VERSION="1.0.0"
IMAGE_NAME="app"
ROOT=$(pwd)
namespace="istio-system"

echo " you need to already have installed Docker, minikube, kubectl, helm, terraform, python3, pip, moto_server"
echo "use pipx ensurepath after installing moto with pipx"
for cmd in pipx python3 terraform docker kubectl; do
    if ! command -v "$cmd" >/dev/null; then
        echo "🚨 ALERT: '$cmd' not found. Install with: sudo apt install $cmd"
    fi
done

echo "Make sure you have updated image's TAG in this script
 "
echo "Ensuring Minikube is running..."
STAT=`minikube status | grep host | cut -f2 -d: | tr -d ' '`
if [ "$STAT" = "Stopped" ]; then
    echo "Minikube is stopped. Starting Minikube..."
    minikube start
fi

echo "Building app image on host Docker... TAG is $VERSION"
docker build -t "$IMAGE_NAME:$VERSION" "$ROOT/app"

echo "Loading image into Minikube..."
minikube image load "$IMAGE_NAME:$VERSION"

echo "Exporting Minikube IP..."
export MINIKUBE_IP=$(minikube ip)
echo "Minikube IP = $MINIKUBE_IP"

echo "Starting moto_server (AWS mock) on port 5000..."
if ! pgrep -f moto_server >/dev/null; then
    moto_server --host 0.0.0.0 --port 5000  &
    sleep 10
fi


helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
echo "Running Terraform..."
pushd "$ROOT/terraform" >/dev/null
terraform init -upgrade
echo "minikube ip is $MINIKUBE_IP"
terraform apply -auto-approve
popd >/dev/null

NODE_IP=$(minikube ip)
echo
echo "Ready. Test with:"
echo "  curl -v -H 'Host: api.app.com' http://${NODE_IP}:30080/info"
echo

echo "Deployment completed successfully!"
