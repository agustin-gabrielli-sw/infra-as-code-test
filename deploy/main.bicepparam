using 'main.bicep'

param environmentType = 'Dev'
param openAiServiceBaseName = 'agustin-gabrielli-open-ai'
param apimServiceBaseName = 'agustin-gabrielli-apim'
param publisherName = 'Agustin Gabrielli'
param publisherEmail = 'agustin.gabrielli@southworks.com'
param apimLoggerBaseName = 'agustin-gabrielli-apim-logger'
param applicationInsightsBaseName = 'agustin-gabrielli-appinsights'
param logAnalyticsWorkspaceBaseName = 'agustin-gabrielli-loganalytics'
param mockApiAiSearchUrl = '' // Passed as a secret in the Github Actions workflow
