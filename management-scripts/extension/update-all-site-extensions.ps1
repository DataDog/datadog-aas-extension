
# Per site, you can use the username and password from the publish profile you download.
# The recommended approach is to use a service account which has permission to access Kudu

 param (
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$false)][string]$Username="ambient",
    [Parameter(Mandatory=$false)][string]$Password="ambient",
    [Parameter(Mandatory=$false)][string]$Extension="Datadog.AzureAppServices.DotNet",
    [Parameter(Mandatory=$false)][Switch]$Remove
 )

# 
# Example call of this script to update all installed extensions in a resource group:
# .\update-all-site-extensions.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName
# 
# Example call of this script to remove all installed extensions in a resource group:
# .\update-all-site-extensions.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -Remove
#
# Example call of this script using non-ambient credentials:
# .\update-all-site-extensions.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -Username $username -Password $password -Remove
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
$allSites=az webapp list -g $ResourceGroup | ConvertFrom-Json

Foreach($webapp in @($allSites)) {
	
	$siteName=$webapp.name
	$baseApiUrl = "https://${siteName}.scm.azurewebsites.net/api"
	$siteExtensionsBase="${baseApiUrl}/siteextensions"
	$siteExtensionManage="${baseApiUrl}/siteextensions/${extension}"

	Write-Output "[${siteName}] Requesting installed extensions."
	
	$hasExtension=$false
	$hasLatest=$false
	$installedExtensions=Invoke-RestMethod -Uri $siteExtensionsBase -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method GET

	Foreach ($installedExtension in @($installedExtensions)){
		
		$extVersion=$installedExtension.version
		$extId=$installedExtension.id
		
		if ($extId -eq $Extension) {
			
			if ($installedExtension.local_is_latest_version) {
				Write-Output "[${siteName}] Latest version (${extVersion}) of ${Extension} already installed."
				$hasLatest=$true
			}
			
			$hasExtension=$true
			break;
		}
	}
	
	if (-Not $hasExtension) {
		Write-Output "[${siteName}] ${Extension} not found."
		continue;
	}
	
	if ($hasLatest) {
		# Nothing to do
		continue;
	}
	
	Write-Output "[${siteName}] Ready to modify ${Extension}."
			
	if ($hasExtension) {
		$extensionUpdate="$PSScriptRoot\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -SiteName $siteName -Username $Username -Password $Password -Extension $Extension"
		if ($Remove) {
		  $extensionUpdate="${extensionUpdate} -Remove"
		}
		iex $extensionUpdate
	}
	
}
