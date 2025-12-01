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
