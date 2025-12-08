#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

VERSION="1.0.2"
IMAGE_NAME="my-app"
ROOT=$(pwd)
TERRAFORM_DIR="$ROOT/terraform"
CHARTS_DIR="./charts"
NAMESPACE_APP="dev"
NAMESPACE_ISTIO="istio-system"

echo " Please make sure you already have installed packages: Docker, minikube, kubectl, helm, terraform, python3, pip, moto_server"
echo "use pipx ensurepath after installing moto with pipx"
for cmd in pipx python3 terraform docker kubectl; do
    if ! command -v "$cmd" >/dev/null; then
        echo "🚨 ALERT: '$cmd' not found. Install with: sudo apt install $cmd"
    fi
done

echo "Make sure you have updated image's TAG in this script"
echo "Ensuring Minikube is running..."
STAT=`minikube status | grep host | cut -f2 -d: | tr -d ' '`
if [ "$STAT" = "Stopped" ]; then
    echo "Minikube is stopped. Starting Minikube..."
    minikube start
fi

# --- 1. IMAGE BUILD & LOAD ---
echo "Building app image on host Docker... TAG is $VERSION"
echo
eval $(minikube docker-env)
docker build -t "$IMAGE_NAME:$VERSION" "$ROOT/app"

echo "Loading image into Minikube..."
minikube image load "$IMAGE_NAME:$VERSION"

# --- 2. SETUP IP & MOTO ---
echo "Exporting Minikube IP..."
export MINIKUBE_IP=$(minikube ip)
echo "Minikube IP = $MINIKUBE_IP"

# Safely update the minikube_ip variable in terraform.tfvars
TFWARS_FILE="$TERRAFORM_DIR/terraform.tfvars"
sed -i "s|minikube_ip = \".*\"|minikube_ip = \"$MINIKUBE_IP\"|g" "$TFWARS_FILE"

echo "Starting moto_server (AWS mock) on port 5000..."
if ! pgrep -f moto_server >/dev/null; then
    moto_server --host 0.0.0.0 --port 5000 &
    sleep 10
fi
#Cleanup
kubectl delete deployment istio-ingressgateway -n istio-system || true
kubectl delete service istio-ingressgateway -n istio-system || true
kubectl delete gateway app-gateway -n istio-system || true
helm delete istio-ingressgateway -n istio-system || true
kubectl create namespace dev > /dev/null 2>&1 || true
sleep 5

# --- 3. INFRASTRUCTURE DEPLOYMENT (Terraform: AWS/Moto & Istio Base) ---
echo "Running Terraform to install Istio Base and AWS/Moto resources..."
pushd "$TERRAFORM_DIR" >/dev/null

terraform init -upgrade
echo "minikube ip is $MINIKUBE_IP"
terraform apply -auto-approve

popd >/dev/null


# --- 4. APPLICATION DEPLOYMENT (Helm) ---
echo
echo "Deploying application 'my-app' via Helm..."
helm upgrade --install my-app "./charts" \
             --wait --timeout 3m \
             --namespace "$NAMESPACE_APP" \
             --set "image.repository=${IMAGE_NAME}" \
             --set "image.tag=${VERSION}" \
             -f "./charts/values.yaml"

# --- 5. TEST INSTRUCTIONS ---
NODE_IP=$(minikube ip)
echo
echo "========================================================"
echo "✅ Deployment completed successfully!"
echo "Istio Ingress Gateway is running on NodePort 30080."
echo "Ready. Test the full path (assuming api.app.com is in /etc/hosts) with:"
echo "  curl -v -H 'Host: api.app.com' http://${NODE_IP}:30080/info"
echo "========================================================"