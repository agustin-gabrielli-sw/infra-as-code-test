/*
  Creates a chat completion endpoint in APIM that connects to an ML model in Azure ML Studio
*/

@description('The name of the API Management service')
param apimServiceName string

@description('The name of the API')
param apiName string = 'ml-model-chat'

@description('The display name of the API')
param apiDisplayName string = 'ML Model Chat Completion'

@description('The description of the API')
param apiDescription string = 'ML model chat completion API'

@description('The instrumentation key for Application Insights')
param appInsightsInstrumentationKey string = ''

@description('The resource ID for Application Insights')
param appInsightsId string = ''

@description('Name of the APIM Logger')
param apimLoggerName string = ''

@description('The URL for the ML Model OpenAI-compatible endpoint')
param mlEndpointUrl string

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

// Create a basic OpenAPI specification for the chat completions endpoint
resource api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: apiName
  parent: apimService
  properties: {
    apiType: 'http'
    description: apiDescription
    displayName: apiDisplayName
    protocols: [
      'https'
    ]
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    subscriptionRequired: true
    type: 'http'
    path: 'ml-model'
  }
}

// Add a chat completions operation
resource chatCompletionsOperation 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  name: 'chat-completions'
  parent: api
  properties: {
    displayName: 'Chat Completions'
    method: 'POST'
    urlTemplate: '/chat/completions'
    description: 'Generate a chat completion with ML model'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-06-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'rawxml'
    value: loadTextContent('./policies/ml-model-policy.xml')
  }
}

// This is the backend that can be used to access the ML API through APIM
resource backendMLModel 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  name: 'ml-model-backend'
  parent: apimService
  properties: {
    description: 'ML Model Backend'
    url: mlEndpointUrl
    protocol: 'http'
  }
}

// Create diagnostics only if we have an App Insights ID, instrumentation key, and APIM Logger name.
resource apiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = if (!empty(appInsightsId) && !empty(appInsightsInstrumentationKey) && !empty(apimLoggerName)) {
  name: 'applicationinsights'
  parent: api
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    loggerId: resourceId(
      resourceGroup().name,
      'Microsoft.ApiManagement/service/loggers',
      apimServiceName,
      apimLoggerName
    )
    metrics: true
    verbosity: 'verbose'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
  }
}

// This is the subscription that can be used to access the ML Model API through APIM
resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = {
  name: 'ml-model-subscription'
  parent: apimService
  properties: {
    allowTracing: true
    displayName: 'ML Model Subscription'
    scope: '/apis/${api.id}'
    state: 'active'
  }
}
