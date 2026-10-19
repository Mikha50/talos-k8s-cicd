terraform {
  required_version = ">= 1.5.0"

  # حفظ الـ State تلقائياً داخل Kubernetes Secret دائم ومحمي
  backend "kubernetes" {
    secret_suffix     = "prod-app-state"
    namespace         = "jenkins"
    in_cluster_config = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
  }
}

provider "kubernetes" {
}

# 1. إنشاء الـ Namespace الخاص بالتطبيق
resource "kubernetes_namespace" "prod_app" {
  metadata {
    name = "production-app"
    labels = {
      environment = "production"
      managed-by  = "terraform-jenkins"
    }
  }
}

# 2. إنشاء قرص التخزين الموزع عبر Longhorn
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-data-pvc"
    namespace = kubernetes_namespace.prod_app.metadata[0].name
    labels = {
      app = "postgres"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

# 3. إنشاء الـ Secret المشفر لبيانات قاعدة البيانات
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.prod_app.metadata[0].name
  }

  data = {
    POSTGRES_DB       = "devops_db"
    POSTGRES_USER     = "dbadmin"
    POSTGRES_PASSWORD = "SuperSecureTalosPassword2026!"
  }

  type = "Opaque"
}

output "namespace" {
  value = kubernetes_namespace.prod_app.metadata[0].name
}

output "pvc_name" {
  value = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
}
