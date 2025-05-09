param name string

param location string = resourceGroup().location

@description('Friendly name for the ML Studio Workspace. This is the name that will be displayed.')
param friendlyName string = name

@description('Description for the ML Studio Workspace. Shows up in the display')
param workspaceDescription string = 'Working deployment for ML Studio'

@description('Resource ID of App Insights instance')
param appInsightsId string

@description('Resource ID of Key Vault instance')
param keyVaultId string

@description('Resource ID of Storage Account instance')
param storageAccountId string 

@description('Resource ID of APIM Principal ID')
param apimPrincipalId string

var azureRoles = loadJsonContent('../../../azure-roles.json')
var azureAIDeveloperRole = resourceId('Microsoft.Authorization/roleDefinitions', azureRoles.AzureAIDeveloper)


resource mlStudio 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: workspaceDescription
    friendlyName: friendlyName

    // dependencies
    applicationInsights: appInsightsId
    keyVault: keyVaultId
    storageAccount: storageAccountId

    publicNetworkAccess: 'Enabled' // TODO: maybe change to Disabled when ready for production
    hbiWorkspace: false
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: mlStudio
  name: guid(subscription().id, resourceGroup().id, mlStudio.name, 'ml-studio-role-assignment')
  properties: {
    roleDefinitionId: azureAIDeveloperRole
    principalId: apimPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output mlStudioId string = mlStudio.id
output mlStudioResourceUrl string = 'https://ml.azure.com/?wsid=/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.MachineLearningServices/workspaces/${mlStudio.name}&tid=${tenant().tenantId}'
output location string = location
