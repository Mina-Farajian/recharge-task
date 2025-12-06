variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}
variable "minikube_ip" {
  type = string
}

variable "istio_chart_repo" {
  description = "Istio Helm chart repo URL"
  type        = string
  default     = "https://istio-release.storage.googleapis.com/charts"
}

variable "istio_version" {
  description = "Istio chart version (optional)"
  type        = string
  default     = ""
}

variable "app_image" {
  description = "Container image for the app"
  type        = string
  default     = "recharge-task/app:latest"
}

variable "app_release_name" {
  description = "Helm release name for the app"
  type        = string
  default     = "my-app"
}

variable "app_namespace" {
  type    = string
  default = "dev"
}