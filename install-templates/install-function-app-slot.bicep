// Version: 1.0.0
// Description: Install Datadog APM extension on an Azure Function App deployment slot. Applies WEBSITE_PRIVATE_EXTENSIONS=0 as a sticky slot setting to prevent MoveDirectory file-lock failures.

@secure()
param datadogApiKey string

param webAppName string
param slotName string

@description('Names of app settings already marked slot-sticky on this Function App. Pass [] for a new app with no existing sticky settings. This template does a full replace of slotConfigNames — omitting an existing sticky setting name will de-sticky it.')
param existingStickyAppSettingNames array
param ddSite string = 'datadoghq.com'
param ddService string = ''
@description('Environment tag — set a distinct value for each slot')
param ddEnv string = 'staging'
param ddVersion string = ''

resource webApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: webAppName
}

// WEBSITE_PRIVATE_EXTENSIONS=0 prevents the Functions runtime from holding file locks
// on C:\home\SiteExtensions\ so Kudu can complete the MoveDirectory step during install.
// Include all your existing slot app settings in this resource — ARM replaces the full set.
resource slot 'Microsoft.Web/sites/slots@2025-03-01' = {
  parent: webApp
  name: slotName
  properties: {
    siteConfig: {
      appSettings: [
        // Add your existing slot app settings here (e.g. AzureWebJobsStorage, FUNCTIONS_WORKER_RUNTIME)
        { name: 'WEBSITE_PRIVATE_EXTENSIONS', value: '0' }
        { name: 'DD_API_KEY', value: datadogApiKey }
        { name: 'DD_SITE', value: ddSite }
        { name: 'DD_SERVICE', value: ddService }
        { name: 'DD_ENV', value: ddEnv }
        { name: 'DD_VERSION', value: ddVersion }
      ]
    }
  }
}

// Marks WEBSITE_PRIVATE_EXTENSIONS as slot-sticky. Replaces the full slotConfigNames list —
// existingStickyAppSettingNames must include any settings already marked sticky or they will be de-stickied.
resource stickySettings 'Microsoft.Web/sites/config@2025-03-01' = {
  name: 'slotConfigNames'
  parent: webApp
  properties: {
    appSettingNames: union(existingStickyAppSettingNames, ['WEBSITE_PRIVATE_EXTENSIONS'])
  }
  dependsOn: [slot]
}

// Only .NET is supported for Azure Function Apps.
resource datadogExtension 'Microsoft.Web/sites/slots/siteextensions@2025-03-01' = {
  parent: slot
  name: 'Datadog.AzureAppServices.DotNet'
  dependsOn: [stickySettings]
}
