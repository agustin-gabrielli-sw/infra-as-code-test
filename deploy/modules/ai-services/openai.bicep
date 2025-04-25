@description('The environment configuration map')
param environmentConfigurationMap object

@description('The environment type')
param environmentType string

@description('The name of the OpenAI service')
param openAiServiceName string

@description('The location for the OpenAI service')
param location string = resourceGroup().location

@description('The name of the GPT-4 deployment')
param deploymentName string = 'gpt-4o-mini-deployment'

@description('The Log Analytics Workspace ID for diagnostics')
param lawId string = ''

resource openAiService 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiServiceName
  location: location
  sku: environmentConfigurationMap[environmentType].openAI.sku
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAiServiceName
    publicNetworkAccess: 'Enabled'
  }
}

// Create a diagnostic setting to send OpenAI service logs to Log Analytics, if a Log Analytics Workspace ID is provided.
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(lawId != '') {
  name: '${openAiService.name}-diagnostics'
  scope: openAiService
  properties: {
    workspaceId: lawId
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: deploymentName
  parent: openAiService
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
  }
  sku: {
    name: environmentConfigurationMap[environmentType].openAI.deployment.sku.name
    capacity: environmentConfigurationMap[environmentType].openAI.deployment.sku.capacity
  }
}

output openAiServiceName string = openAiService.name
output deploymentName string = deployment.name
output endpoint string = openAiService.properties.endpoint
