@allowed([
  'Production'
  'Dev'
])
@description('The environment type')
param environmentType string = 'Dev'

@description('The name of the OpenAI service')
param openAiServiceName string

@description('The name of the API Management service')
param apimServiceName string

@description('The publisher name for the API Management service')
param publisherName string

@description('The publisher email for the API Management service')
param publisherEmail string

@description('The location for all resources')
param location string = resourceGroup().location

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

module openAiModule 'modules/openai.bicep' = {
  name: 'openAiModule'
  params: {
    environmentConfigurationMap: environmentConfigurationMap
    environmentType: environmentType
    openAiServiceName: openAiServiceName
    location: location
  }
}

module apim 'modules/apim.bicep' = {
  name: 'apimModule'
  params: {
    environmentConfigurationMap: environmentConfigurationMap
    environmentType: environmentType
    apimServiceName: apimServiceName
    location: location
    publisherName: publisherName
    publisherEmail: publisherEmail
  }
}

module apimOpenAiEndpoint 'modules/apim-openai-endpoint.bicep' = {
  name: 'apimOpenAiEndpointModule'
  params: {
    apimServiceName: apimServiceName
    openAiServiceName: openAiServiceName
    openAIServiceEndpoint: openAiModule.outputs.endpoint
  }
  dependsOn: [
    apim
  ]
}
