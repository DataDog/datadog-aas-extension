
 param (
    [Parameter(Mandatory=$false)][Switch]$Recycle,
    [Parameter(Mandatory=$false)][Switch]$UpdateExtension,
    [Parameter(Mandatory=$false)][Switch]$FullStopStart
 )

if ($Recycle) {
	Write-Host "Preparing to recycle all samples."
}

if ($UpdateExtension) {
	Write-Host "Preparing to update extensions on all samples."
}

if ($FullStopStart) {
	Write-Host "Preparing to stop and start all samples."
}

$subscriptions=@('8c56d827-5f07-45ce-8f2b-6c5001db5c6f')
$resourceGroups=@('apm-azure-app-services', 'apm-aas-junkyard')
$extensions=@('Datadog.AzureAppServices.DotNet', 'DevelopmentVerification.DdDotNet.Apm')

if ($Recycle -or $FullStopStart) {
	Foreach($sub in @($subscriptions)) {
	
		Foreach($group in @($resourceGroups)) {
			
			$allSites=az webapp list -g $group | ConvertFrom-Json

			Foreach($webapp in @($allSites)) {
				
				$SiteName=$webapp.name
				$siteApiUrl="https://management.azure.com/subscriptions/${SubscriptionId}/resourceGroups/${group}/providers/Microsoft.Web/sites/${SiteName}"
				
				if ($Recycle) {
					Write-Host "[${SiteName}] Requesting recycle."
					az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/restart?api-version=2019-08-01"
				}
				
				if ($FullStopStart) {
					Write-Host "[${SiteName}] Requesting stop."
					az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/stop?api-version=2019-08-01"
					Write-Host "[${SiteName}] Requesting start."
					az rest -m POST --header "Accept=application/json" -u "${siteApiUrl}/start?api-version=2019-08-01"
				}
			}
			
		}
	}
}
					
if ($UpdateExtension) {
	Foreach($sub in @($subscriptions)) {
		Foreach($group in @($resourceGroups)) {
			Foreach($ext in @($extensions)) {
				.\extension\update-all-site-extensions.ps1 -SubscriptionId $sub -ResourceGroup $group -Extension $ext
			}
		}
	}
}
