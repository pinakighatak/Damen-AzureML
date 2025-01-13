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
    privateEndpoints: [
      {
        name: containerRegistryPleName
        subnetResourceId: subnetResourceId
        privateLinkServiceConnectionName: containerRegistryPleName
        applicationSecurityGroupResourceIds: [
          'registry'
        ]
        privateDnsZoneGroup: {
          name: 'registry-PrivateDnsZoneGroup'
          privateDnsZoneGroupConfigs: [
            {
              name: privateDnsZoneName
              privateDnsZoneResourceId: acrPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

module acrPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: privateDnsZoneName
  params: {
    // Required parameters
    name: privateDnsZoneName
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

output containerRegistryResourceId string = containerRegistry.outputs.resourceId
