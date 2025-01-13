using './main.bicep'
param amlName = 'DS-AML-Demo'
param vnetRgName = 'rg-Devcenter'
param vnetName = 'vNet-Devcenter'
param subnetName = 'subnet-openai'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'MY_ENV')
param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP', '')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westeurope')
// param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
// param openAiName = readEnvironmentVariable('AZURE_OPENAI_NAME', '')
// param createRoleForUser = bool(readEnvironmentVariable('CREATE_ROLE_FOR_USER', 'true'))
