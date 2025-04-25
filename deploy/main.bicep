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

var uniqueSuffix = uniqueString(resourceGroup().id)
var openAiServiceName = '${openAiServiceBaseName}-${uniqueSuffix}'
var apimServiceName = '${apimServiceBaseName}-${uniqueSuffix}'
var logAnalyticsWorkspaceName = '${logAnalyticsWorkspaceBaseName}-${uniqueSuffix}'
var applicationInsightsName = '${applicationInsightsBaseName}-${uniqueSuffix}'
var apimLoggerName = '${apimLoggerBaseName}-${uniqueSuffix}'

var environmentConfigurationMap = {
  Production: {
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

// 1. Log Analytics Workspace
module logAnalyticsWorkspaceModule './modules/app-insights/log-analytics-workspace.bicep' = {
  name: 'logAnalyticsWorkspaceModule'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceLocation: location
  }
}

// 2. Application Insights
module appInsightsModule './modules/app-insights/app-insights.bicep' = {
  name: 'appInsightsModule'
  params: {
    applicationInsightsName: applicationInsightsName
    lawId: logAnalyticsWorkspaceModule.outputs.id
    customMetricsOptedInType: 'WithDimensions'
  }
}

// 3. OpenAI service + Deployment
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

// 4. API Management + Connection to App Insights (logger)
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

// 5. APIM OpenAI Endpoint
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

// 6. APIM Mock AI Search Endpoint
module apimMockAiSearchEndpoint 'modules/apim/apis/api-mock-aisearch.bicep' = {
  name: 'apimMockAiSearchEndpointModule'
  params: {
    apimServiceName: apimServiceName
    wiremockUrl: mockApiAiSearchUrl
    apiDisplayName: 'Mock AI Search API'
    apiDescription: 'API that connects to a WireMock instance for AI Search'
    apiVersion: 'v1'
    subscriptionRequired: false
  }
  dependsOn: [
    apim
  ]
}
