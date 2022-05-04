terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.4.0"
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
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

### Local Variables

locals {
  app_name             = var.app_name
  aks_namespace        = "default"
  service_account_name = "workload-identity-sa"
}


### Resource Group

resource "azurerm_resource_group" "example" {
  name     = "rg-${local.app_name}"
  location = var.location
}


### Kubernetes Cluster

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-${local.app_name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  dns_prefix          = "aks-${local.app_name}"
  node_resource_group = "rg-k8s-${local.app_name}"

  oidc_issuer_enabled = true

  default_node_pool {
    name       = local.aks_namespace
    node_count = 1
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}


### Azure Active Directory

resource "azuread_application" "example" {
  display_name = "aks-${local.app_name}-service-principal"
}

resource "azuread_service_principal" "example" {
  application_id               = azuread_application.example.application_id
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "example" {
  application_object_id = azuread_application.example.object_id
  display_name          = "kubernetes-federated-credential"
  description           = "Kubernetes service account federated credential"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = azurerm_kubernetes_cluster.example.oidc_issuer_url
  subject               = "system:serviceaccount:${local.aks_namespace}:${local.service_account_name}"
}


### Key Vault

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                       = "kv-${local.app_name}"
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]
  }
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.example.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azuread_service_principal.example.object_id

  secret_permissions = [
    "Get"
  ]
}

resource "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  value        = "Hello!"
  key_vault_id = azurerm_key_vault.example.id
}


### Outputs

output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.example.name
}
