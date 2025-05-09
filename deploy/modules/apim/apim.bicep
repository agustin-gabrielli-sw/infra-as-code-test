@description('The environment configuration map')
param environmentConfigurationMap object

@description('The environment type')
param environmentType string

@description('The name of the API Management service')
param apimServiceName string

@description('The location for the API Management service')
param location string = resourceGroup().location

@description('The publisher name for the API Management service')
param publisherName string

@description('The publisher email for the API Management service')
param publisherEmail string

@description('The instrumentation key for the Application Insights service')
param appInsightsInstrumentationKey string = ''

@description('The ID of the Application Insights service')
param appInsightsId string = ''

@description('The name of the APIM logger')
param apimLoggerName string = 'appInsightsLogger'

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apimServiceName
  location: location
  sku: environmentConfigurationMap[environmentType].apiManagement.sku
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
  }
}

/* 
  Create a logger only if we have an App Insights ID and instrumentation key.
  This is needed to later connect APIs to this logger and send logs to App Insights.
*/
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2021-12-01-preview' = if (!empty(appInsightsId) && !empty(appInsightsInstrumentationKey)) {
  name: apimLoggerName
  parent: apimService
  properties: {
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
    description: 'Application Insights logger'
    isBuffered: false
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
  }
}

output apimServiceName string = apimService.name
output gatewayUrl string = apimService.properties.gatewayUrl 
output principalId string = apimService.identity.principalId
