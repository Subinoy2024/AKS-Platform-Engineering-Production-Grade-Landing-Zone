resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.4"
  timeout    = 900

  values = [yamlencode({
    global = {
      domain = "argocd.${var.environment}.platform.internal"
    }
    configs = {
      params = {
        "server.insecure" = false
      }
      cm = {
        "timeout.reconciliation"      = "180s"
        "application.instanceLabelKey" = "argocd.argoproj.io/instance"
      }
    }
    server = {
      replicas = 2
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer"              = "letsencrypt-prod"
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
        }
        hosts = ["argocd.${var.environment}.platform.internal"]
        tls = [{
          secretName = "argocd-server-tls"
          hosts      = ["argocd.${var.environment}.platform.internal"]
        }]
      }
      autoscaling = {
        enabled     = true
        minReplicas = 2
        maxReplicas = 5
      }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }
    repoServer = {
      replicas = 2
      autoscaling = {
        enabled     = true
        minReplicas = 2
        maxReplicas = 5
      }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }
    applicationSet = {
      replicas = 2
    }
    controller = {
      replicas = 1
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    }
    redis-ha = {
      enabled = true
    }
  })]
}

####################################
# Root app-of-apps - bootstraps all GitOps applications
####################################

resource "kubernetes_manifest" "root_app" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-${var.environment}"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = "argocd/app-of-apps/${var.environment}"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true", "PrunePropagationPolicy=foreground"]
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }
}
