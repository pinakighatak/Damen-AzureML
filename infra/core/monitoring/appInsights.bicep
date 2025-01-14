//create paramaterss for names
param logAnalyticsWorkspaceName string
param applicationInsightsName string

param location string
param tags object

// Create logAnalyticsWorkspace Insights from AVM
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: logAnalyticsWorkspaceName
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    skuName: 'PerGB2018'
    dataRetention: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Disabled'
    tags: tags
  }
}

//create application insights from AVM
module applicationInsights 'br/public:avm/res/insights/component:0.4.2' = {
  name: applicationInsightsName
  params: {
    // Required parameters
    name: applicationInsightsName
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    // Non-required parameters
    location: location
    kind: 'web'
    applicationType: 'web'
    tags: tags
  }
}
output applicationInsightsResourceId string = applicationInsights.outputs.resourceId
