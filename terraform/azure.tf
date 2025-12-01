# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.workload}-${local.location_short}"
  location = var.location
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

  template {
    container {
      name   = "hello-world-app"
      image  = "mpchenette/mpchenette.com:latest"
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
