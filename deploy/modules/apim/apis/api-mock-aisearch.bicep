@description('The name of the API Management service')
param apimServiceName string

@description('The name of the API')
param apiName string = 'mock-aisearch'

@description('The display name of the API')
param apiDisplayName string = 'Mock AI Search API'

@description('The description of the API')
param apiDescription string = 'API that connects to a WireMock instance for AI Search'

@description('The URL of the WireMock instance')
param wiremockUrl string

@description('The subscription required for accessing the API')
param subscriptionRequired bool = false

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

resource api 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  name: apiName
  parent: apimService
  properties: {
    displayName: apiDisplayName
    description: apiDescription
    serviceUrl: wiremockUrl
    path: 'mock-aisearch'
    protocols: [
      'https'
    ]
    subscriptionRequired: subscriptionRequired
    apiType: 'http'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  name: 'policy'
  parent: api
  properties: {
    value: loadTextContent('./policies/aisearch-policy.xml')
    format: 'rawxml'
  }
}
