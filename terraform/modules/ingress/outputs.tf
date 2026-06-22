output "ingress_namespace" { value = kubernetes_namespace.ingress.metadata[0].name }
output "cert_manager_namespace" { value = kubernetes_namespace.cert_manager.metadata[0].name }
