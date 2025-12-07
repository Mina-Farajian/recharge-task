
resource "kubernetes_namespace" "dev_app" {
  metadata {
    name = "dev"
  }
}


