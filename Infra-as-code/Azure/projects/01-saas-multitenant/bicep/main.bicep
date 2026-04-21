targetScope = 'subscription'

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Primary Azure region')
param location string = 'eastus'

@description('Secondary region for geo-redundancy')
param secondaryLocation string = 'westus2'

@description('Project name prefix')
param projectName string = 'saas'

@description('Image tag for container apps')
param imageTag string = 'latest'

var tags = {
  environment: environment
  project: projectName
  managedBy: 'bicep'
  compliance: 'SOC2'
}

// ── Resource Groups ──────────────────────────────────────────────────────────
resource rgPrimary 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${projectName}-${environment}-rg'
  location: location
  tags: tags
}

resource rgSecondary 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${projectName}-${environment}-secondary-rg'
  location: secondaryLocation
  tags: tags
}

// ── Networking ───────────────────────────────────────────────────────────────
module network 'modules/network.bicep' = {
  name: 'network'
  scope: rgPrimary
  params: {
    vnetName: '${projectName}-${environment}-vnet'
    location: location
    tags: tags
  }
}

// ── Container Apps Environment ────────────────────────────────────────────────
module containerApps 'modules/container-apps.bicep' = {
  name: 'container-apps'
  scope: rgPrimary
  params: {
    environmentName: '${projectName}-${environment}-cae'
    location: location
    subnetId: network.outputs.containerAppsSubnetId
    tags: tags
    imageTag: imageTag
    keyVaultName: keyVault.outputs.keyVaultName
    acrName: acr.outputs.acrName
  }
}

// ── Azure SQL Hyperscale ──────────────────────────────────────────────────────
module sql 'modules/sql.bicep' = {
  name: 'sql'
  scope: rgPrimary
  params: {
    serverName: '${projectName}-${environment}-sql'
    location: location
    secondaryLocation: secondaryLocation
    tags: tags
  }
}

// ── Key Vault ─────────────────────────────────────────────────────────────────
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: rgPrimary
  params: {
    keyVaultName: '${projectName}-${environment}-kv'
    location: location
    tags: tags
  }
}

// ── Container Registry ────────────────────────────────────────────────────────
module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: rgPrimary
  params: {
    acrName: '${projectName}${environment}acr'
    location: location
    tags: tags
  }
}

// ── Azure Front Door ──────────────────────────────────────────────────────────
module frontDoor 'modules/frontdoor.bicep' = {
  name: 'frontdoor'
  scope: rgPrimary
  params: {
    profileName: '${projectName}-${environment}-afd'
    apiServiceFqdn: containerApps.outputs.apiServiceFqdn
    tags: tags
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output frontDoorEndpoint string = frontDoor.outputs.endpointHostname
output apiServiceFqdn string = containerApps.outputs.apiServiceFqdn
output sqlServerFqdn string = sql.outputs.serverFqdn
