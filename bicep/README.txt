Lake Maple Web Portal Migration Baseline (Azure Bicep)


1) Overview
This project provides a repeatable Azure provisioning baseline for migrating a small web portal. The environment includes:
- An App Service–hosted Web App for a public landing page and an admin entry point
- An Azure SQL Database for relational application data
- An Azure Storage Account for static assets such as images and PDF documents

The objective is to establish a clean, deployable foundation that can be promoted across environments using the same Infrastructure as Code entry point.


2) Architecture
The deployment follows a simple 3-tier separation:
- Web tier (App Service Web App): runtime boundary for future releases
- Data tier (Azure SQL Database): structured operational data
- Static tier (Azure Storage): non-executable assets served from blob storage

This structure keeps web releases independent, preserves the database for transactional workloads, and offloads static content to a dedicated service.


3) Infrastructure as Code (Bicep)
All infrastructure is defined using Azure Bicep. Resource naming uses a deterministic uniqueness pattern based on:
uniqueString(resourceGroup().id, namePrefix)

Bicep layout:
- bicep/main.bicep
  Orchestrates the deployment, wires configuration, and exposes outputs.
- bicep/webapp.bicep
  Creates the App Service Plan (Linux) and Web App with baseline settings:
  HTTPS-only, minimum TLS 1.2, FTPS disabled, Node 20 LTS runtime.
- bicep/storage.bicep
  Creates the Storage Account and a blob container named "static-assets".
- bicep/main.parameters.json
  Holds environment-specific values such as SQL admin credentials.


4) Key Configuration Decisions
Web App baseline:
- HTTPS-only enabled
- TLS 1.2 enforced
- FTPS disabled
- Linux runtime (Node 20 LTS)

Azure SQL baseline:
- Azure SQL Server + Azure SQL Database
- Firewall rule "AllowAzureServices" enabled for baseline connectivity
- Web App SQL connection string applied through App Service connection strings
  (encrypted transport via Encrypt=True)

Storage baseline:
- StorageV2 account
- Blob container: static-assets


5) Monitoring and Logging
To support operational visibility, the deployment includes:
- Log Analytics Workspace
- Diagnostic Settings forwarding:
  - Web App logs/metrics (HTTP, console/app logs, platform logs, AllMetrics)
  - SQL Server metrics and supported logs into the workspace

This enables centralized troubleshooting and basic operational reporting without changing application code.


6) Deployment Steps (Azure CLI)
1. Create the resource group:
   az group create -n rg-lakemaple-bicep -l canadacentral

2. Deploy the templates:
   az deployment group create -g rg-lakemaple-bicep -f bicep/main.bicep -p bicep/main.parameters.json


7) CI/CD (GitHub Actions)
Repository-native automation is used to validate infrastructure changes:
- .github/workflows/bicep-validate.yml
  Runs on push to main and executes az bicep build against bicep/main.bicep.

A typical deployment pipeline structure is:
checkout -> Azure authentication -> bicep build/validate -> az deployment group create

Note: Azure deployment from GitHub Actions requires an Azure identity with appropriate RBAC permissions.


8) Deployment Evidence (Sample Outputs)
- Web App URL: https://lakemaple-web-d7o3e2gevknog.azurewebsites.net
- SQL Server FQDN: lakemaple-sql-d7o3e2gevknog.database.windows.net
- SQL Database Name: lakemaple-db
- Storage Account Name: lakemaplestd7o3e2gevknog

Validation example:
curl -I https://lakemaple-web-d7o3e2gevknog.azurewebsites.net
(HTTP/1.1 200 OK)


9) Assumptions / Limitations
- This package focuses on infrastructure provisioning and baseline configuration.
- The SQL firewall posture is intentionally permissive for baseline connectivity and should be tightened for production
  (e.g., Private Endpoint/VNet integration and least-privilege access patterns).
