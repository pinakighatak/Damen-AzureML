metadata description = 'Creates an Azure Cognitive Services instance.'

// Creates AI services resources, private endpoints, and DNS zones
@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Name of the AI service')
param aiServiceName string

@description('Resource ID of the subnet')
param subnetId string

@description('Resource ID of the virtual network')
param virtualNetworkId string

var cognitiveServicesPrivateDnsZoneName = 'privatelink.cognitiveservices.azure.com'
var openAiPrivateDnsZoneName = 'privatelink.openai.azure.com'


//create an array of allowed values for the kind parameter
@allowed([
  'AIServices'
  'AnomalyDetector'
  'CognitiveServices'
  'ComputerVision'
  'ContentModerator'
  'ContentSafety'
  'ConversationalLanguageUnderstanding'
  'CustomVision.Prediction'
  'CustomVision.Training'
  'Face'
  'FormRecognizer'
  'HealthInsights'
  'ImmersiveReader'
  'Internal.AllInOne'
  'LanguageAuthoring'
  'LUIS'
  'LUIS.Authoring'
  'MetricsAdvisor'
  'OpenAI'
  'Personalizer'
  'QnAMaker.v2'
  'SpeechServices'
  'TextAnalytics'
  'TextTranslation'
])

param kind string = 'AIServices'

module cognitiveServicesPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: cognitiveServicesPrivateDnsZoneName
  params: {
    // Required parameters
    name: cognitiveServicesPrivateDnsZoneName
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
        location: 'global'
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

@description('Model deployments for OpenAI')
//create cognitive services account from AVM
module aiServices 'br/public:avm/res/cognitive-services/account:0.9.1' = {
  name: aiServiceName
  scope: resourceGroup()
  params: {
    name: aiServiceName
    location: location
    tags: tags
    customSubDomainName: aiServiceName
    kind: kind
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true
    // deployments: [
    //   {
    //     model: {
    //       format: 'OpenAI'
    //       name: 'gpt-35-turbo'
    //       version: '0301'
    //     }
    //     name: 'gpt-35-turbo'
    //     sku: {
    //       capacity: 10
    //       name: 'Standard'
    //     }
    //   }
    // ]
    privateEndpoints: [
      {
        subnetResourceId: subnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: openAiPrivateDnsZone.outputs.resourceId
              name: replace(openAiPrivateDnsZoneName, '.', '-')
            }
            {
              privateDnsZoneResourceId: cognitiveServicesPrivateDnsZone.outputs.resourceId
              name: replace(cognitiveServicesPrivateDnsZoneName, '.', '-')
            }
          ]
        }
      }
    ]
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
  }
}
output aiServicesResourceId string = aiServices.outputs.resourceId
output aiservicesTarget string = aiServices.outputs.endpoint
