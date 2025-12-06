data "local_file" "istio_gateway" {
  filename = "./k8s/istio-gateway.yaml"
}

resource "kubernetes_manifest" "istio_gateway" {
  manifest = yamldecode(data.local_file.istio_gateway.content)
  depends_on = [helm_release.istio_ingress]
}

data "local_file" "istio_virtualservice" {
  filename = "./k8s/istio-virtualservice.yaml"
}

resource "kubernetes_manifest" "istio_virtualservice" {
  manifest = yamldecode(data.local_file.istio_virtualservice.content)
  depends_on = [kubernetes_manifest.istio_gateway, helm_release.app]
}
