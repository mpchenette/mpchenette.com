# mpchenette.com

Minimal HTTP server in Rust (std only) returning plain text "Hello World". Deployed to Azure Container Apps with Cloudflare DNS.

## Local Development

```bash
cargo run                # Start server on :8000
curl localhost:8000      # Returns: Hello World
```

## Docker

```bash
docker build -t hello-world .
docker run -p 8000:8000 hello-world
```

**Image**: ~6MB (Rust → scratch, statically linked musl binary)

## Deploy to Azure

### Prerequisites
- Azure subscription
- Cloudflare account with domain
- GitHub repo with these secrets:
  - `AZURE_CREDENTIALS` - Service principal JSON
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_TENANT_ID`
  - `CLOUDFLARE_API_TOKEN`

### Setup

1. **Create Azure service principal:**
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-mpchenette" \
     --role contributor \
     --scopes /subscriptions/<SUBSCRIPTION_ID> \
     --sdk-auth
   ```

2. **Get Cloudflare API token:**
   - Go to [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
   - Permission: Zone > DNS > Edit
   - Zone: mpchenette.com

3. **Deploy:**
   ```bash
   git push origin main  # GitHub Actions handles the rest
   ```

### Manual Deployment

```bash
# Terraform
terraform init
terraform apply -var="cloudflare_api_token=YOUR_TOKEN"

# Build & push image
ACR=$(terraform output -raw container_registry_login_server)
az acr login --name mpchenettecr
docker build -t $ACR/hello-world:latest .
docker push $ACR/hello-world:latest

# Update container app
az containerapp update \
  --name $(terraform output -raw container_app_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --image $ACR/hello-world:latest
```

## Infrastructure

- **Azure Container Apps** - Serverless containers, 0.25 vCPU, 0.5GB RAM, scales 0-3
- **Azure Container Registry** - Stores Docker images
- **Cloudflare DNS** - Proxied CNAME to Azure (apex + www)

**Cost**: ~$7-12/month (scales to zero when idle)

## Management

```bash
# View logs
az containerapp logs show --name mpchenette-webapp --resource-group rg-mpchenette-webapp --follow

# Check status
az containerapp show --name mpchenette-webapp --resource-group rg-mpchenette-webapp --query "properties.runningStatus"

# Scale
az containerapp update --name mpchenette-webapp --resource-group rg-mpchenette-webapp --min-replicas 1 --max-replicas 5
```

## Files

- [src/main.rs](src/main.rs) - HTTP server
- [Cargo.toml](Cargo.toml) - Rust manifest (zero deps)
- [Dockerfile](Dockerfile) - Multi-stage build
- [main.tf](main.tf) - Infrastructure as code
- [.github/workflows/deploy.yml](.github/workflows/deploy.yml) - CI/CD pipeline
