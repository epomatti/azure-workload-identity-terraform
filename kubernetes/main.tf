terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.22.0"
    }
  }
  backend "local" {
    path = "./.workspace/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
  }
}

locals {
  resource_group_name   = "rg-${var.app_name}"
  keyvault_name         = "kv-${var.app_name}"
  aks_name              = "aks-${var.app_name}"
  app_registration_name = "aks-${var.app_name}-service-principal"
  service_account_name  = "workload-identity-sa"
}

data "azurerm_client_config" "current" {}

### Secrets and ConfigMaps

data "azurerm_key_vault" "main" {
  name                = local.keyvault_name
  resource_group_name = local.resource_group_name
}

data "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_name
  resource_group_name = local.resource_group_name
}

provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.main.kube_config[0].host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_config_map" "default" {
  metadata {
    name = "solution-configmap"
  }
  data = {
    USE_KEYVAULT = true
    KEYVAULT_URL = data.azurerm_key_vault.main.vault_uri
  }
}


### App Registration for Workload Identity ###

data "azuread_application" "default" {
  display_name = local.app_registration_name
}

resource "kubernetes_service_account" "default" {
  metadata {
    name      = local.service_account_name
    namespace = "default"
    annotations = {
      "azure.workload.identity/client-id" = data.azuread_application.default.application_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}

resource "kubernetes_pod" "quick_start" {
  metadata {
    name      = "quick-start"
    namespace = "default"
  }

  spec {
    service_account_name = local.service_account_name
    container {
      image = "ghcr.io/azure/azure-workload-identity/msal-node"
      name  = "oidc"

      env {
        name  = "KEYVAULT_NAME"
        value = local.keyvault_name
      }

      env {
        name  = "SECRET_NAME"
        value = "my-secret"
      }
    }

    # node_selector = 

    # node_selector {
    #   kubernetes.io/os = "linux"
    # }
  }

  depends_on = [
    kubernetes_service_account.default
  ]

}
