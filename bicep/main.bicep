param location string = resourceGroup().location
param namePrefix string = 'lakemaple'
param appServiceSkuName string = 'B1'

param sqlAdminLogin string
@secure()
param sqlAdminPassword string

var unique = toLower(uniqueString(resourceGroup().id, namePrefix))

// Deterministic names (known at start of deployment)
var webAppName = '${namePrefix}-web-${unique}'
var sqlServerName = '${namePrefix}-sql-${unique}'
var sqlDbName = '${namePrefix}-db'

// --------------------
// Compute module: App Service Plan + Web App (webapp.bicep)
// --------------------
module webappMod './webapp.bicep' = {
  name: 'webappDeploy'
  params: {
    location: location
    namePrefix: namePrefix
    appServiceSkuName: appServiceSkuName
    unique: unique
  }
}

// Reference the web app created by the module (for scope-safe resources)
resource webExisting 'Microsoft.Web/sites@2022-09-01' existing = {
  name: webAppName
}

// --------------------
// Monitoring: Log Analytics Workspace
// --------------------
var lawName = '${namePrefix}-law-${unique}'

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// --------------------
// Database Tier: Azure SQL Server + DB
// --------------------
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${sqlServer.name}/${sqlDbName}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {}
}

// Fast baseline connectivity: allow Azure services
resource allowAzureFirewall 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: '${sqlServer.name}/AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// --------------------
// Wire SQL connection string into the Web App
// --------------------
resource webConn 'Microsoft.Web/sites/config@2022-09-01' = {
  name: '${webAppName}/connectionstrings'
  properties: {
    SqlDb: {
      value: 'Server=tcp:${sqlServer.name}.database.windows.net,1433;Initial Catalog=${sqlDbName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
      type: 'SQLAzure'
    }
  }
  dependsOn: [
    sqlDb
    webappMod
  ]
}

// --------------------
// Diagnostic Settings: Web App -> Log Analytics
// --------------------
resource webDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diag'
  scope: webExisting
  properties: {
    workspaceId: law.id
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true }
      { category: 'AppServiceConsoleLogs', enabled: true }
      { category: 'AppServiceAppLogs', enabled: true }
      { category: 'AppServicePlatformLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
  dependsOn: [
    law
    webappMod
  ]
}

// --------------------
// Storage module (storage.bicep)
// --------------------
module storageMod './storage.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    namePrefix: namePrefix
    unique: unique
  }
}

// --------------------
// Outputs
// --------------------
output webAppUrl string = webappMod.outputs.webAppUrl
output appInsightsName string = webappMod.outputs.appInsightsName
output sqlServerFqdn string = '${sqlServer.name}.database.windows.net'
output sqlDbName string = sqlDbName
output storageAccountName string = storageMod.outputs.storageAccountName
output logAnalyticsWorkspaceName string = law.name
