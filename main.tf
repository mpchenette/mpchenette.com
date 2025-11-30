terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Log Analytics Workspace (required for Container Apps)
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.app_name}-logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "${var.app_name}-env"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Container App
resource "azurerm_container_app" "app" {
  name                         = var.app_name
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

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Custom Domain for Container App
resource "azurerm_container_app_custom_domain" "custom_domain" {
  name             = var.domain_name
  container_app_id = azurerm_container_app.app.id

  # Certificate binding will be handled separately or via Cloudflare
  certificate_binding_type = "Disabled"

  depends_on = [cloudflare_record.cname]
}

# Get Cloudflare Zone
data "cloudflare_zone" "domain" {
  name = var.cloudflare_zone_name
}

# Cloudflare DNS Record (CNAME to Azure Container App)
resource "cloudflare_record" "cname" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "@"
  content = azurerm_container_app.app.latest_revision_fqdn
  type    = "CNAME"
  ttl     = 1
  proxied = true

  comment = "Managed by Terraform - Points to Azure Container App"
}

# Cloudflare DNS Record (www subdomain)
resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "www"
  content = var.domain_name
  type    = "CNAME"
  ttl     = 1
  proxied = true

  comment = "Managed by Terraform - Redirects www to apex domain"
}
