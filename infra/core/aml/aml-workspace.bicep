// Creates an Azure AI resource with proxied endpoints for the Azure AI services provider

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('AML name')
param amlWorkspaceName string

param privateZoneGroupName string

@description('Resource ID of the application insights resource for storing diagnostics logs')
param applicationInsightsId string

@description('Name of the custom network interface NIC for the private endpoint')
param customNetworkInterfaceName string

@description('Resource ID of the container registry resource for storing docker images')
param containerRegistryId string

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

@description('Resource ID of the AI Services resource')
param aiServicesId string

@description('Resource ID of the AI Services endpoint')
param aiServicesTarget string

@description('Resource Id of the virtual network to deploy the resource into.')
param vnetResourceId string

@description('Subnet Id to deploy into.')
param subnetResourceId string

@description('Private endpoint name')
param privateEndpointName string

var azuremlPrivateDnsZoneName = 'privatelink.api.azureml.ms'
var notebooksPrivateDnsZoneName = 'privatelink.notebooks.azure.com'

module azuremlPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: azuremlPrivateDnsZoneName
  params: {
    // Required parameters
    name: azuremlPrivateDnsZoneName
    // Non-required parameters
    location: 'global'
    tags: tags
    // a:[]
    // aaaa: []
    // cname: []
    // mx: []
    // ptr: []
    // soa: []
    // srv: []
    // txt: []
    virtualNetworkLinks: [
      {
        name: '${uniqueString(vnetResourceId)}-api'
        registrationEnabled: false
        virtualNetworkResourceId: vnetResourceId
      }
    ]
  }
}

module notebooksPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: notebooksPrivateDnsZoneName
  params: {
    // Required parameters
    name: notebooksPrivateDnsZoneName
    // Non-required parameters
    location: 'global'
    tags: tags
    // a:[]
    // aaaa: []
    // cname: []
    // mx: []
    // ptr: []
    // soa: []
    // srv: []
    // txt: []
    virtualNetworkLinks: [
      {
        name: '${uniqueString(vnetResourceId)}-notebooks'
        registrationEnabled: false
        virtualNetworkResourceId: vnetResourceId
      }
    ]
  }
}
// Create the Azure Machine Learning workspace from AVM
module amlWorkspace 'br/public:avm/res/machine-learning-services/workspace:0.9.1' = {
  name: amlWorkspaceName
  params: {
    name: amlWorkspaceName
    location: location
    tags: tags
    sku: 'Standard'
    kind: 'Default'
    associatedApplicationInsightsResourceId: applicationInsightsId
    associatedContainerRegistryResourceId: containerRegistryId
    associatedKeyVaultResourceId: keyVaultId
    associatedStorageAccountResourceId: storageAccountId
    publicNetworkAccess: 'Disabled'
    description: 'Azure Machine Learning workspace'
    managedNetworkSettings: {
      isolationMode: 'AllowInternetOutbound'
    }
    sharedPrivateLinkResources: []
    managedIdentities: {
      systemAssigned: true
    }
    privateEndpoints: [
      {
        name: privateEndpointName
        customDnsConfigs: []
        subnetResourceId: subnetResourceId
        customNetworkInterfaceName: customNetworkInterfaceName
        privateDnsZoneGroup: {
          name: privateZoneGroupName
          privateDnsZoneGroupConfigs: [
            {
              name: replace(azuremlPrivateDnsZoneName, '.', '-')
              privateDnsZoneResourceId: azuremlPrivateDnsZone.outputs.resourceId
            }
            {
              name: replace(notebooksPrivateDnsZoneName, '.', '-')
              privateDnsZoneResourceId: notebooksPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
    connections: [
      {
        name: amlWorkspaceName
        connectionProperties: {
          authType: 'ApiKey'
          credentials: {
            key: '${listKeys(aiServicesId, '2021-10-01').key1}'
          }
        }
        category: 'AIServices'
        target: aiServicesTarget
        isSharedToAll: true
        metadata: {
          ApiType: 'Azure'
          ResourceId: aiServicesId
        }
      }
    ]
  }
}
output amlWorkspaceID string = amlWorkspace.outputs.resourceId
