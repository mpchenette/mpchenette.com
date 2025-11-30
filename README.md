# mpchenette.com

## Hello World Rust App

A minimal HTTP server written in pure Rust (only std library) that returns plain text "Hello World". The Docker image is built from scratch for maximum efficiency (~6MB).

### Prerequisites

- **For Local Development**: Rust 1.75+ ([Install Rust](https://rustup.rs/))
- **For Docker**: Docker installed ([Get Docker](https://docs.docker.com/get-docker/))

### Local Development

1. **Run the server:**
   ```bash
   cargo run
   ```

2. **Test it:**
   ```bash
   curl http://localhost:8000
   # Output: Hello World
   ```

### Docker Quick Start

1. **Build the Docker image:**
   ```bash
   docker build -t hello-world-app .
   ```

2. **Run the container:**
   ```bash
   docker run -p 8000:8000 hello-world-app
   ```

3. **View the app:**
   ```bash
   curl http://localhost:8000
   # Or open http://localhost:8000 in your browser
   ```

### Stop the Container

Press `Ctrl+C` in the terminal, or run:
```bash
docker ps  # Find the container ID
docker stop <container-id>
```

### Run in Detached Mode

To run the container in the background:
```bash
docker run -d -p 8000:8000 --name hello-app hello-world-app
```

Stop it with:
```bash
docker stop hello-app
docker rm hello-app
```

### Docker Image Details

- **Build Type**: Multi-stage build with Rust + scratch base
- **Target**: `x86_64-unknown-linux-musl` (statically linked)
- **Final Image Size**: ~6MB
- **Dependencies**: Zero (only Rust std library)
- **Port**: 8000

## Deployment to Azure

This project includes Terraform configuration and GitHub Actions workflow for automatic deployment to Azure with Cloudflare DNS management.

### Prerequisites for Deployment

1. **Azure Account** with an active subscription
2. **Cloudflare Account** with mpchenette.com domain registered
3. **GitHub Repository** with secrets configured
4. **Azure CLI** and **Terraform** installed locally (for manual deployment)

### Azure Setup

1. **Create a Service Principal for GitHub Actions:**
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-mpchenette" \
     --role contributor \
     --scopes /subscriptions/<SUBSCRIPTION_ID> \
     --sdk-auth
   ```
   Save the JSON output for GitHub secrets.

2. **Get your Azure credentials:**
   ```bash
   az account show
   ```

### Cloudflare Setup

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Create a new token with:
   - Permission: Zone > DNS > Edit
   - Zone Resources: Include > Specific zone > mpchenette.com
3. Save the token for GitHub secrets and Terraform

### GitHub Secrets Configuration

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

```
AZURE_CREDENTIALS           # Full JSON output from service principal creation
AZURE_CLIENT_ID             # From service principal JSON
AZURE_CLIENT_SECRET         # From service principal JSON
AZURE_SUBSCRIPTION_ID       # Your Azure subscription ID
AZURE_TENANT_ID             # Your Azure tenant ID
CLOUDFLARE_API_TOKEN        # Your Cloudflare API token
```

### Deploy with GitHub Actions

Push to main branch:
```bash
git add .
git commit -m "Deploy to Azure"
git push origin main
```

The GitHub Actions workflow will:
1. Run Terraform to provision Azure resources
2. Build and push Docker image to Azure Container Registry
3. Deploy to Azure Web App
4. Configure Cloudflare DNS to point to your app

### Manual Deployment with Terraform

1. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

5. **Build and push Docker image:**
   ```bash
   # Login to Azure
   az login

   # Get ACR credentials
   ACR_NAME=$(terraform output -raw container_registry_name)
   az acr login --name $ACR_NAME

   # Build and push
   ACR_SERVER=$(terraform output -raw container_registry_login_server)
   docker build -t $ACR_SERVER/hello-world-app:latest .
   docker push $ACR_SERVER/hello-world-app:latest
   ```

6. **Update the Container App:**
   ```bash
   CONTAINER_APP_NAME=$(terraform output -raw container_app_name)
   RESOURCE_GROUP=$(terraform output -raw resource_group_name)
   ACR_SERVER=$(terraform output -raw container_registry_login_server)

   az containerapp update \
     --name $CONTAINER_APP_NAME \
     --resource-group $RESOURCE_GROUP \
     --image $ACR_SERVER/hello-world-app:latest
   ```

### Infrastructure Components

The Terraform configuration creates:
- **Resource Group**: Container for all Azure resources
- **Container Registry**: Stores Docker images (Basic SKU)
- **Log Analytics Workspace**: For Container Apps monitoring and logging
- **Container Apps Environment**: Managed environment for container apps
- **Container App**: Serverless container with auto-scaling (0-3 replicas)
- **Cloudflare DNS**: CNAME records pointing to Azure Container App
- **Custom Domain**: mpchenette.com configured on the Container App

### Container App Features

- **Auto-scaling**: Scales from 0 to 3 replicas based on demand (saves costs when idle)
- **CPU**: 0.25 cores per replica
- **Memory**: 0.5 GB per replica
- **Port**: Exposed on 3000 with external ingress enabled
- **HTTPS**: Automatic HTTPS via Azure-managed certificates

### DNS Configuration

Cloudflare DNS records created:
- `@` (apex) → CNAME to Azure Container App FQDN (proxied)
- `www` → CNAME to apex domain (proxied)

### Monitoring and Management

**View logs (live streaming):**
```bash
az containerapp logs show \
  --name mpchenette-webapp \
  --resource-group rg-mpchenette-com \
  --follow
```

**Check Container App status:**
```bash
az containerapp show \
  --name mpchenette-webapp \
  --resource-group rg-mpchenette-com \
  --query "properties.runningStatus"
```

**View current replicas:**
```bash
az containerapp revision list \
  --name mpchenette-webapp \
  --resource-group rg-mpchenette-com \
  --query "[].{Name:name, Replicas:properties.replicas, Active:properties.active}"
```

**Scale the app (adjust min/max replicas):**
```bash
az containerapp update \
  --name mpchenette-webapp \
  --resource-group rg-mpchenette-com \
  --min-replicas 1 \
  --max-replicas 5
```

**View all revisions:**
```bash
az containerapp revision list \
  --name mpchenette-webapp \
  --resource-group rg-mpchenette-com \
  --output table
```

### Cost Optimization

Current configuration uses:
- **Container Apps**: Pay-per-use (scales to zero when idle)
  - vCPU: ~$0.000024/second (~$1.85/month if running 24/7)
  - Memory: ~$0.000003/second (~$0.23/month if running 24/7)
  - Estimated: ~$2-5/month with auto-scaling
- **Log Analytics**: First 5GB free, then ~$2.76/GB
- **Basic Container Registry**: ~$5/month
- **Cloudflare Free Plan**: $0

**Total: ~$7-12/month** (significantly cheaper than App Service!)

Benefits of Container Apps:
- Scales to zero when not in use (saves ~70% compared to App Service)
- Only pay for actual usage
- Automatic HTTPS and certificate management
- Built-in load balancing

To destroy all resources:
```bash
terraform destroy
```

### Files

**Application:**
- [src/main.rs](src/main.rs) - Rust HTTP server (only std library)
- [Cargo.toml](Cargo.toml) - Rust package manifest (zero dependencies)
- [Dockerfile](Dockerfile) - Multi-stage build: Rust → scratch
- [.dockerignore](.dockerignore) - Files to exclude from Docker image

**Infrastructure:**
- [main.tf](main.tf) - Terraform main configuration
- [variables.tf](variables.tf) - Terraform variables
- [outputs.tf](outputs.tf) - Terraform outputs
- [backend.tf](backend.tf) - Terraform state backend configuration
- [terraform.tfvars.example](terraform.tfvars.example) - Example variables file

**CI/CD:**
- [.github/workflows/deploy.yml](.github/workflows/deploy.yml) - GitHub Actions deployment workflow