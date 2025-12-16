## Lake Maple Web Portal Migration Baseline


Lake Maple Web Portal Migration Baseline is an Infrastructure-as-Code package that provisions a consistent Azure environment for a web portal footprint. The goal is to stand up the platform layer first—web hosting, relational data storage, static asset storage, and operational visibility—so application releases can be delivered on top with minimal friction.

---

### Solution Approach

The design follows a simple separation of responsibilities:

* **Web tier** provides the runtime boundary for the portal. It hosts the public landing surface and admin entry point and becomes the deployment target for future app releases.
* **Data tier** keeps operational records in a relational store so the portal can model structured entities such as registrations and summary data.
* **Static content tier** serves non-executable content from storage, allowing predictable delivery without coupling content management to the web runtime.
* **Operations layer** centralizes logs and metrics for troubleshooting and service health tracking without requiring access to individual resources during an incident.

This structure supports incremental delivery: infrastructure first, then application code, then tighter security and network controls as the environment matures.

---

### Infrastructure Definition

All resources are defined with Azure Bicep. Resource names are generated deterministically using a stable unique suffix to avoid collisions across deployments.

**Bicep layout**

* `bicep/main.bicep`
  Orchestrates the deployment: parameters, SQL resources, configuration wiring, monitoring resources, and module calls.
* `bicep/webapp.bicep`
  App Service Plan + Web App baseline configuration.
* `bicep/storage.bicep`
  Storage account + `static-assets` blob container.
* `bicep/main.parameters.json`
  Environment-specific inputs (including SQL admin credentials).

---

### What Gets Provisioned

#### Web Tier (App Service)

* Linux App Service Plan + Web App
* HTTPS-only enforced
* Minimum TLS 1.2
* FTPS disabled
* Runtime set for Node.js (Node 20 LTS)

#### Data Tier (Azure SQL)

* Azure SQL Server + Azure SQL Database
* Baseline firewall posture allows Azure-hosted connectivity for validation and integration
* Web App database access is configured through App Service **connection strings**, not in application code
* Connection string enforces encrypted transport (`Encrypt=True`)

#### Static Assets (Azure Storage)

* Storage account (StorageV2)
* Blob container: `static-assets`
* Intended for images, rules PDFs, and other portal content that does not require execution

#### Monitoring and Logging

* Log Analytics Workspace for centralized telemetry
* Diagnostic Settings configured to forward:

  * Web App logs/metrics to Log Analytics
  * SQL diagnostics/metrics to Log Analytics (using supported categories)

---

### Deployment

Run from the repository root.

```bash
az group create -n rg-lakemaple-bicep -l canadacentral

az deployment group create \
  -g rg-lakemaple-bicep \
  -f bicep/main.bicep \
  -p bicep/main.parameters.json
```

**Typical outputs**

* Web App URL
* SQL Server FQDN + database name
* Storage account name
* Log Analytics workspace name

---

### CI/CD Automation (GitHub Actions)

The repository includes GitHub Actions workflows under `.github/workflows/` to keep infrastructure changes reviewable and repeatable.

Current automation focuses on infrastructure quality gates:

* **Bicep validation** runs on push and compiles the templates (e.g., `az bicep build`) to catch template issues early.

A deployment workflow typically follows this operating model:

1. Checkout repository
2. Authenticate to Azure (OIDC or service principal)
3. Build/validate Bicep
4. Run the same `az deployment group create` command used locally

This keeps the deployment path consistent across local development and automated pipelines.

---

### Operational Notes

* Centralized diagnostics in Log Analytics supports faster root-cause analysis by consolidating App Service and SQL signals.
* Capacity management is handled at the App Service Plan layer (SKU/capacity), with room to add autoscale rules as traffic patterns become known.
* Secret management can be strengthened by moving credentials to Key Vault and replacing permissive firewall access with private connectivity patterns when needed.

---

### Verification

Example HTTP check against the Web App endpoint:

```bash
curl -I https://<WEB_APP_NAME>.azurewebsites.net
```

A healthy response returns `HTTP/1.1 200 OK`.
