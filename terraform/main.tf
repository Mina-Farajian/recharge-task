
resource "kubernetes_namespace" "dev_app" {
  metadata {
    name = "dev"
  }
}

# The 'istio-system' namespace will be created by the 'helm install' command in deploy.sh.
/*
resource "aws_s3_bucket" "my_app_storage" {
  bucket = "recharge-task-bucket"
}
*/

