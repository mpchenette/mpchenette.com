output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.app.name
}

output "container_app_fqdn" {
  description = "Fully qualified domain name of the Container App"
  value       = azurerm_container_app.app.latest_revision_fqdn
}

output "container_app_url" {
  description = "URL of the Container App"
  value       = "https://${azurerm_container_app.app.latest_revision_fqdn}"
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "custom_domain" {
  description = "Custom domain configured for the app"
  value       = var.domain_name
}

output "custom_domain_url" {
  description = "URL of the custom domain"
  value       = "https://${var.domain_name}"
}
