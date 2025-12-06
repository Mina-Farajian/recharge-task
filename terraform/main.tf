
#This tells Terraform:
  #“Hey, read this file and give me its contents as a string.”

data "local_file" "istio_gateway" {
  filename = "./k8s/istio-gateway.yaml"
}

resource "kubernetes_manifest" "istio_gateway" {
  manifest = yamldecode(data.local_file.istio_gateway.content)
  depends_on = [helm_release.istio_ingress]
}
# yamldecode(...) converts the YAML string → Terraform map.
# kubernetes_manifest takes that map and applies it to the cluster.
# So Terraform won't try to create a Gateway before Istio itself is ready.


data "local_file" "istio_virtualservice" {
  filename = "./k8s/istio-virtualservice.yaml"
}

resource "kubernetes_manifest" "istio_virtualservice" {
  manifest = yamldecode(data.local_file.istio_virtualservice.content)
  depends_on = [kubernetes_manifest.istio_gateway, helm_release.app]
}

#1- Terraform loads your YAML file

#2-Converts it into a manifest

#3-Applies it after Istio ingress gateway is installed
#custom resource difinitions are not installed by Istio Helm charts, they depend on the application you deploy