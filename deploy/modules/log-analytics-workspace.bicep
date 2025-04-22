/*
  Creates a Log Analytics workspace, which is used to store and analyze logs from the Azure resources, and must be created and linked to the Application Insights instance.
*/

@description('Name of the Log Analytics resource')
param logAnalyticsWorkspaceName string

@description('Location of the Log Analytics resource')
param logAnalyticsWorkspaceLocation string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: logAnalyticsWorkspaceLocation
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}


output id string = logAnalyticsWorkspace.id
output customerId string = logAnalyticsWorkspace.properties.customerId
