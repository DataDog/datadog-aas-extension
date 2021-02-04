 
# This script relies on azure cli being setup and authenticated on your machine

 param (
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$resourceGroupName,
    [Parameter(Mandatory=$false)][string]$subscriptionId="{subscriptionId}"
 )

$name="dd-aas-netcore31-latest"
$resourceGroupName="apm-azure-app-services"
# Override the subscription id, or allow your azure cli defaults to determine it
$subscriptionId="{subscriptionId}"
$siteExtensionId="Datadog.AzureAppServices.DotNet"

$siteApiUrl="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/sites/${name}"

# Stop the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/stop
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/stop?api-version=2019-08-01"

# Install or upgrade the extension (TODO: FAILS WITH 400 BAD REQUEST - https://github.com/MicrosoftDocs/feedback/issues/3448)
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/installsiteextension
az rest -m PUT --header "Accept=application/json" -u "${siteApiUrl}/siteextensions/${siteExtensionId}?api-version=2019-08-01"

# Start the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/start
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/start?api-version=2019-08-01"

