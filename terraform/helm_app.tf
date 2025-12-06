resource "helm_release" "app" {
  name       = "app"
  chart      = "./charts/app-chart"
  namespace  = "dev"
}
