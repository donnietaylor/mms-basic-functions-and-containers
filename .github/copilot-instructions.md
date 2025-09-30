# Copilot Instructions for Azure Functions and Container Apps Demo Repository

## Repository Overview

Progressive 4-demo series for Azure Functions and Container Apps: (1) Simple HTTP Function, (2) Function with Storage, (3) PowerShell Container App, (4) Integrated Solution. All code uses **PowerShell 7.2**. ~1,342 lines across PowerShell, Terraform, and configs.

**Tech Stack:** PowerShell 7.2, Terraform, Docker, Azure Functions (Consumption/Linux), Azure Container Apps, Azure Blob Storage, GitHub Actions

**Structure:** `functions/demo[1-4]/` (PowerShell Functions), `containers/demo[3-4]/` (Docker containers), `terraform/demo[1-4]/` (IaC), `.github/workflows/` (CI/CD)

**Key Files:**
- Functions: `functions/demo[X]/HttpTrigger/run.ps1` (logic), `function.json` (bindings), `host.json` (config), `requirements.psd1` (modules)
- Containers: `containers/demo[X]/{app,api}.ps1` (server), `start.ps1` (entry), `Dockerfile`
- Terraform: `terraform/demo[X]/{main,variables,outputs}.tf`
- Workflows: `.github/workflows/demo[X]*.yml`

## Build & Deployment - CRITICAL

**NO LOCAL BUILD/TEST COMMANDS EXIST.** This is Azure-deployment-only. All validation via GitHub Actions workflows.

### Container Building (Validation Only)

```bash
cd containers/demo3-simple  # or demo4-api
docker build -t demo3-local .
# Build time: 40-50s, Result: ~336MB image
# Warning (ignore): "No match... Microsoft.PowerShell.UnixCompleters"
```

**Base image:** `mcr.microsoft.com/powershell:7.2-ubuntu-20.04`, **Port:** 8080

### PowerShell Functions

**Cannot run locally** - scripts require Azure Functions runtime types (`[HttpResponseContext]`, `Push-OutputBinding`). Direct `pwsh` execution will fail.

### Terraform

**Prerequisites:** Terraform 1.5.0, Azure CLI (`az login`), Contributor role

```bash
cd terraform/demo[1-4]
terraform init                                    # Download providers
terraform plan -no-color -input=false            # Validate
terraform apply -auto-approve -input=false       # Deploy
terraform destroy --auto-approve                  # Cleanup
```

**Provider:** `hashicorp/azurerm ~>3.0`

### GitHub Actions Workflows

**Manual trigger only** (`workflow_dispatch`). Pattern: (1) Terraform → (2) Deploy → (3) Test

**Required Secret:** `AZURE_CREDENTIALS` (Service Principal JSON)

**Execution Times:**
- Demo 1: 3-5 min | Demo 2: 5-7 min | Demo 3: 7-10 min | Demo 4: 12-15 min

**CRITICAL WAIT TIMES** (main failure cause):
- Functions: 30s (demo1), 45s (demo2)
- Container Apps: **60s minimum** (demo3)
- Integrated: **90s** (demo4) - Container Apps need more stabilization time than Functions

## Configuration Essentials

**host.json:** `version: 2.0`, extensionBundle `[3.*, 4.0.0)`, timeout `00:05:00`, `managedDependency: enabled`

**requirements.psd1:** Demo1: none, Demo2: `'Az.Storage' = '5.*'`, Demo4: integration modules

**function.json:** `authLevel: anonymous`, methods: GET/POST, bindings: httpTrigger (in), http (out)

**Dockerfile pattern:** Base `mcr.microsoft.com/powershell:7.2-ubuntu-20.04` → Install modules → Copy scripts → `chmod +x` → Expose 8080 → Entry `pwsh /app/start.ps1`

**Resource Naming (Terraform):**
- RG: `rg-mms-demo[1-4]` | Functions: `func-mms-demo[1-4]` | ASP: `asp-mms-demo[1-4]`
- Storage: `stmmsdemo[1-4]`, `stdatamms[2,4]` (no hyphens, globally unique)
- ACR: `acrmmsdemo[3-4]` (no hyphens) | Containers: `ca-mms-demo[3-4]`
- Location: `East US` (default)

## Testing & Validation

**Automated workflow tests** use `curl -f` (fails on HTTP errors):
- **Demo 1:** Default + name param tests
- **Demo 2:** Default, store message, list messages
- **Demo 3:** Root `/`, `/health`, `/echo`, `/info`, `/time`
- **Demo 4:** Individual services + Function↔Container integration + shared storage + analytics

**Manual Azure CLI checks:**
```bash
az account show                                   # Verify login
az functionapp list --output table                # List functions
az containerapp list --output table               # List containers
az containerapp logs show --name ca-mms-demo3 --resource-group rg-mms-demo3  # View logs
az group delete --name rg-mms-demo1 --yes --no-wait  # Cleanup
```

## Common Issues & Solutions

**Deployment failures:** Check `AZURE_CREDENTIALS` secret (Service Principal JSON), verify resource naming uniqueness (storage/ACR), confirm Contributor role

**Functions won't start:** Check PowerShell syntax in `run.ps1`, verify `requirements.psd1` modules, review Application Insights logs in Azure Portal

**Container build fails:** Test locally with `docker build` first, ignore `Microsoft.PowerShell.UnixCompleters` warning, verify script permissions

**Integration test failures (Demo 4):** #1 cause is insufficient wait time. **Always wait 90+ seconds** for integrated services. Container Apps need more time than Functions. Check `CONTAINER_APP_URL` and `FUNCTION_APP_URL` env vars.

**Container update fails:** Always run `az containerapp registry set --identity system` before `az containerapp update` (see workflows for exact commands)

## Architecture Patterns

**Demo 1:** Basic HTTP trigger | Resources: RG + Storage (runtime) + ASP (Y1/Consumption) + Function App | Single `run.ps1`, no dependencies

**Demo 2:** Function + external storage | Demo1 resources + data Storage Account + Blob Container | Uses `Az.Storage` module | App setting: `DataStorageConnection`

**Demo 3:** Containerized HTTP API | ACR + Log Analytics + Container Apps Environment + Container App | Custom HTTP listener (`System.Net.HttpListener`) | Deploy: Build→Push to ACR→Update Container App with managed identity

**Demo 4:** Microservices + shared storage | Function + Container + Shared Storage + ACR + Log Analytics
- Function→Container: HTTP via `CONTAINER_APP_URL` env var
- Container→Function: HTTP via `FUNCTION_APP_URL` env var
- Both→Storage: Blob ops via connection strings
- Function settings: `CONTAINER_APP_URL`, `SharedStorageConnection`
- Container env vars: `FUNCTION_APP_URL`, `SHARED_STORAGE_CONNECTION`

## Modification Guidelines

**PowerShell Functions:**
- Edit: `functions/demo[X]/HttpTrigger/run.ps1` (logic), `requirements.psd1` (modules), `host.json` (rare)
- **Cannot test locally** - deploy via workflow to validate

**Containers:**
- Edit: `containers/demo[X]/{app,api}.ps1` (logic), `start.ps1` (rare), `Dockerfile` (rare)
- **Always test locally:** `docker build -t test:local .` before committing

**Terraform:**
- Edit: `terraform/demo[X]/main.tf` (resources), `variables.tf` (inputs), `outputs.tf` (exports)
- **Validate:** Run `terraform plan` locally before committing, actual deploy via workflow

**Workflows:**
- Edit: `.github/workflows/demo[X]*.yml`
- **Maintain:** Wait times (30-90s), `continue-on-error: true` on plan steps, test URLs, manual trigger only

## Critical Rules

**ALWAYS:**
1. Validate container builds with `docker build` before committing container changes
2. Wait adequate time (30-90s) for services to stabilize before testing
3. Use managed identity for Container Apps ACR authentication (`az containerapp registry set --identity system`)
4. Check resource naming - storage accounts and ACRs require lowercase, alphanumeric, globally unique names
5. Test via GitHub Actions workflows after changes

**NEVER:**
1. Run PowerShell function scripts directly with `pwsh` (requires Azure Functions runtime)
2. Add package.json, build scripts, or test frameworks (not used)
3. Commit local.settings.json, .terraform/, state files (in .gitignore)
4. Force push or modify resource names without ensuring global uniqueness

**When in doubt:** Review README.md, test Docker builds locally first, run `terraform plan`, check workflow wait times/URL patterns

This repository is for progressive learning - maintain consistency across demos while building complexity from demo 1→4.
