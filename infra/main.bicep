targetScope = 'subscription'

@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param amlName string = 'DS-AML-Demo'

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The Azure resource group where new resources will be deployed')
param resourceGroupName string = ''

@description('Resource group name of the virtual network to deploy the resource into.')
param vnetRgName string

@description('Resource name of the virtual network to deploy the resource into.')
param vnetName string

@description('Name of the subnet to deploy into.')
param subnetName string

@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

var applicationInsightsName = '${abbrs.insightsComponents}${resourceToken}'
var appInsightSDeploymentName ='-${applicationInsightsName}-deployment'

var containerRegistryName = '${abbrs.containerRegistryRegistries}${resourceToken}'
var containerRegistryPleName = '${abbrs.containerRegistryRegistries}${resourceToken}-PE'
var keyvaultName = '${abbrs.keyVaultVaults}${resourceToken}'
var keyvaultPleName = '${abbrs.networkPrivateLinkServices}${resourceToken}-PE'
var logAnalyticsWorkspaceName = '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
var privateDnsZoneName = 'privatelink${environment().suffixes.keyvaultDns}'

var storageAccountName = '${abbrs.storageStorageAccounts}${resourceToken}'
var storagePleBlobName = 'ple-${storageAccountName}-blob'
var storagePleFileName = 'ple-${storageAccountName}-file'

var vnetResourceId = '/subscriptions/52a1b0a6-51af-4e8d-b2e9-adb2d7106869/resourceGroups/rg-devcenter/providers/Microsoft.Network/virtualNetworks/vNet-Devcenter'
//var vnetResourceId = resourceId(subscription().id,vnetRgName, 'Microsoft.Network/virtualNetworks', vnetName)

var subnetResourceId = '/subscriptions/52a1b0a6-51af-4e8d-b2e9-adb2d7106869/resourceGroups/rg-devcenter/providers/Microsoft.Network/virtualNetworks/vNet-Devcenter/subnets/subnet-openai'
//var subnetResourceId = resourceId(subscription().id,vnetRgName, 'Microsoft.Network/virtualNetworks/subnets', '${vnetName}/${subnetName}')
resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module applicationInsights 'core/monitoring/appInsights.bicep' = {
  name: appInsightSDeploymentName
  scope: rg
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    location: location
    tags: tags
  }
}

module keyVault 'core/security/keyvault.bicep' = {
  name: keyvaultName
  scope: rg
  params: {
    keyvaultName: keyvaultName
    keyvaultPleName: keyvaultPleName
    subnetId: subnetResourceId
    virtualNetworkId: vnetResourceId
    location: location
    privateDnsZoneName: privateDnsZoneName
    tags: tags
  }
}

module containerRegistry 'core/acr/containerregistry.bicep' = {
  name: containerRegistryName
  scope: rg
  params: {
    acrName: containerRegistryName
    location: location
    containerRegistryPleName: containerRegistryPleName
    subnetResourceId: subnetResourceId
    virtualNetworkId: vnetResourceId
    tags: tags
  }
}

module aiServices 'core/ai/cognitiveservices.bicep' = {
  name: amlName
  scope: rg
  params: {
    location: location
    tags: tags
    aiServiceName: amlName
    aiServicesPleName: amlName
    subnetId: subnetResourceId
    virtualNetworkId: vnetResourceId
  }
}

module storage 'core/storage/storge.bicep' = {
  name: storageAccountName
  scope: rg
  params: {
    storageName: storageAccountName
    storagePleBlobName: storagePleBlobName
    storagePleFileName: storagePleFileName
    subnetId: subnetResourceId
    virtualNetworkId: vnetResourceId
    location: location
    tags: tags
  }
}

module amlWorkspace 'core/aml/aml-workspace.bicep' = {
  name: amlName
  scope: rg
  params: {
    amlWorkspaceName: amlName
    location: location
    tags: tags
    applicationInsightsId: applicationInsightsName
    containerRegistryId: containerRegistryName
    keyVaultId: keyvaultName
    storageAccountId: storageAccountName
    aiServicesId: amlName
    aiServicesTarget: amlName
    vnetResourceId: vnetResourceId
    subnetResourceId: subnetResourceId
  }
}
