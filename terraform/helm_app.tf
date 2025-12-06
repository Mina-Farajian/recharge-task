resource "helm_release" "app" {
  name       = "app"
  chart      = "./charts/"
  namespace  = "dev"
  create_namespace = true
}
