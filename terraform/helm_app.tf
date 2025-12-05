resource "helm_release" "app" {
  name       = "app"
  chart      = "${path.module}/../charts/app-chart"
  namespace  = "default"

  values = [
    yamlencode({
      replicaCount = 2
      image = {
        repository = "app"
        tag        = "latest"
        pullPolicy = "IfNotPresent"
      }
      service = {
        type = "ClusterIP"
        port = 8080
      }
    })
  ]
}
