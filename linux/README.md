This readme outlines how to set up Datadog tracing with your Azure App Service Linux application. Making the following changes in the Azure portal will allow the tracer to initialize when your application is started.

_Note: Currently only NODE is supported._

- ### Application Settings
    - `DD_API_KEY` is your Datadog API key 
    - `DD_SITE` is the Datadog site [parameter](https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site) (defaults to datadoghq.com)
    - `DD_SERVICE` is the service name used for this program. Defaults to the name field value in package.json.
    - `DD_START_APP` is the command used to start your application. For example, `node ./bin/www`

- ### General Settings
    - Add the following to the startup command box
    
          curl -s https://raw.githubusercontent.com/DataDog/datadog-aas-extension/linux-v0.1.2-beta/linux/datadog_wrapper | bash
