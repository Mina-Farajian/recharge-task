#CRD
resource "null_resource" "add_istio_repo" {
  provisioner "local-exec" {
    command = <<EOT
set -e
if ! helm repo list | awk '{print $1}' | grep -q "^istio$"; then
  helm repo add istio https://istio-release.storage.googleapis.com/charts
fi
helm repo update
EOT
  }
}
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true

  wait    = true
  timeout = 60

  depends_on = [null_resource.add_istio_repo]
}

# Control plane
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"

  wait    = true
  timeout = 120

  depends_on = [
    helm_release.istio_base
  ]
}

# Ingress gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"

  values = [file("${path.module}/istio-values.yaml")]

  wait    = true
  timeout = 60

  depends_on = [
    helm_release.istiod
  ]
}
