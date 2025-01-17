// Creates a KeyVault with Private Link Endpoint
@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location

@description('Tags to apply to the Key Vault Instance')
param tags object = {}

@description('The name of the Key Vault')
param keyvaultName string

@description('The Subnet ID where the Key Vault Private Link is to be created')
param subnetId string

@description('The VNet ID where the Key Vault Private Link is to be created')
param virtualNetworkId string

var privateDnsZoneName = 'privatelink${environment().suffixes.keyvaultDns}'

//create private DNS zone and link from AVM
module keyVaultPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
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
        location: 'global'
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}

//create keyvault from AVM
module keyVault 'br/public:avm/res/key-vault/vault:0.11.1' = {
  name: keyvaultName
  params: {
    name: keyvaultName
    location: location
    sku: 'standard'
    tags: tags
    createMode: 'default'
    enableVaultForDeployment: false
    enableVaultForDiskEncryption: false
    enableVaultForTemplateDeployment: false
    enableSoftDelete: true
    enablePurgeProtection: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    privateEndpoints: [
      {
        subnetResourceId: subnetId
        service: 'vault'
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: privateDnsZoneName
              privateDnsZoneResourceId: keyVaultPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

// //create private endpoints for the keyvault
// module keyVaultPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.9.1' = {
//   name: privateEndPointName
//   params: {
//     name: privateEndPointName
//     location: location
//     subnetResourceId: subnetId
//     tags: tags
//     privateLinkServiceConnections: [
//       {
//         name: uniqueString(keyvaultPleName)
//         properties: {
//           privateLinkServiceId: keyVault.outputs.resourceId
//           groupIds: [
//             'vault'
//           ]
//         }
//       }
//     ]
//     privateDnsZoneGroup: {
//       name: 'vault-privatednszonegroup'
//       privateDnsZoneGroupConfigs: [
//         {
//           name: privateDnsZoneName
//           privateDnsZoneResourceId: keyVaultPrivateDnsZone.outputs.resourceId
//         }
//       ]
//     }
//   }
// }

output keyVaultResourceId string = keyVault.outputs.resourceId
