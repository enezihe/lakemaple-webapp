Project: Lake Maple Web Portal Migration (Azure Bicep)

Objective
Deliver a repeatable Azure provisioning baseline for a migrated web portal. The environment includes an App Service–hosted web application for a public landing page and admin access, an Azure SQL Database for relational application data, and a Storage Account for static assets such as images and PDF documents. The web tier is configured to reach the database using an encrypted connection and centralized application configuration.

Solution Overview
This deployment establishes a clean separation of concerns:
- Web tier: Hosts the portal entry points and provides the runtime boundary for future application releases.
- Data tier: Stores structured operational data in Azure SQL.
- Static content tier: Serves non-executable assets from blob storage for predictable performance and simplified content management.

Bicep Structure
- main.bicep: Orchestrates the deployment and wires service configurations.
- webapp.bicep: Provisions the App Service Plan and Web App with baseline security settings.
- storage.bicep: Provisions the Storage Account and a blob container for static assets.

Deployed Components
1) Web Tier (App Service)
- App Service Plan (Linux) and Web App
- HTTPS-only enabled
- Minimum TLS 1.2 enforced
- FTPS disabled

2) Data Tier (Azure SQL)
- Azure SQL Server and Azure SQL Database
- Baseline firewall rule allows Azure-hosted services to reach the database
- Web App connection string is applied through App Service configuration (connection strings) with Encrypt=True

3) Static Assets (Azure Storage)
- Storage Account (StorageV2)
- Blob container: static-assets
- Intended for images, rules PDFs, and other static files

Security Notes
- Web access is restricted to HTTPS with a minimum TLS posture.
- Database connectivity uses encrypted transport.
- Sensitive configuration is managed via App Service configuration rather than hardcoding in application code.
- Production hardening options: store secrets in Key Vault, enforce private connectivity (Private Endpoint/VNet integration), and replace broad firewall allowances with least-privilege network rules.

How to Deploy
1) Create resource group:
   az group create -n rg-lakemaple-bicep -l canadacentral

2) Deploy the Bicep template:
   az deployment group create -g rg-lakemaple-bicep -f bicep/main.bicep -p bicep/main.parameters.json

CI/CD Options (Implementation Approach)
The deployment command can be executed from an automation pipeline to standardize releases across environments. A lightweight approach is a repository-native workflow (e.g., GitHub Actions) that authenticates to Azure and runs the same deployment command on versioned infrastructure changes. An enterprise-oriented alternative is Azure DevOps Pipelines, which provides stronger centralized governance (environments, approvals, and audit controls) at the cost of additional platform configuration.

CI Automation (GitHub Actions)
A GitHub Actions workflow is included to validate the infrastructure template on every push. The pipeline compiles the Bicep template (az bicep build) to catch syntax and dependency issues early and to keep infrastructure changes reviewable and repeatable. Automated Azure deployments can be enabled by adding an Azure identity (service principal or federated credentials) with appropriate RBAC permissions and then running the same az deployment group create command in the workflow.

Data Movement / Transformation Approach
Operational data lives in Azure SQL while static content lives in Azure Storage. For reporting or downstream analytics, a pragmatic approach is to periodically extract or incrementally capture SQL changes, land data into a storage zone, and apply transformations as needs evolve. This keeps the transactional database optimized for application workloads while enabling flexible reporting pipelines over time.
