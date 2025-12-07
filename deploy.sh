#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

VERSION="1.0.1"
IMAGE_NAME="app"
ROOT=$(pwd)
TERRAFORM_DIR="$ROOT/terraform"
CHARTS_DIR="./charts"
NAMESPACE_APP="dev"
NAMESPACE_ISTIO="istio-system"

echo " you need to already have installed Docker, minikube, kubectl, helm, terraform, python3, pip, moto_server"
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
# Assumes Dockerfile is in $ROOT/app
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

# --- 3. INFRASTRUCTURE DEPLOYMENT (Terraform: AWS/Moto & Istio Base) ---
echo "Running Terraform to install Istio Base and AWS/Moto resources..."
pushd "$TERRAFORM_DIR" >/dev/null

terraform init -upgrade
echo "minikube ip is $MINIKUBE_IP"
terraform apply -auto-approve

popd >/dev/null

# --- 4. ISTIO DEPLOYMENT (Full Control in Shell) ---
echo "--- Installing Istio Control Plane and Gateway (CRD Sync Controlled) ---"
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Base (CRDs)
echo "Installing Istio Base (CRDs)..."
helm upgrade --install istio-base istio/base -n "$NAMESPACE_ISTIO" --create-namespace --wait --timeout 60s

# Install Istiod (Control Plane)
echo "Installing Istiod (Control Plane)..."
helm upgrade --install istiod istio/istiod -n "$NAMESPACE_ISTIO" --wait --timeout 120s

# Install Ingress Gateway (with NodePort 30080 config from istio-values.yaml)
echo "Installing Istio Ingress Gateway..."
helm upgrade --install istio-ingressgateway istio/gateway -n "$NAMESPACE_ISTIO" \
  -f "$TERRAFORM_DIR/istio-values.yaml" --wait --timeout 60s

# Robust wait for the deployment to be ready
echo "Waiting for Istio Ingress Gateway Deployment to be Available..."
kubectl wait --namespace "$NAMESPACE_ISTIO" --for=condition=Available deployment/istio-ingressgateway --timeout=120s

# Apply Istio Injection Label
echo "Applying Istio Sidecar Injection Label to '$NAMESPACE_APP' namespace..."
kubectl label namespace "$NAMESPACE_APP" istio-injection=enabled --overwrite

# Apply Istio Custom Resources (Gateway and VirtualService)
echo "Applying Istio Gateway and VirtualService..."
kubectl apply -f "$K8S_CONFIG_DIR/istio-gateway.yaml"
kubectl apply -f "$K8S_CONFIG_DIR/istio-virtualservice.yaml"

# --- 5. APPLICATION DEPLOYMENT (Helm) ---
echo "Deploying application 'my-app' via Helm..."
helm upgrade --install my-app "$CHARTS_DIR" \
             --wait --timeout 3m \
            --namespace "$NAMESPACE_APP" \
            -f "$CHARTS_DIR/values.yaml"

# --- 6. TEST INSTRUCTIONS ---
NODE_IP=$(minikube ip)
echo
echo "========================================================"
echo "✅ Deployment completed successfully!"
echo "Istio Ingress Gateway is running on NodePort 30080."
echo "Ready. Test the full path (assuming api.app.com is in /etc/hosts) with:"
echo "  curl -v -H 'Host: api.app.com' http://${NODE_IP}:30080/info"
echo "========================================================"