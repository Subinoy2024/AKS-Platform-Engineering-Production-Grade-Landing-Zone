resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.1"
  timeout    = 600

  values = [yamlencode({
    controller = {
      replicaCount = 3
      service = {
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
        }
      }
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "10254"
      }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
      autoscaling = {
        enabled     = true
        minReplicas = 3
        maxReplicas = 10
      }
      podDisruptionBudget = {
        enabled      = true
        minAvailable = 2
      }
    }
  })]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.5"
  timeout    = 600

  values = [yamlencode({
    installCRDs = true
    replicaCount = 2
    prometheus = {
      enabled = true
      servicemonitor = {
        enabled = true
      }
    }
  })]
}
