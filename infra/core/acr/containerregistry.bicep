param location string

@description('Container registry name')
param acrName string

@description('Container registry private link endpoint name')
param containerRegistryPleName string

param subnetResourceId string

@description('Resource ID of the virtual network')
param virtualNetworkId string
param tags object
var privateDnsZoneName = 'privatelink${environment().suffixes.acrLoginServer}'

module containerRegistry 'br/public:avm/res/container-registry/registry:0.7.0' = {
  name: acrName
  params: {
    name: acrName
    location: location
    acrSku: 'Premium'
    acrAdminUserEnabled: false
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSetDefaultAction: 'Deny'
    quarantinePolicyStatus: 'disabled'
    retentionPolicyStatus: 'enabled'
    retentionPolicyDays: 7
    trustPolicyStatus: 'enabled'
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: 'Disabled'
    tags: tags
  }
}

//create private endpoints for the keyvault
module containerRegistryPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.9.1' = {
  name: containerRegistryPleName
  params: {
    name: containerRegistryPleName
    location: location
    subnetResourceId: subnetResourceId
    tags: tags
    privateLinkServiceConnections: [
      {
        name: uniqueString(containerRegistryPleName)
        properties: {
          privateLinkServiceId: containerRegistry.outputs.resourceId
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    privateDnsZoneGroup: {
      name: 'registry-privatednszonegroup'
      privateDnsZoneGroupConfigs: [
        {
          name: privateDnsZoneName
          privateDnsZoneResourceId: acrPrivateDnsZone.outputs.resourceId
        }
      ]
    }
  }
}
module acrPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: privateDnsZoneName
  params: {
    name: privateDnsZoneName
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: uniqueString(containerRegistry.outputs.resourceId)
        location: 'global'
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}

output containerRegistryResourceId string = containerRegistry.outputs.resourceId
