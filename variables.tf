variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-mpchenette-com"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Name of the Azure Web App (must be globally unique)"
  type        = string
  default     = "mpchenette-webapp"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)"
  type        = string
  default     = "mpchenettecr"
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = "mpchenette.com"
}

variable "cloudflare_zone_name" {
  description = "Cloudflare zone name (your domain)"
  type        = string
  default     = "mpchenette.com"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}
