metadata description = 'Creates an Azure Cognitive Services instance.'

// Creates AI services resources, private endpoints, and DNS zones
@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Name of the AI service')
param aiServiceName string

@description('Name of the AI service private link endpoint for cognitive services')
param aiServicesPleName string

@description('Resource ID of the subnet')
param subnetId string

@description('Resource ID of the virtual network')
param virtualNetworkId string

var aiServiceNameCleaned = replace(aiServiceName, '-', '')

var cognitiveServicesPrivateDnsZoneName = 'privatelink.cognitiveservices.azure.com'
var openAiPrivateDnsZoneName = 'privatelink.openai.azure.com'

param kind string = 'AIServices'

//create cognitive services account from AVM
module aiServices 'br/public:avm/res/cognitive-services/account:0.9.1' = {
  name: aiServiceNameCleaned
  scope: resourceGroup()
  params: {
    name: aiServiceName
    location: location
    tags: tags
    customSubDomainName: aiServiceNameCleaned
    kind: kind
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true

    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnetId
          ignoreMissingVnetServiceEndpoint: true
        }
      ]
    }

    managedIdentities: {
      systemAssigned: true
    }
    sku: 'S0'
    deployments: []
  }
}

//create private endpoints for the keyvault
module aiServicesPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.9.1' = {
  name: aiServicesPleName
  params: {
    name: aiServicesPleName
    location: location
    subnetResourceId: subnetId
    tags: tags
    privateLinkServiceConnections: [
      {
        name: aiServicesPleName
        properties: {
          privateLinkServiceId: aiServices.outputs.resourceId
          groupIds: [
            'account'
          ]
        }
      }
    ]
    privateDnsZoneGroup: {
      name: 'default'
      privateDnsZoneGroupConfigs: [
        {
          name: replace(openAiPrivateDnsZoneName, '.', '-')
          privateDnsZoneResourceId: openAiPrivateDnsZone.outputs.resourceId
        }
        {
          name: replace(cognitiveServicesPrivateDnsZoneName, '.', '-')
          privateDnsZoneResourceId: cognitiveServicesPrivateDnsZone.outputs.resourceId
        }
      ]
    }
  }
}

module cognitiveServicesPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: cognitiveServicesPrivateDnsZoneName
  params: {
    // Required parameters
    name: cognitiveServicesPrivateDnsZoneName
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
        name: uniqueString(virtualNetworkId)
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}

module openAiPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: openAiPrivateDnsZoneName
  params: {
    // Required parameters
    name: openAiPrivateDnsZoneName
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
        name: uniqueString(virtualNetworkId)
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}

output aiServicesResourceId string = aiServices.outputs.resourceId
output aiservicesTarget string = aiServices.outputs.endpoint

