
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
    [Parameter(Mandatory=$false)][string]$DDSite="<not-set>",
    [Parameter(Mandatory=$false)][string]$DDEnv="<not-set>",
    [Parameter(Mandatory=$false)][string]$DDService="<not-set>",
    [Parameter(Mandatory=$false)][string]$DDVersion="<not-set>",
    [Parameter(Mandatory=$false)][string]$ExtensionVersion,
    [Parameter(Mandatory=$false)][Switch]$Remove
 )

# 
# Example calls of this script:
#
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Username $username -Password $password
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Username $username -Password $password -ExtensionVersion 1.5.0
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -ExtensionVersion 1.5.0
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Username $username -Password $password -Remove
# .\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -Remove
#
# .\install-latest-extension.ps1 -SubscriptionId 8c56d827-5f07-45ce-8f2b-6c5001db5c6f -ResourceGroup apm-aas-junkyard -SiteName dd-netcore31-junkyard-dev -Extension DevelopmentVerification.DdDotNet.Apm -ExtensionVersion 0.1.37-prerelease
# 

# Example call of install with datadog environment variables applied:
# 
# .\install-latest-extension.ps1 -Username $username -Password $password -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $webAppName -DDSite $ddSite -DDApiKey $ddApiKey -DDEnv $ddEnv -DDService $ddService -DDVersion $ddVersion
#

if ($Username -eq "ambient") {
	$Username=$env:DD_AAS_USER
}

if ($Password -eq "ambient") {
	$Password=$env:DD_AAS_PASS
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $Password)))
$userAgent = "powershell/1.0"

$siteApiUrl="https://management.azure.com/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroup}/providers/Microsoft.Web/sites/${SiteName}"
$siteConfig = az rest -m GET --header "Accept=application/json" -u "${siteApiUrl}?api-version=2019-08-01" | ConvertFrom-Json

$baseApiUrl = "https://$($siteConfig.properties.enabledHostNames -like "*.scm.*")/api"
$siteExtensionsBase="${baseApiUrl}/siteextensions"
$siteExtensionManage="${baseApiUrl}/siteextensions/${Extension}"

# Stop the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/stop
Write-Output "[${SiteName}] Stopping webapp"
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/stop?api-version=2019-08-01"

$skipVar="<not-set>"

az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_AAS_SCRIPT_INSTALL=1
	
if ($DDApiKey -ne $skipVar) {
	az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_API_KEY=$DDApiKey
}
	
if ($DDSite -ne $skipVar) {
	az webapp config appsettings set -n ${SiteName} -g ${ResourceGroup} --settings DD_SITE=$DDSite
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
  Write-Output "[${SiteName}] Attempting to remove ${Extension}"
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method DELETE
  Write-Output "[${SiteName}] Completed request to remove ${Extension}"
}
else {
	if ($PSBoundParameters.ContainsKey('ExtensionVersion')) {
		
        Write-Output "[${SiteName}] Attempting to install version ${ExtensionVersion} of ${Extension}"
		
		$packageUrl="https://globalcdn.nuget.org/packages/${Extension}.${ExtensionVersion}.nupkg".ToLower()
		
		Write-Output "[${SiteName}] Setting package URL to ${packageUrl}"
		
		$install=$true
		
		# If this is a downgrade, we need to remove the extension first or the install logic will ignore the package
		$installedExtensions=Invoke-RestMethod -Uri $siteExtensionsBase -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method GET
		
		Foreach ($installedExtension in @($installedExtensions)){
			
			if ($installedExtension.id -eq $Extension) {
				if ($installedExtension.version -eq $ExtensionVersion) {
					Write-Output "[${SiteName}] Package version (${ExtensionVersion}) is already installed."
					$install=$false
					break;
				}
				else {
					Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method DELETE
					Write-Output "[${SiteName}] Requested package removal. "
					Write-Output "[${SiteName}] Waiting ten seconds to ensure removal is complete. "
					Start-Sleep -s 10
					break;
				}
			}
		}
		
		if ($install) {
			# https://github.com/projectkudu/kudu/blob/98ad238b860f81a4cb4e3419c8785a58ba68e661/Kudu.Services/SiteExtensions/SiteExtensionController.cs#L240
			$siteExtensionInfo = @{        
			  packageUri = $packageUrl
			};
			
			$json = $siteExtensionInfo | ConvertTo-Json;
			
			Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT -ContentType application/json -Body $json
			
			Write-Output "[${SiteName}] Completed request to install version ${ExtensionVersion} of ${Extension}"
		}
	}
	else {
        Write-Output "Attempting to install latest ${Extension}"
        Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=$("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT
		Write-Output "[${SiteName}] Completed request to install latest of ${Extension}"
	}
}

# Start the web app
# https://docs.microsoft.com/en-us/rest/api/appservice/webapps/start
Write-Output "[${SiteName}] Starting webapp"
az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/start?api-version=2019-08-01"
