// Version: 1.0.0
// Description: Install Datadog APM extension on an Azure Web App deployment slot.

@secure()
param datadogApiKey string

param webAppName string
param slotName string
param ddSite string = 'datadoghq.com'
param ddService string = 'my-service'
param ddEnv string = 'staging'
param ddVersion string = '0.0.0'

@allowed([
  'Datadog.AzureAppServices.DotNet'
  'Datadog.AzureAppServices.Java.Apm'
  'Datadog.AzureAppServices.Node.Apm'
])
param extensionName string = 'Datadog.AzureAppServices.DotNet'

resource webApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: webAppName
}

resource slot 'Microsoft.Web/sites/slots@2025-03-01' = {
  parent: webApp
  name: slotName
  properties: {
    siteConfig: {
      appSettings: [
        // Add your existing slot app settings here
        { name: 'DD_API_KEY', value: datadogApiKey }
        { name: 'DD_SITE', value: ddSite }
        { name: 'DD_SERVICE', value: ddService }
        { name: 'DD_ENV', value: ddEnv }
        { name: 'DD_VERSION', value: ddVersion }
      ]
    }
  }
}

resource datadogExtension 'Microsoft.Web/sites/slots/siteextensions@2025-03-01' = {
  parent: slot
  name: extensionName
  // Available values for extensionName:
  // 'Datadog.AzureAppServices.DotNet'
  // 'Datadog.AzureAppServices.Java.Apm'
  // 'Datadog.AzureAppServices.Node.Apm'
}
