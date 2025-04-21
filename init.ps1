# Script for configuring the GitHub Actions workflow to deploy the infrastructure for the first time

# In a PowerShell terminal, run the following script, step by step

# 1) Sign in to Azure
Connect-AzAccount

# 2) Define the GitHub organization and repository names
$githubOrganizationName = 'agustin-gabrielli-sw'
$githubRepositoryName = 'infra-as-code-test'

# 3) Create a workload identity (concretely an App Registration) and associate it with your GitHub repository
# An App Registration is used to give an identity to apps, scripts, etc. In this case, it will be used to give an identity to the GitHub Actions workflow
$applicationRegistration = New-AzADApplication -DisplayName 'infra-as-code-test-workflow'

# Add a federated identity credential to the App Registration, so GitHub Actions can authenticate as that app without a client secret
New-AzADAppFederatedCredential `
   -Name 'infra-as-code-test-workflow' `
   -ApplicationObjectId $applicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"

# 4) Get your existing target resource group
$resourceGroup = Get-AzResourceGroup -Name agustin-gabrielli-rg

# 5) Create a service principal and assign the Contributor role to it 
# In other words, grant your workload identity access to the rg
New-AzADServicePrincipal -AppId $applicationRegistration.AppId
New-AzRoleAssignment `
   -ApplicationId $($applicationRegistration.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId

# 6) Prepare GitHub secrets
$azureContext = Get-AzContext
Write-Host "AZURE_CLIENT_ID: $($applicationRegistration.AppId)"
Write-Host "AZURE_TENANT_ID: $($azureContext.Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $($azureContext.Subscription.Id)"

# 7) Go to the GitHub repo and add the secrets
# In the repo, go to Settings -> Secrets and Variables -> Actions
# Add the following secrets:
# AZURE_CLIENT_ID
# AZURE_TENANT_ID
# AZURE_SUBSCRIPTION_ID

