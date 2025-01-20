param location string

@description('Container registry name')
param acrName string

param subnetResourceId string

@description('Resource ID of the virtual network')
param virtualNetworkId string
param tags object
var privateDnsZoneName = 'privatelink${environment().suffixes.acrLoginServer}'

module acrPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: privateDnsZoneName
  params: {
    name: privateDnsZoneName
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
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}

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
    privateEndpoints: [
      {
        subnetResourceId: subnetResourceId
        service: 'registry'
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: privateDnsZoneName
              privateDnsZoneResourceId: acrPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
    tags: tags
  }
}


output containerRegistryResourceId string = containerRegistry.outputs.resourceId
