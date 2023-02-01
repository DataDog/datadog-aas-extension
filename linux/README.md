This readme outlines how to set up Datadog tracing with your Azure App Service Linux application. Making the following changes in the Azure portal will allow the tracer to initialize when your application is started.

_Note: Currently Java, NODE, .NET, PHP and Python are supported._

### Application Settings
- `DD_API_KEY` is your Datadog API key
- `DD_SITE` is the Datadog site [parameter](https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site) (defaults to datadoghq.com)
- `DD_SERVICE` is the service name used for this program. Defaults to the name field value in package.json.
- `DD_START_APP` is the command used to start your application. For example, `node ./bin/www`

![storms-nodejs-example - Microsoft Azure 2022-11-30 at 4 15 47 PM](https://p-qkfgo2.t2.n0.cdn.getcloudapp.com/items/YEuD88kN/57eceb6b-dd34-4d5f-a7ea-a8fcc2ec77ba.jpg?source=viewer&v=505cc168a458a4ec84b7d6a903f78493)

### General Settings
##### Node, .NET, PHP or Python
Add the following to the startup command box

      curl -s https://raw.githubusercontent.com/DataDog/datadog-aas-extension/linux-v0.1.4-beta/linux/datadog_wrapper | bash

![storms-nodejs-example - Microsoft Azure 2022-11-30 at 4 15 26 PM](https://p-qkfgo2.t2.n0.cdn.getcloudapp.com/items/P8uNWWQ6/02c4f33f-f4d9-42b3-b746-3d5c9d62a8f3.jpg?source=viewer&v=3db9f9bba7f342e88c43da5aed1218fd)

##### Java
Download the `datadog_startup.sh` file from the releases and upload it to your application with the [Azure CLI command](https://learn.microsoft.com/en-us/azure/app-service/deploy-zip?tabs=cli#deploy-a-startup-script):

      az webapp deploy --resource-group <group-name> --name <app-name> --src-path scripts/startup.sh --type=startup

Alternatively you can upload this script as part of your application and set the  startup command in general settings as its location (e.g. `/home/site/wwwroot/datadog_startup.sh`)

If you are already using a startup script, add the following curl command to the end of your script:

     curl -s https://raw.githubusercontent.com/DataDog/datadog-aas-extension/linux-v0.1.4-beta/linux/datadog_wrapper | bash
### Viewing traces

1. Azure will restart the application when new Application Settings are saved. However, a restart may be required for the startup command to be recognized by App Services if it is added and saved at a different time.

2. After the AAS application restarts, the traces can be viewed by searching for the service name (DD_SERVICE) in the [APM Service page](https://docs.datadoghq.com/tracing/services/service_page/) of your Datadog app.

### Custom Metrics

To enable custom metrics for your application with DogStatsD, add  `DD_CUSTOM_METRICS_ENABLED` and set it as `true` in your Application Settings.

To configure your application to submit metrics, follow the appropriate steps for your runtime.

- [Java](https://docs.datadoghq.com/developers/dogstatsd/?tab=hostagent&code-lang=java)
- [Node](https://github.com/brightcove/hot-shots)
- [.NET](https://docs.datadoghq.com/developers/dogstatsd/?tab=hostagent&code-lang=dotnet#code)
- [PHP](https://docs.datadoghq.com/developers/dogstatsd/?tab=hostagent&code-lang=php)
- [Python](https://docs.datadoghq.com/developers/dogstatsd/?tab=hostagent&code-lang=python)
