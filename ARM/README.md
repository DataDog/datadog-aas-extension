## Configuring Datadog in ARM Templates

 - [Parameters to accept Datadog configuration. ](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameters)
   - DD_API_KEY
   - DD_ENV
   - DD_SERVICE
   - DD_VERSION
   - DD_SITE
 - [Entries in `appSettings` underneath `Microsoft.Web/sites/config`](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-web?tabs=json)
	 - One to one entries for each relevant parameter

*To enable features such as [Runtime Metrics](https://docs.datadoghq.com/tracing/runtime_metrics/dotnet/) or [Logs Correlation](https://docs.datadoghq.com/tracing/connect_logs_and_traces/dotnet/?tab=serilog), you can specify these in your `appSettings` section, or you can pass them as parameters similar to the other values specified in the example below.*

```
{
    ...
    "parameters": {
        ...
        "dd_api_key": {
            "type": "String"
        },
        "dd_env": {
            "type": "String"
        },
        "dd_service": {
            "type": "String"
        },
        "dd_version": {
            "type": "String"
        },
        "dd_site": {
            "defaultValue": "datadoghq.com",
            "type": "String"
        }
    },
    ...
    "resources": [
        ...
        {
            "type": "Microsoft.Web/sites/config",
            ...
            "properties": {
                "appSettings": [
                    {
                        "name": "DD_API_KEY",
                        "value": "[parameters('dd_api_key')]"
                    },
                    {
                        "name": "DD_ENV",
                        "value": "[parameters('dd_env')]"
                    },
                    {
                        "name": "DD_SERVICE",
                        "value": "[parameters('dd_service')]"
                    },
                    {
                        "name": "DD_VERSION",
                        "value": "[parameters('dd_version')]"
                    },
                    {
                        "name": "DD_SITE",
                        "value": "[parameters('dd_site')]"
                    }
                ],
                ...
        },
        ...
        {
            "type": "Microsoft.Web/sites/siteextensions",
            "apiVersion": "2021-01-15",
            "name": "[concat(parameters('site_name'), '/Datadog.AzureAppServices.DotNet')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[resourceId('Microsoft.Web/sites', parameters('site_name'))]"
            ]
        }
    ]
}
```

Pass the relevant parameters to your deployment command:
```
az deployment group create ... --parameters dd_api_key={{api-key}} dd_env={{env}} dd_service={{service}} dd_version={{version}} dd_site={{datadog-intake}}
```