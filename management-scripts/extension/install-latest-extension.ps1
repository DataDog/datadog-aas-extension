
# Per site, you can use the username and password from the publish profile you download.
# The recommended approach is to use a service account which has permission to access Kudu
# Note that the $username here should look like `SomeUserName`, and **not** `SomeSite\SomeUserName`
 param (
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$true)][string]$SiteName,
    [Parameter(Mandatory=$false)][string]$Username="ambient",
    [Parameter(Mandatory=$false)][string]$Password="ambient",
    [Parameter(Mandatory=$false)][string]$Extension="Datadog.AzureAppServices.DotNet",
    [Parameter(Mandatory=$false)][string]$DDApiKey="<not-set>",
    [Parameter(Mandatory=$false)][string]$DDEnv="<not-set>",
    [Parameter(Mandatory=$false)][string]$DDService="<not-set>",
    [Parameter(Mandatory=$false)][string]$DDVersion="<not-set>",
    [Parameter(Mandatory=$false)][Switch]$Remove
 )

# 
# Example calls of this script:
#
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Username $username -Password $password
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Username $username -Password $password -Remove
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Remove
#

# Example call of install with datadog environment variables applied:
# 
# .\install-latest-extension.ps1 -Username $username -Password $password -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -DDApiKey $ddApiKey -DDEnv $ddEnv -DDService $ddService -DDVersion $ddVersion
#

if ($Username -eq "ambient") {
	$Username=$env:DD_AAS_USER
}

if ($Password -eq "ambient") {
	$Password=$env:DD_AAS_PASS
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$baseApiUrl = "https://${SiteName}.scm.azurewebsites.net/api"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $Password)))
$userAgent = "powershell/1.0"

$siteExtensionsBase="${baseApiUrl}/siteextensions"
$siteExtensionManage="${baseApiUrl}/siteextensions/${Extension}"

$siteApiUrl="https://management.azure.com/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroup}/providers/Microsoft.Web/sites/${SiteName}"

# Stop the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/stop
Write-Output "[${SiteName}] Stopping webapp"
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/stop?api-version=2019-08-01"

$skipVar="<not-set>"

az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_AAS_SCRIPT_INSTALL=1
	
if ($DDApiKey -ne $skipVar) {
	az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_API_KEY=$DDApiKey
}

if ($DDEnv -ne $skipVar) {
	az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_ENV=$DDEnv
}

if ($DDService -ne $skipVar) {
	az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_SERVICE=$DDService
}

if ($DDVersion -ne $skipVar) {
	az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_VERSION=$DDVersion
}

if ($Remove) {
  Write-Output "Attempting to remove ${Extension} from ${SiteName}"
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method DELETE
  Write-Output "[${SiteName}] Completed request to remove ${Extension}"
}
else {
  Write-Output "Attempting to install latest ${Extension}"
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT
  Write-Output "[${SiteName}] Completed request to install latest of ${Extension}"
}

# Start the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/start
Write-Output "[${SiteName}] Starting webapp"
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/start?api-version=2019-08-01"
