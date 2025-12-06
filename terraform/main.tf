resource "null_resource" "wait_for_istio_crds" {
  depends_on = [helm_release.istiod]

  provisioner "local-exec" {
    command = <<EOT
set -e
echo "Waiting for Istio CRDs..."
until kubectl get crd gateways.networking.istio.io >/dev/null 2>&1; do
  sleep 2
done
echo "Istio CRDs available."
EOT
  }
}


data "local_file" "istio_gateway" {
  filename = "../k8s/istio-gateway.yaml"
}

resource "kubernetes_manifest" "istio_gateway" {
  depends_on = [
    null_resource.wait_for_istio_crds,
    helm_release.istio_ingress
  ]
  manifest = yamldecode(data.local_file.istio_gateway.content)
}

data "local_file" "istio_virtualservice" {
  filename = "../k8s/istio-virtualservice.yaml"
}

resource "kubernetes_manifest" "istio_virtualservice" {
  depends_on = [
    kubernetes_manifest.istio_gateway,
    helm_release.app
  ]
  manifest = yamldecode(data.local_file.istio_virtualservice.content)
}


#This tells Terraform:
#“Hey, read this file and give me its contents as a string.”

# yamldecode(...) converts the YAML string → Terraform map.
# kubernetes_manifest takes that map and applies it to the cluster.
# So Terraform won't try to create a Gateway before Istio itself is ready.

#1- Terraform loads your YAML file

#2-Converts it into a manifest

#3-Applies it after Istio ingress gateway is installed
#custom resource difinitions are not installed by Istio Helm charts, they depend on the application you deploy