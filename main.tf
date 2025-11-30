terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 3.0" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 4.0" }
  }
}

provider "azurerm" {
  features {}
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Variables
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "mpchenette.com"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "southcentralus"
}

variable "workload" {
  description = "Workload name"
  type        = string
  default     = "mpchenette"
}

locals {
  location_short = "scus"  # southcentralus abbreviation
}

# Outputs
output "url" {
  value = "https://${var.domain}"
}

output "container_app_name" {
  value = azurerm_container_app.app.name
}

output "container_app_fqdn" {
  value = azurerm_container_app.app.latest_revision_fqdn
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "container_registry_name" {
  value = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.acr.login_server
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.workload}-${local.location_short}"
  location = var.location
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "cr${var.workload}${local.location_short}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${var.workload}-${local.location_short}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-${var.workload}-${local.location_short}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

# Container App
resource "azurerm_container_app" "app" {
  name                         = "ca-${var.workload}-${local.location_short}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "hello-world-app"
      image  = "${azurerm_container_registry.acr.login_server}/hello-world-app:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PORT"
        value = "8000"
      }

      env {
        name  = "RUNTIME_ENV"
        value = "Azure Container App"
      }
    }

    min_replicas = 0
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

}

# Custom Domain
resource "azurerm_container_app_custom_domain" "custom_domain" {
  name                     = var.domain
  container_app_id         = azurerm_container_app.app.id
  certificate_binding_type = "Disabled"
  depends_on               = [cloudflare_record.root]
}

# Cloudflare DNS
data "cloudflare_zone" "domain" {
  name = var.domain
}

resource "cloudflare_record" "root" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "@"
  content = azurerm_container_app.app.latest_revision_fqdn
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "www"
  content = var.domain
  type    = "CNAME"
  proxied = true
}
