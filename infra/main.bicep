targetScope = 'subscription'

// Execute this main file to deploy Azure AI studio resources in the basic security configuration

// Parameters
@description('Resource name of the virtual network to deploy the resource into.')
param vnetName string

@description('Resource group name of the virtual network to deploy the resource into.')
param vnetRgName string

@description('Name of the subnet to deploy into.')
param subnetName string

@description('The location into which the resources should be deployed.')
param location string

@description('The Azure resource group where new resources will be deployed')
param resourceGroupName string = ''

@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

//variables
//The VNET and subnet resources are used to create the private endpoints. This should already exist in the subscription
var vnetResourceId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetRgName}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
var subnetResourceId = '${vnetResourceId}/subnets/${subnetName}'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

var applicationInsightsName = '${abbrs.insightsComponents}${resourceToken}'
var containerRegistryName = '${abbrs.containerRegistryRegistries}${resourceToken}'

var keyvaultName = '${abbrs.keyVaultVaults}${resourceToken}'

var logAnalyticsWorkspaceName = '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
var storageAccountName = '${abbrs.storageStorageAccounts}${resourceToken}'
var customNetworkInterfaceName = '${abbrs.networkNetworkInterfaces}-${resourceToken}'

var aiServicesName = '${abbrs.cognitiveServicesAccounts}${resourceToken}'
var mlWorkspaceName = '${abbrs.machineLearningServicesWorkspaces}${resourceToken}'
var amlWorkspacePEName = '${abbrs.networkPrivateEndpoint}${mlWorkspaceName}'
var amlWorkspacePrivateZoneGroupName = '${abbrs.networkPrivateDnsZones}${mlWorkspaceName}'

resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

//Create Application Insights and Log Analytics Workspace
module applicationInsights 'core/monitoring/appInsights.bicep' = {
  name: '${applicationInsightsName}-deployment'
  scope: rg
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    location: location
    tags: tags
  }
}

//Create Azure keyvault with its private endpoint, links and DNS zone
module keyVault 'core/security/keyvault.bicep' = {
  name: '${keyvaultName}-deployment'
  scope: rg
  params: {
    keyvaultName: keyvaultName
    virtualNetworkId: vnetResourceId
    subnetId: subnetResourceId
    location: location
    tags: tags
  }
}

module containerRegistry 'core/acr/containerregistry.bicep' = {
  name: '${containerRegistryName}-deployment'
  scope: rg
  params: {
    acrName: containerRegistryName
    location: location
    subnetResourceId: subnetResourceId
    virtualNetworkId: vnetResourceId
    tags: tags
  }
}

module storage 'core/storage/storge.bicep' = {
  name: '${storageAccountName}-deployment'
  scope: rg
  params: {
    storageName: storageAccountName
    subnetId: subnetResourceId
    virtualNetworkId: vnetResourceId
    location: location
    tags: tags
  }
}
module openAIServices 'core/ai/cognitiveservices.bicep' = {
  name: '${aiServicesName}-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    aiServiceName: aiServicesName
    // aiServicesPleName: aiServicesPleName
    subnetId: subnetResourceId
    kind: 'CognitiveServices'
    virtualNetworkId: vnetResourceId
  }
}

module machineLearningWorkspace 'core/aml/aml-workspace.bicep' = {
  name: '${mlWorkspaceName}-deployment'
  scope: rg
  params: {
    amlWorkspaceName: mlWorkspaceName
    privateZoneGroupName: amlWorkspacePrivateZoneGroupName
    customNetworkInterfaceName: customNetworkInterfaceName
    location: location
    tags: tags
    containerRegistryId: containerRegistry.outputs.containerRegistryResourceId
    keyVaultId: keyVault.outputs.keyVaultResourceId
    storageAccountId: storage.outputs.storageResourceId
    aiServicesId: openAIServices.outputs.aiServicesResourceId
    aiServicesTarget: openAIServices.outputs.aiservicesTarget
    applicationInsightsId: applicationInsights.outputs.applicationInsightsResourceId
    vnetResourceId: vnetResourceId
    privateEndpointName: amlWorkspacePEName
    subnetResourceId: subnetResourceId
  }
}
