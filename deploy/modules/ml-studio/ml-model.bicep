param mlWorkspaceName string
param location string // Location that is supported by the model catalog serverless endpoint
param modelId string // Do not include the version when copying the Model ID
param endpointName string

resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-10-01' existing = {
  name: mlWorkspaceName
}

// Create a serverless endpoint
resource serverlessEndpoint 'Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2025-01-01-preview' = {
  name: endpointName
  parent: mlWorkspace
  sku: {
    name: 'Consumption'
  }
  location: location
  properties: {
    authMode: 'AAD'
    contentSafety: {
      contentSafetyLevel: 'Deferred'
      contentSafetyStatus: 'Enabled'
    }
    modelSettings: {
      modelId: modelId
    }
  }
}

output endpointId string = serverlessEndpoint.name
output modelUrl string = serverlessEndpoint.properties.inferenceEndpoint.uri
