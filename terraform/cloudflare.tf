# Cloudflare DNS
data "cloudflare_zone" "domain" {
  name = var.domain
}

resource "cloudflare_record" "root" {
  zone_id         = data.cloudflare_zone.domain.id
  name            = "@"
  content         = azurerm_container_app.app.latest_revision_fqdn
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "cloudflare_record" "www" {
  zone_id         = data.cloudflare_zone.domain.id
  name            = "www"
  content         = var.domain
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}
