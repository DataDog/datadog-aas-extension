## Requirements:
The .NET Datadog APM Site Extension requires that you setup the [Microsoft Azure Integration](https://docs.datadoghq.com/integrations/azure_app_services/) first.
Please follow the directions in the referenced document.

## Installation:
Fully stop your web app before installing, modifying, or removing the .NET Datadog APM Site Extension.
This site extension uses the [.NET Profiling API](https://docs.microsoft.com/en-us/dotnet/framework/unmanaged-api/profiling/profiling-interfaces) which hooks in at process start.

### IMPORTANT NOTICES:
#### *Restart* recycles an application pool, the app must be *STOPPED* before any changes to this extension.
####*Beta users will need to uninstall the beta extension before installing the official release*

### Relevant Links:

[Datadog Azure App Service Documentation](https://docs.datadoghq.com/serverless/azure_app_services)
[Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
[Nuget Package](https://www.nuget.org/packages/Datadog.AzureAppServices.DotNet)