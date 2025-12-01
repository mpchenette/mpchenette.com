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
