# Azure Functions and Container Apps Demo Series

This repository contains a progressive series of demos for learning Azure Functions and Container Apps, specifically designed for attendees with zero Azure experience. All functions are built using PowerShell (pwsh) for consistency and ease of understanding.

## 🎯 Demo Series Overview

The demos progress from simple to complex, building understanding step-by-step:

1. **Demo 1** - Simple HTTP Trigger Function
2. **Demo 2** - Function with Azure Storage Integration  
3. **Demo 3** - PowerShell Container App with HTTP API
4. **Demo 4** - Integrated Solution (Function App + Container App + Shared Storage)

## 🏗️ Repository Structure

```
├── functions/                      # Azure Functions code
│   ├── demo1-simple/              # Basic HTTP trigger function
│   ├── demo2-storage/             # Function with storage integration
│   └── demo4-integrated/          # Integrated solution function
├── containers/                     # Container Apps code
│   ├── demo3-simple/              # Basic PowerShell API container
│   └── demo4-api/                 # Advanced API container for integration
├── terraform/                      # Infrastructure as Code
│   ├── demo1/                     # Simple Function App infrastructure
│   ├── demo2/                     # Function + Storage infrastructure
│   ├── demo3/                     # Container Apps infrastructure
│   └── demo4/                     # Integrated solution infrastructure
└── .github/workflows/              # GitHub Actions deployment pipelines
    ├── demo1-function.yml
    ├── demo2-function-storage.yml
    ├── demo3-container.yml
    └── demo4-integrated.yml
```

## 📋 Prerequisites

### Required Azure Resources
- Azure Subscription
- Resource Group access or ability to create resource groups
- Contributor role in the subscription

### Required Secrets (GitHub Repository)
Set up the following secret in your GitHub repository:

1. **AZURE_CREDENTIALS**: Service Principal credentials for Azure authentication
   ```json
   {
     "clientId": "your-client-id",
     "clientSecret": "your-client-secret", 
     "subscriptionId": "your-subscription-id",
     "tenantId": "your-tenant-id"
   }
   ```

### Create Service Principal
```bash
az ad sp create-for-rbac --name "mms-demo-sp" --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth
```

## 🚀 Demo Details

### Demo 1: Simple HTTP Trigger Function ⚡

**Learning Goals:** Basic Azure Functions, HTTP triggers, PowerShell in the cloud

**What it does:**
- Simple HTTP endpoint that responds with "Hello World"
- Accepts optional `name` parameter for personalized greeting
- Demonstrates basic Function App deployment

**Infrastructure:**
- Resource Group
- Storage Account (for Function App runtime)
- App Service Plan (Consumption)
- Linux Function App with PowerShell 7.2

**Test it:**
```bash
# Basic greeting
curl "https://func-mms-demo1.azurewebsites.net/api/HttpTrigger"

# Personalized greeting  
curl "https://func-mms-demo1.azurewebsites.net/api/HttpTrigger?name=YourName"
```

**Deploy:** Push changes to `functions/demo1-simple/` or `terraform/demo1/`

---

### Demo 2: Function with Storage Integration 💾

**Learning Goals:** Azure Storage integration, PowerShell modules, data persistence

**What it does:**
- Store and retrieve messages in Azure Blob Storage
- Demonstrates Az.Storage PowerShell module usage
- JSON responses for better API experience

**Infrastructure:**
- Everything from Demo 1, plus:
- Additional Storage Account for data
- Blob Container with public read access
- Enhanced Function App configuration

**Test it:**
```bash
# Store a message
curl -X POST "https://func-mms-demo2.azurewebsites.net/api/HttpTrigger?action=store&message=Hello%20MMS!"

# List all messages
curl "https://func-mms-demo2.azurewebsites.net/api/HttpTrigger?action=list"

# View help
curl "https://func-mms-demo2.azurewebsites.net/api/HttpTrigger"
```

**Deploy:** Push changes to `functions/demo2-storage/` or `terraform/demo2/`

---

### Demo 3: PowerShell Container App 🐳

**Learning Goals:** Container Apps, containerized PowerShell, HTTP APIs, Docker

**What it does:**
- PowerShell-based HTTP API running in a container
- Multiple endpoints for different functionality
- Demonstrates Container Apps scaling and ingress

**Infrastructure:**
- Resource Group
- Log Analytics Workspace
- Azure Container Registry
- Container Apps Environment  
- Container App with external ingress

**Container Features:**
- PowerShell 7.2 runtime
- Multiple API endpoints
- Request logging and analytics
- Health checks

**Test it:**
```bash
# Basic info
curl "https://ca-mms-demo3.{region}.azurecontainerapps.io/"

# Health check
curl "https://ca-mms-demo3.{region}.azurecontainerapps.io/health"

# Echo service
curl "https://ca-mms-demo3.{region}.azurecontainerapps.io/echo?message=Hello%20Container%20Apps!"

# System info
curl "https://ca-mms-demo3.{region}.azurecontainerapps.io/info"

# Current time
curl "https://ca-mms-demo3.{region}.azurecontainerapps.io/time"
```

**Deploy:** Push changes to `containers/demo3-simple/` or `terraform/demo3/`

---

### Demo 4: Integrated Solution 🔗

**Learning Goals:** Microservices architecture, service-to-service communication, shared resources

**What it does:**
- Function App and Container App working together
- Shared storage for data exchange
- Cross-service communication
- Message passing between services
- Analytics and monitoring

**Architecture:**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Function App  │◄──►│  Shared Storage  │◄──►│  Container App  │
│                 │    │                  │    │                 │
│ - HTTP Triggers │    │ - Blob Storage   │    │ - HTTP API      │
│ - Storage Ops   │    │ - Integration    │    │ - Message Queue │
│ - Integration   │    │   Data Exchange  │    │ - Analytics     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

**Infrastructure:**
- Resource Group
- Function App with PowerShell 7.2
- Container App with PowerShell API
- Shared Storage Account
- Container Registry
- Log Analytics Workspace
- Container Apps Environment

**Integration Features:**
- **Function → Container**: HTTP requests, message sending
- **Container → Function**: Health checks, data retrieval
- **Shared Storage**: Data exchange medium
- **Analytics**: Request tracking and monitoring

**Test the Integration:**
```bash
# Test Function App
curl "https://func-mms-demo4.azurewebsites.net/api/HttpTrigger?name=Demo4"

# Test Container App  
curl "https://ca-mms-demo4.{region}.azurecontainerapps.io/"

# Test Function → Container integration
curl "https://func-mms-demo4.azurewebsites.net/api/HttpTrigger?action=container-ping"

# Test messaging between services
curl "https://func-mms-demo4.azurewebsites.net/api/HttpTrigger?action=notify-container&data=Hello%20from%20Function!"

# Test shared storage
curl "https://func-mms-demo4.azurewebsites.net/api/HttpTrigger?action=store-shared&data=SharedData&name=Integration"

# Test Container → Function integration  
curl "https://ca-mms-demo4.{region}.azurecontainerapps.io/integration"

# View analytics
curl "https://ca-mms-demo4.{region}.azurecontainerapps.io/analytics"
```

**Deploy:** Push changes to `functions/demo4-integrated/`, `containers/demo4-api/`, or `terraform/demo4/`

## 🔧 Local Development

### Testing Functions Locally
```bash
# Navigate to function directory
cd functions/demo1-simple

# Install Azure Functions Core Tools (if not installed)
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Start local development server
func start
```

### Building Containers Locally
```bash
# Navigate to container directory
cd containers/demo3-simple

# Build the container
docker build -t demo3-local .

# Run locally
docker run -p 8080:8080 demo3-local

# Test locally
curl http://localhost:8080/
```

### Terraform Local Planning
```bash
# Navigate to terraform directory
cd terraform/demo1

# Initialize Terraform
terraform init

# Plan deployment (requires Azure CLI login)
az login
terraform plan

# Apply (if desired)
terraform apply
```

## 📚 Learning Path

### For Complete Beginners
1. **Start with Demo 1** - Understand basic concepts
2. **Review the Terraform** - See infrastructure as code
3. **Examine the PowerShell** - Understand the function logic
4. **Run Demo 1** - Deploy and test your first Function App

### Progressive Learning
1. **Demo 1** → **Demo 2**: Learn storage integration
2. **Demo 2** → **Demo 3**: Transition to containers
3. **Demo 3** → **Demo 4**: Understand microservices

### Key Concepts Covered
- ✅ Azure Functions (Consumption Plan)
- ✅ PowerShell in Azure Functions
- ✅ HTTP Triggers and Bindings
- ✅ Azure Blob Storage
- ✅ Container Apps
- ✅ Docker with PowerShell
- ✅ Azure Container Registry
- ✅ Terraform Infrastructure as Code
- ✅ GitHub Actions CI/CD
- ✅ Service-to-Service Communication
- ✅ Shared Storage Patterns
- ✅ Microservices Architecture

## 🛠️ Troubleshooting

### Common Issues

**Deployment Fails**
- Check Azure credentials in GitHub Secrets
- Verify resource naming (must be globally unique for some resources)
- Check Azure subscription permissions

**Functions Don't Start**
- Check PowerShell syntax in `run.ps1`
- Verify `requirements.psd1` modules
- Check `host.json` configuration

**Container Build Fails**
- Verify Dockerfile syntax
- Check PowerShell script permissions
- Ensure base image availability

**Integration Tests Fail**
- Wait longer for services to start (especially Container Apps)
- Check service URLs in environment variables
- Verify network connectivity between services

### Useful Commands

```bash
# Check Azure CLI login
az account show

# List resource groups
az group list --output table

# Check Function App status
az functionapp list --output table

# Check Container App status  
az containerapp list --output table

# View logs
az containerapp logs show --name ca-mms-demo3 --resource-group rg-mms-demo3

# Clean up resources
az group delete --name rg-mms-demo1 --yes --no-wait
```

## 🧹 Cleanup

To remove all demo resources:

```bash
# Delete all demo resource groups
az group delete --name rg-mms-demo1 --yes --no-wait
az group delete --name rg-mms-demo2 --yes --no-wait  
az group delete --name rg-mms-demo3 --yes --no-wait
az group delete --name rg-mms-demo4 --yes --no-wait
```

Or use Terraform:
```bash
# In each demo directory
terraform destroy --auto-approve
```

## 📖 Additional Resources

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [PowerShell in Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

---

**Happy Learning! 🚀**

This demo series provides hands-on experience with modern Azure serverless and container technologies using PowerShell. Start with Demo 1 and progress through each demo to build comprehensive understanding of Azure Functions and Container Apps.