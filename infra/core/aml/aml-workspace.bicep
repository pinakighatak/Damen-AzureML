// Creates an Azure AI resource with proxied endpoints for the Azure AI services provider

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('AML name')
param amlWorkspaceName string

@description('Resource ID of the application insights resource for storing diagnostics logs')
param applicationInsightsId string

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

var privateEndpointName = '${amlWorkspaceName}-amlWorkspace-PE'


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
    managedNetworkSettings: {
      isolationMode: 'AllowInternetOutbound'
    }
    privateEndpoints: [
      {
        name: privateEndpointName
        subnetResourceId: subnetResourceId
        privateLinkServiceConnectionName: amlWorkspaceName
        applicationSecurityGroupResourceIds: [
          'amlworkspace'
        ]
        privateDnsZoneGroup: {
          name: 'default'
          privateDnsZoneGroupConfigs: [
            {
              name: 'privatelink-api-azureml-ms'
              privateDnsZoneResourceId: privateLinkApi.outputs.resourceId
            }
            {
              name: 'privatelink-notebooks-azure-net'
              privateDnsZoneResourceId: privateLinkNotebooks.outputs.resourceId
            }
          ]
        }
      }
    ]
    connections: [
      {
        name: '${amlWorkspaceName}-connection-AIServices'
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

module privateLinkApi 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: 'privatelink.api.azureml.ms'
  params: {
    // Required parameters
    name: 'privatelink.api.azureml.ms'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
        name: '${uniqueString(vnetResourceId)}-api'
        registrationEnabled: false
        virtualNetworkResourceId: vnetResourceId
      }
    ]
  }
}

module privateLinkNotebooks 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: 'privatelink.notebooks.azure.net'
  params: {
    // Required parameters
    name: 'privatelink.notebooks.azure.net'
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
        name: uniqueString(vnetResourceId)
        registrationEnabled: false
        virtualNetworkResourceId: vnetResourceId
      }
    ]
  }
}

output amlWorkspaceID string = amlWorkspace.outputs.resourceId
