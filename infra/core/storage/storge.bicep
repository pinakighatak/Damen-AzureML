// Creates a storage account, private endpoints and DNS zones
@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Name of the storage account')
param storageName string

@description('Name of the storage blob private link endpoint')
param storagePleBlobName string

@description('Name of the storage file private link endpoint')
param storagePleFileName string

@description('Resource ID of the subnet')
param subnetId string

@description('Resource ID of the virtual network')
param virtualNetworkId string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
@description('Storage SKU')
param storageSkuName string = 'Standard_LRS'

var storageNameCleaned = replace(storageName, '-', '')

var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

var filePrivateDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'

//create a storage from AVM
module storage 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: storageNameCleaned
  scope: resourceGroup()
  params: {
    name: storageName
    location: location
    tags: tags
    skuName: storageSkuName
    kind: 'StorageV2'
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    privateEndpoints: [
      {
        service: 'Blob'
        name: storagePleBlobName
        subnetResourceId: subnetId
        privateLinkServiceConnectionName: storagePleBlobName
        applicationSecurityGroupResourceIds: [
          'account'
        ]
        privateDnsZoneGroup: {
          name: 'default'
          privateDnsZoneGroupConfigs: [
            {
              name: blobPrivateDnsZoneName
              privateDnsZoneResourceId: blobPrivateDnsZone.outputs.resourceId
            }
            {
              name: filePrivateDnsZoneName
              privateDnsZoneResourceId: filePrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
      {
        name: storagePleFileName
        service: 'File'
        subnetResourceId: subnetId
        privateLinkServiceConnectionName: storagePleFileName
        applicationSecurityGroupResourceIds: [
          'account'
        ]
        privateDnsZoneGroup: {
          name: 'default'
          privateDnsZoneGroupConfigs: [
            {
              name: filePrivateDnsZoneName
              privateDnsZoneResourceId: filePrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

module blobPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: blobPrivateDnsZoneName
  params: {
    // Required parameters
    name: blobPrivateDnsZoneName
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
module filePrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: filePrivateDnsZoneName
  params: {
    // Required parameters
    name: filePrivateDnsZoneName
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
