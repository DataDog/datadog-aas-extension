 
# Per site, you can use the username and password from the publish profile you download.
# The recommended approach is to use a service account which has permission to access Kudu
# Note that the $username here should look like `SomeUserName`, and **not** `SomeSite\SomeUserName`

 param (
    [Parameter(Mandatory=$true)][string]$subscriptionId,
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$siteName,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$tenantId,
    [Parameter(Mandatory=$true)][string]$token
 )

# https://docs.microsoft.com/en-us/rest/api/azure/

$apiUrl=https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Web/sites/${siteName}

$stopUrl=${apiUrl}/stop?api-version=2019-08-01
$startUrl=${apiUrl}/start?api-version=2019-08-01

$headers='grant_type=client_credentials&client_id=${appId}&client_secret=${token}&resource=https%3A%2F%2Fmanagement.azure.com%2F'

# Stop the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/stop
# POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Web/sites/{siteName}/stop?api-version=2019-08-01
# 
curl -X POST -d $headers $stopUrl

# Install or upgrade the extension
# 
.\manage-site-extension.ps1 -sitename $siteName -username $username -password $password -extension "Datadog.AzureAppServices.DotNet" -InstallLatest

# Start the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/start
# POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Web/sites/{siteName}/start?api-version=2019-08-01
# 
curl -X POST -d $headers $startUrl