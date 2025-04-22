/*
  Creates a chat completion endpoint in APIM that connects to the OpenAI service
*/

@description('The name of the API Management service')
param apimServiceName string

@description('The endpoint of the OpenAI service')
param openAIServiceEndpoint string

@description('The name of the OpenAI service')
param openAiServiceName string

@description('The name of the API')
param apiName string = 'openai-chat'

@description('The display name of the API')
param apiDisplayName string = 'OpenAI Chat Completion'

@description('The description of the OpenAI API in API Management. Defaults to "Azure OpenAI API inferencing API".')
param apiDescription string = 'Azure OpenAI API inferencing API'

@description('The version of the OpenAI API in API Management. Defaults to "2024-02-01".')
param openAIAPIVersion string = '2024-02-01'

@description('The URL for the OpenAI API specification')
param openAIAPISpecURL string = 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/${openAIAPIVersion}/inference.json'

@description('The name of the OpenAI subscription in API Management. Defaults to "openai-subscription".')
param openAISubscriptionName string = 'openai-subscription'

@description('The description of the OpenAI subscription in API Management. Defaults to "OpenAI Subscription".')
param openAISubscriptionDescription string = 'OpenAI Subscription'

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

resource namedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'openai-key'
  parent: apimService
  properties: {
    displayName: 'openai-key' // This is the name that should be as a placeholder in the apiPolicy.xml file
    value: listKeys(resourceId('Microsoft.CognitiveServices/accounts', openAiServiceName), '2024-10-01').key1
    secret: true
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: apiName
  parent: apimService
  properties: {
    apiType: 'http'
    description: apiDescription
    displayName: apiDisplayName
    format: 'openapi-link'
    protocols: [
      'https'
    ]
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    subscriptionRequired: true
    type: 'http'
    value: openAIAPISpecURL
    path: 'openaitest'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-06-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'xml'
    value: loadTextContent('../apiPolicy.xml')
  }
  dependsOn: [namedValue]
}

// This is the backend that can be used to access the OpenAI API through the APIM
resource backendOpenAI 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  name: 'openai-backend'
  parent: apimService
  properties: {
    description: 'backend description'
    url: '${openAIServiceEndpoint}/openai'
    protocol: 'http'
  }
}

// This is the subscription that can be used to access the OpenAI API through the APIM
resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2024-06-01-preview' = {
  name: openAISubscriptionName
  parent: apimService
  properties: {
    allowTracing: true
    displayName: openAISubscriptionDescription
    scope: '/apis/${api.id}'
    state: 'active'
  }
}
