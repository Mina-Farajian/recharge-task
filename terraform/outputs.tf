output "minikube_ip" {
  value = chomp(trimspace(shell("minikube ip")))
  description = "Minikube node IP for curl testing"
}
