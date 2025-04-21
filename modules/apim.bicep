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

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apimServiceName
  location: location
  sku: environmentConfigurationMap[environmentType].apiManagement.sku
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
  }
}

output apimServiceName string = apimService.name
output gatewayUrl string = apimService.properties.gatewayUrl 
