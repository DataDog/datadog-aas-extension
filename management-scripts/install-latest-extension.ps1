
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
Write-Output "Stopping webapp ${SiteName}"
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/stop?api-version=2019-08-01"

if ($Remove) {
  Write-Output "Attempting to remove ${Extension} from ${SiteName}"
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method DELETE
  Write-Output "Completed request to remove ${Extension} from ${SiteName}"
}
else {
  Write-Output "Attempting to install latest ${Extension} on ${SiteName}"
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT
  Write-Output "Completed request to install latest of ${Extension} to ${SiteName}"
}

# Start the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/stop
Write-Output "Starting webapp ${SiteName}"
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/start?api-version=2019-08-01"
