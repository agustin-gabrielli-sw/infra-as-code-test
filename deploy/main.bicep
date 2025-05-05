@allowed([
  'Production'
  'Dev'
])
@description('The environment type')
param environmentType string = 'Dev'

@description('The base name for the OpenAI service')
param openAiServiceBaseName string

@description('The base name for the API Management service')
param apimServiceBaseName string

@description('The base name for the Log Analytics workspace')
param logAnalyticsWorkspaceBaseName string

@description('The base name for the Application Insights instance')
param applicationInsightsBaseName string

@description('The base name for the APIM logger')
param apimLoggerBaseName string

@description('The publisher name for the API Management service')
param publisherName string

@description('The publisher email for the API Management service')
param publisherEmail string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The WireMock URL')
param mockApiAiSearchUrl string

@description('The base name for the ML Studio workspace')
param mlStudioBaseName string

@description('The model ID for the ML Studio model used from the model catalog')
param modelId string = 'azureml://registries/azureml/models/Phi-3-mini-4k-instruct' // Do not include the version when copying the Model ID

@description('The base name for the ML Studio model endpoint')
param mlModelEndpointBaseName string = 'ml-model-endpoint'

@description('The base name for the storage account')
param storageAccountBaseName string

@description('The base name for the key vault')
param keyVaultBaseName string

var uniqueSuffix = uniqueString(resourceGroup().id)
var openAiServiceName = '${openAiServiceBaseName}-${uniqueSuffix}'
var apimServiceName = '${apimServiceBaseName}-${uniqueSuffix}'
var logAnalyticsWorkspaceName = '${logAnalyticsWorkspaceBaseName}-${uniqueSuffix}'
var applicationInsightsName = '${applicationInsightsBaseName}-${uniqueSuffix}'
var apimLoggerName = '${apimLoggerBaseName}-${uniqueSuffix}'
var mlStudioName = '${mlStudioBaseName}-${uniqueSuffix}'
var mlModelEndpointName = '${mlModelEndpointBaseName}-${uniqueSuffix}'
var storageAccountName = '${storageAccountBaseName}${uniqueSuffix}'
var keyVaultName = '${keyVaultBaseName}-${uniqueSuffix}'

var environmentConfigurationMap = {
  Production: {
    storage: {
      sku: {
        name: 'Standard_LRS'
      }
    }
    keyVault: {
      sku: {
        name: 'standard'
      }
    }
    openAI: {
      sku: {
        name: 'S0'
      }
      deployment: {
        sku: {
          name: 'Standard'
          capacity: 20
        }
      }
    }
    apiManagement: {
      sku: {
        name: 'Developer'
        capacity: 1
      }
    }
  }
  Dev: {
    storage: {
      sku: {
        name: 'Standard_LRS'
      }
    }
    keyVault: {
      sku: {
        name: 'standard'
      }
    }
    openAI: {
      sku: {
        name: 'S0'
      }
      deployment: {
        sku: {
          name: 'Standard'
          capacity: 20
        }
      }
    }
    apiManagement: {
      sku: {
        name: 'Developer'
        capacity: 1
      }
    }
  }
}

// Storage Account
module storageModule './modules/storage/storage.bicep' = {
  name: 'storageModule'
  params: {
    location: location
    name: storageAccountName
    sku: environmentConfigurationMap[environmentType].storage.sku.name
  }
}

// Key Vault
module keyVaultModule './modules/key-vault/key-vault.bicep' = {
  name: 'keyvaultModule'
  params: {
    location: location
    name: keyVaultName
    sku: environmentConfigurationMap[environmentType].keyVault.sku.name
  }
}

// Log Analytics Workspace
module logAnalyticsWorkspaceModule './modules/app-insights/log-analytics-workspace.bicep' = {
  name: 'logAnalyticsWorkspaceModule'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceLocation: location
  }
}

// Application Insights
module appInsightsModule './modules/app-insights/app-insights.bicep' = {
  name: 'appInsightsModule'
  params: {
    applicationInsightsName: applicationInsightsName
    lawId: logAnalyticsWorkspaceModule.outputs.id
    customMetricsOptedInType: 'WithDimensions'
  }
}

// OpenAI service + Deployment
module openAiModule 'modules/ai-services/openai.bicep' = {
  name: 'openAiModule'
  params: {
    environmentConfigurationMap: environmentConfigurationMap
    environmentType: environmentType
    openAiServiceName: openAiServiceName
    location: location
    lawId: logAnalyticsWorkspaceModule.outputs.id
  }
}

// ML Studio
module mlStudioModule './modules/ml-studio/ml-studio.bicep' = {
  name: 'mlStudioModule'
  params: {
    // Workspace info
    location: 'eastus2' // Allows to deploy serverless endpoints for models from the model catalog
    name: mlStudioName

    // dependencies
    appInsightsId: appInsightsModule.outputs.id
    keyVaultId: keyVaultModule.outputs.keyVaultId
    storageAccountId: storageModule.outputs.accountId
  }
}

// Create an ML model in the ML workspace and add an API in the existing APIM that connects to the model (with a /chat/completions operation), using a serverless endpoint with API key auth
module mlModelModule './modules/ml-studio/ml-model.bicep' = {
  name: 'mlModelModule'
  params: {
    mlWorkspaceName: mlStudioName
    location: mlStudioModule.outputs.location
    modelId: modelId
    endpointName: mlModelEndpointName
  }
}

// API Management + Connection to App Insights (logger)
module apim 'modules/apim/apim.bicep' = {
  name: 'apimModule'
  params: {
    environmentConfigurationMap: environmentConfigurationMap
    environmentType: environmentType
    apimServiceName: apimServiceName
    location: location
    publisherName: publisherName
    publisherEmail: publisherEmail
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    appInsightsId: appInsightsModule.outputs.id
    apimLoggerName: apimLoggerName
  }
}

// APIM OpenAI Endpoint
module apimOpenAiEndpoint 'modules/apim/apis/api-openai.bicep' = {
  name: 'apimOpenAiEndpointModule'
  params: {
    apimServiceName: apimServiceName
    openAiServiceName: openAiServiceName
    openAIServiceEndpoint: openAiModule.outputs.endpoint
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    appInsightsId: appInsightsModule.outputs.id
    apimLoggerName: apimLoggerName
  }
  dependsOn: [
    apim
  ]
}

// APIM Mock AI Search Endpoint
module apimMockAiSearchEndpoint 'modules/apim/apis/api-mock-aisearch.bicep' = {
  name: 'apimMockAiSearchEndpointModule'
  params: {
    apimServiceName: apimServiceName
    wiremockUrl: mockApiAiSearchUrl
    apiDisplayName: 'Mock AI Search API'
    apiDescription: 'API that connects to a WireMock instance for AI Search'
    subscriptionRequired: false
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    appInsightsId: appInsightsModule.outputs.id
    apimLoggerName: apimLoggerName
  }
  dependsOn: [
    apim
  ]
}

// APIM ML Model Endpoint
module apimMLModelEndpoint 'modules/apim/apis/api-ml-model.bicep' = {
  name: 'apimMLModelEndpointModule'
  params: {
    apimServiceName: apimServiceName
    mlWorkspaceName: mlStudioName
    mlEndpointName: mlModelModule.outputs.endpointId
    mlEndpointUrl: mlModelModule.outputs.modelUrl
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    appInsightsId: appInsightsModule.outputs.id
    apimLoggerName: apimLoggerName
  }
  dependsOn: [
    apim
  ]
}

