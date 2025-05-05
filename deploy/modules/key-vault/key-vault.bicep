param name string

param location string = resourceGroup().location

@allowed(['standard', 'premium'])
param sku string

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: name
  location: location
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: subscription().tenantId
  }
}

output keyVaultId string = keyVault.id
