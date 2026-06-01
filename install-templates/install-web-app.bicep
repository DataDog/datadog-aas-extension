// Version: 1.0.0
// Description: Install Datadog APM extension on an Azure Web App.

@secure()
param datadogApiKey string

param webAppName string
param ddSite string = 'datadoghq.com'
param ddService string = ''
param ddEnv string = 'prod'
param ddVersion string = ''

@allowed([
  'Datadog.AzureAppServices.DotNet'
  'Datadog.AzureAppServices.Java.Apm'
  'Datadog.AzureAppServices.Node.Apm'
])
param extensionName string = 'Datadog.AzureAppServices.DotNet'

resource webApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: webAppName
}

resource appSettings 'Microsoft.Web/sites/config@2025-03-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    // Add your existing app settings here
    DD_API_KEY: datadogApiKey
    DD_SITE: ddSite
    DD_SERVICE: ddService
    DD_ENV: ddEnv
    DD_VERSION: ddVersion
  }
}

resource datadogExtension 'Microsoft.Web/sites/siteextensions@2025-03-01' = {
  parent: webApp
  name: extensionName
  // Available values for extensionName:
  // 'Datadog.AzureAppServices.DotNet'
  // 'Datadog.AzureAppServices.Java.Apm'
  // 'Datadog.AzureAppServices.Node.Apm'
  dependsOn: [appSettings]
}
