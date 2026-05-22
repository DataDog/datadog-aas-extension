## Templates

| File | Scenario |
|---|---|
| [`install-web-app.bicep`](install-web-app.bicep) / [`install-web-app.json`](install-web-app.json) | Azure Web App |
| [`install-web-app-slot.bicep`](install-web-app-slot.bicep) / [`install-web-app-slot.json`](install-web-app-slot.json) | Azure Web App — deployment slot |
| [`install-function-app-slot.bicep`](install-function-app-slot.bicep) / [`install-function-app-slot.json`](install-function-app-slot.json) | Azure Function App — deployment slot (.NET only) |

Each file has a `version` field (Bicep: top comment; ARM JSON: `metadata.version`). The inline code snippets in the Datadog documentation carry matching version identifiers — if yours differ, re-download the latest template.

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
            "apiVersion": "2025-03-01",
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

## Azure Function Apps (deployment slot)

Function Apps can fail with "MoveDirectory" errors during extension install because the Functions runtime holds file locks on `C:\home\SiteExtensions\`. The fix is `WEBSITE_PRIVATE_EXTENSIONS=0` as a sticky slot setting: it prevents the runtime from loading private site extensions (and acquiring those locks) on the slot, while remaining sticky so it never propagates to production after a swap.

This is only needed when both of the following are true:
- The target resource is an Azure Function App (kind contains `functionapp`)
- You are targeting a deployment slot (not the production slot directly)

### ARM JSON

See [`install-function-app-slot.json`](install-function-app-slot.json) for the full template.

Deploy with:
```
az deployment group create --resource-group <RESOURCE GROUP> --template-file install-function-app-slot.json
```

### Bicep

See [`install-function-app-slot.bicep`](install-function-app-slot.bicep) for the full template.

Deploy with:
```
az deployment group create --resource-group <RESOURCE GROUP> --template-file install-function-app-slot.bicep
```

> **Note:** `slotConfigNames` replaces the full list of sticky setting names. If you have other slot-sticky settings, add their names to the `appSettingNames` array.