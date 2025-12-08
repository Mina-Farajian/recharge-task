#########################################
# Wait for Istio CRDs
#########################################
resource "null_resource" "wait_for_istio_ready" {
  # Now depends on the component that *deploys* the gateway Pods
  depends_on = [
    helm_release.istio_ingress
  ]

  provisioner "local-exec" {
    command = <<EOT
set -e
echo "Waiting for Istio Ingress Gateway Pods to be Ready..."
# Wait for the Istio Ingress Gateway Deployment to be Ready
kubectl wait --namespace istio-system --for=condition=Available deployment/istio-ingressgateway --timeout=120s
echo "Istio Ingress Gateway is Ready."
EOT
  }
}


#########################################
# Istio Gateway
#########################################
data "local_file" "istio_gateway" {
  filename = "../k8s/istio-gateway.yaml"
}

resource "kubernetes_manifest" "istio_gateway" {
  depends_on = [
    null_resource.wait_for_istio_ready
  ]
  manifest = yamldecode(data.local_file.istio_gateway.content)
}

#########################################
# Istio VirtualService
#########################################
data "local_file" "istio_virtualservice" {
  filename = "../k8s/istio-virtualservice.yaml"
}

resource "kubernetes_manifest" "istio_virtualservice" {
  depends_on = [
    kubernetes_manifest.istio_gateway
  ]
  manifest = yamldecode(data.local_file.istio_virtualservice.content)
}

