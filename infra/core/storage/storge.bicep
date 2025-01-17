// Creates a storage account, private endpoints and DNS zones
@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Name of the storage account')
param storageName string

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

module blobPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: blobPrivateDnsZoneName
  params: {
    // Required parameters
    name: blobPrivateDnsZoneName
    // Non-required parameters
    location: 'global'
    virtualNetworkLinks: [
      {
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
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetworkId
      }
    ]
  }
}
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
    enableHierarchicalNamespace: false
    enableNfsV3: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    privateEndpoints: [
      {
        subnetResourceId: subnetId
        service: 'blob'
        privateDnsZoneGroup: {
          name: blobPrivateDnsZoneName
          privateDnsZoneGroupConfigs: [
            {
              name: blobPrivateDnsZoneName
              privateDnsZoneResourceId: blobPrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
      {
        subnetResourceId: subnetId
        service: 'file'
        privateDnsZoneGroup: {
          name: filePrivateDnsZoneName
          privateDnsZoneGroupConfigs: [
            {
              name: filePrivateDnsZoneName
              privateDnsZoneResourceId: filePrivateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]

    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}

// //create private endpoints for the blob storage
// module storagePrivateEndpointBlob 'br/public:avm/res/network/private-endpoint:0.9.1' = {
//   name: storagePleBlobName
//   params: {
//     name: storagePleBlobName
//     location: location
//     subnetResourceId: subnetId
//     tags: tags
//     privateLinkServiceConnections: [
//       {
//         name: storagePleBlobName
//         properties: {
//           privateLinkServiceId: storage.outputs.resourceId
//           groupIds: [
//             'blob'
//           ]
//         }
//       }
//     ]
//     privateDnsZoneGroup: {
//       name: 'blob-privatednszonegroup'
//       privateDnsZoneGroupConfigs: [
//         {
//           name: blobPrivateDnsZoneName
//           privateDnsZoneResourceId: blobPrivateDnsZone.outputs.resourceId
//         }
//       ]
//     }
//   }
// }

// //create private endpoints for the file storage
// module storagePrivateEndpointFile 'br/public:avm/res/network/private-endpoint:0.9.1' = {
//   name: storagePleFileName
//   params: {
//     name: storagePleFileName
//     location: location
//     subnetResourceId: subnetId
//     tags: tags
//     privateLinkServiceConnections: [
//       {
//         name: storagePleFileName
//         properties: {
//           privateLinkServiceId: storage.outputs.resourceId
//           groupIds: [
//             'file'
//           ]
//         }
//       }
//     ]
//     privateDnsZoneGroup: {
//       name: 'file-privatednszonegroup'
//       privateDnsZoneGroupConfigs: [
//         {
//           name: filePrivateDnsZoneName
//           privateDnsZoneResourceId: filePrivateDnsZone.outputs.resourceId
//         }
//       ]
//     }
//   }
// }

output storageResourceId string = storage.outputs.resourceId
