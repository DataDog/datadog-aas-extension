## Requirements:
The Datadog APM Windows Site Extensions require that you setup the [Datadog Azure App Service Integration](https://docs.datadoghq.com/integrations/azure_app_services/) first.
Please follow the directions in the referenced document.

## Supported Runtimes

- .NET
- Java
- Node

## Installation:
Fully stop your web app before installing, modifying, or removing a Datadog APM Site Extension.

### IMPORTANT NOTICES:
#### *Restart* recycles an Application Pool. The app must be *STOPPED* before any changes to this extension.
#### *Beta users will need to uninstall the beta extension before installing the official release.*

### Documentation:

- [Datadog Azure App Service Integration](https://docs.datadoghq.com/integrations/azure_app_services/) 
- [Datadog Azure App Service Extension](https://docs.datadoghq.com/serverless/azure_app_services)

### Relevant Links:
- [Datadog Azure App Service Blog](https://www.datadoghq.com/blog/azure-app-service-extension/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [.NET NuGet Package](https://www.nuget.org/packages/Datadog.AzureAppServices.DotNet)
- [Java NuGet Package](https://www.nuget.org/packages/Datadog.AzureAppServices.Java.Apm)
- [Node NuGet Package](https://www.nuget.org/packages/Datadog.AzureAppServices.Node.Apm)
