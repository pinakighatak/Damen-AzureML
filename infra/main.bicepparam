using './main.bicep'
param amlName = 'ds-aml-demo'
param vnetRgName = 'rg-networks-dev'
param vnetName = 'vNet-damen-openai'
param subnetName = 'subnet-openai'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'MY_ENV')
param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP', '')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westeurope')
// param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
// param openAiName = readEnvironmentVariable('AZURE_OPENAI_NAME', '')
// param createRoleForUser = bool(readEnvironmentVariable('CREATE_ROLE_FOR_USER', 'true'))
