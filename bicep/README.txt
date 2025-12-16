## Lake Maple Web Portal Migration Baseline

---

## 1) Project Summary

This project delivers a reusable Azure provisioning baseline for migrating an existing web portal. The environment includes an App Service–hosted Web App, an Azure SQL Database for relational application data, and an Azure Storage Account for static assets. The web tier connects to the database through centralized App Service configuration using an encrypted connection string (Encrypt=True).

---

## 2) Solution Architecture (3-Tier)

* **Web Tier (App Service Web App):** Hosts the public landing page and admin entry point.
* **Data Tier (Azure SQL Database):** Stores relational operational data (e.g., registrations and summary records).
* **Static Content Tier (Azure Storage):** Serves non-executable assets (images, rules PDF, and static files) from blob storage.

This separation keeps web releases independent, preserves SQL for transactional workloads, and offloads static content to a dedicated service for predictable delivery.

---

## 3) What Was Implemented in Bicep

All resources are defined as Infrastructure as Code (IaC) using Azure Bicep. To reduce naming collisions, the deployment uses a deterministic uniqueness pattern based on `uniqueString(resourceGroup().id, namePrefix)`. The main template orchestrates the deployment, and selected components are separated into modular Bicep files.

### Repository / Bicep Layout

* `bicep/main.bicep`
  Orchestrates the deployment: parameters, SQL resources, connection string wiring, module calls, and outputs.
* `bicep/webapp.bicep`
  Provisions the App Service Plan + Web App with baseline security settings (HTTPS-only, TLS 1.2, FTPS disabled, Linux runtime Node 20 LTS).
* `bicep/storage.bicep`
  Provisions the Storage Account and creates the `static-assets` blob container.
* `bicep/main.parameters.json`
  Holds environment-specific values, including SQL admin credentials.

### Web Tier Baseline Configuration

* HTTPS-only enabled
* Minimum TLS version set to 1.2
* FTPS disabled
* Linux App Service Plan with Web App (Node 20 LTS runtime)

### Azure SQL Baseline Configuration

* Azure SQL Server + Azure SQL Database created
* **AllowAzureServices** firewall rule enabled for fast baseline connectivity
* Web App SQL connection string applied via App Service configuration (Encrypt=True)

### Storage Baseline Configuration

* StorageV2 Storage Account created
* Blob container: `static-assets` (for images, rules PDFs, and other static files)

---

## 4) Security Notes

* Web access is enforced over HTTPS with minimum TLS 1.2.
* Database connectivity uses encrypted transport (Encrypt=True).
* Sensitive configuration is managed through App Service connection strings rather than hardcoding in application code.
* Production hardening options: Key Vault for secrets, Private Endpoint/VNet integration, and replacing permissive firewall posture with least-privilege rules.

---

## 5) Deployment (Azure CLI)

```bash
az group create -n rg-lakemaple-bicep -l canadacentral
az deployment group create -g rg-lakemaple-bicep -f bicep/main.bicep -p bicep/main.parameters.json
```

---

## 6) CI/CD and Automation (GitHub Actions)

GitHub Actions is used to validate infrastructure changes as part of a lightweight, repository-native automation approach.

* **Bicep Validation:** A workflow runs on each push and executes `az bicep build` to confirm the template compiles and to catch issues early.
* **Azure Deployment Approach:** A standard automation flow is checkout → Azure login (OIDC or service principal) → Bicep build/validate → `az deployment group create`. This requires an Azure identity with appropriate RBAC permissions.

Example deployment command used by an automation pipeline:

```bash
az deployment group create -g rg-lakemaple-bicep -f bicep/main.bicep -p bicep/main.parameters.json
```

---

## 7) Evidence and Outputs

* **Web App URL:** [https://lakemaple-web-d7o3e2gevknog.azurewebsites.net](https://lakemaple-web-d7o3e2gevknog.azurewebsites.net)
* **SQL Server FQDN:** lakemaple-sql-d7o3e2gevknog.database.windows.net
* **SQL Database Name:** lakemaple-db
* **Storage Account Name:** lakemaplestd7o3e2gevknog
* **Validation:** `curl -I` returned `HTTP/1.1 200 OK`
* **Repository:** [https://github.com/enezihe/lakemaple-webapp](https://github.com/enezihe/lakemaple-webapp)
