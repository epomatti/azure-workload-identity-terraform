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

locals {
  main_root_name           = "${var.application_name}-${var.environment}-${var.main_instance}"
  main_resource_group_name = "rg-${local.main_root_name}"
}

data "azurerm_client_config" "current" {}

### Secrets and ConfigMaps

data "azurerm_key_vault" "main" {
  name                = "kv-${local.main_root_name}"
  resource_group_name = local.main_resource_group_name
}

data "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.main_root_name}"
  resource_group_name = local.main_resource_group_name
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
  display_name = "aks-service-principal-${var.environment}"
}

resource "kubernetes_service_account" "default" {
  metadata {
    name      = "workload-identity-sa"
    namespace = "default"
    annotations = {
      "azure.workload.identity/client-id" = data.azuread_application.default.application_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}
