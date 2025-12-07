

# --- 2. Namespace Creation ---
# Create the 'dev' namespace for your application, where Istio sidecar injection is enabled later.
resource "kubernetes_namespace" "dev_app" {
  metadata {
    name = "dev"
  }
}

# The 'istio-system' namespace will be created by the 'helm install' command in deploy.sh.


# --- 3. AWS Mock Resources (Example Placeholder) ---
# Replace this section with your actual AWS mock configuration using a provider like 'aws-mock' or 'local-exec'
# Example: Create an S3 Bucket or other resources your app needs to mock.

resource "aws_s3_bucket" "my_app_storage" {
  bucket = "recharge-task-bucket"
}

