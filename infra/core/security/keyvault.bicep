// Creates a KeyVault with Private Link Endpoint
@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location

@description('Tags to apply to the Key Vault Instance')
param tags object = {}

@description('The name of the Key Vault')
param keyvaultName string

@description('The name of the Key Vault private link endpoint')
param keyvaultPleName string

@description('The Subnet ID where the Key Vault Private Link is to be created')
param subnetId string

@description('The VNet ID where the Key Vault Private Link is to be created')
param virtualNetworkId string

param privateDnsZoneName string

//create keyvault from AVM
module keyVault 'br/public:avm/res/key-vault/vault:0.11.1' = {
  name: keyvaultName
  params: {
    name: keyvaultName
    location: location
    sku: 'standard'
    tags: tags
    enableVaultForDeployment: false
    enableVaultForDiskEncryption: false
    enableVaultForTemplateDeployment: false
    enableSoftDelete: true
    //enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    privateEndpoints: [
      {
        name: keyvaultPleName
        location: location
        tags: tags
        subnetResourceId: subnetId
        applicationSecurityGroupResourceIds: [
          'vault'
        ]
        privateLinkServiceConnectionName: keyvaultPleName
        service: 'vault'
        privateDnsZoneGroup: {
          name: 'default'
          privateDnsZoneGroupConfigs: [
            {
              name: 'default'
              privateDnsZoneResourceId: keyVaultPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

//create private DNS zone from AVM
module keyVaultPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: 'privateDnsZoneDeployment'
  params: {
    name: privateDnsZoneName
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: uniqueString(keyvaultName)
        location: 'global'
        registrationEnabled: true
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}





output keyVaultResourceId string = keyVault.outputs.resourceId
