
 param (
	[Parameter(Mandatory=$true)][string]$SubscriptionId,
	[Parameter(Mandatory=$true)][string]$StagingApiKey,
	[Parameter(Mandatory=$true)][string]$DotNetTestApiKey
 )

$ddSite="datadoghq.com"
$devExtension="DevelopmentVerification.DdDotNet.Apm"

$reliabilityApps=@('dd-aas-net48-appinsight', 'dd-aas-net48-appinsight-x64', '
dd-aas-net48-baseline', 'dd-aas-net48-development', 'dd-aas-net48-development-x64', 'dd-aas-net48-latest', 'dd-aas-net5-baseline', 'dd-aas-net5-development', 'dd-aas-netcore21-baseline', 'dd-aas-netcore21-development', 'dd-aas-netcore31-appinsight', 'dd-aas-netcore31-baseline', 'dd-aas-netcore31-development','dd-aas-netcore31-prerelease', 'dd-aas-netcore31-development-x64', 'dd-aas-netcore31-latest', 'dd-aas-netcore31-oop')

$bareboneGroup="apm-azure-app-services"

Foreach($SiteName in @($reliabilityApps)) {

	.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $bareboneGroup -SiteName $SiteName -Remove
	.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $bareboneGroup -SiteName $SiteName -Extension $devExtension -Remove

	az webapp config appsettings set -n ${SiteName} -g ${bareboneGroup} --settings DD_SITE=$ddSite DD_API_KEY=$StagingApiKey
	
	if ($SiteName.Contains('baseline')) {
		Write-Host "[${SiteName}] Baseline app should have no extension."
		continue;
	}
	elseif ($SiteName.Contains('dev')) {
		Write-Host "[${SiteName}] Installing latest master development version."
		az webapp config appsettings set -n ${SiteName} -g ${bareboneGroup} --settings DD_AAS_REMOTE_INSTALL="latest"
		.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $bareboneGroup -SiteName $SiteName -Extension $devExtension
	}
	elseif ($SiteName.Contains('prerelease')) {
		Write-Host "[${SiteName}] Installing development version."
		az webapp config appsettings delete -n ${SiteName} -g ${bareboneGroup} --setting-names DD_AAS_REMOTE_INSTALL
		.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $bareboneGroup -SiteName $SiteName -Extension $devExtension
	}
	else {
		Write-Host "[${SiteName}] Installing latest release."
		az webapp config appsettings delete -n ${SiteName} -g ${bareboneGroup} --setting-names DD_AAS_REMOTE_INSTALL
		.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $bareboneGroup -SiteName $SiteName
	}
}

$junkyardGroup="apm-aas-junkyard"
$junkyardApps=@('dd-netcore31-junkyard', 'dd-netcore31-junkyard-baseline', 'dd-netcore31-junkyard-dev', 'dd-netcore31-junkyard-dev-clone', 'dd-netcore31-junkyard-parallel-baseline', 'dd-netcore31-junkyard-parallel-development')

Foreach($SiteName in @($junkyardApps)) {

	.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $junkyardGroup -SiteName $SiteName -Remove
	.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $junkyardGroup -SiteName $SiteName -Extension $devExtension -Remove

	az webapp config appsettings set -n ${SiteName} -g ${junkyardGroup} --settings DD_SITE=$ddSite DD_AAS_REMOTE_INSTALL="latest" DD_API_KEY=$DotNetTestApiKey
	
	if ($SiteName.Contains('baseline')) {
		 Write-Host "[${SiteName}] Baseline app should have no extension."
		 continue;
	}
	else {
		.\extension\install-latest-extension.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $junkyardGroup -SiteName $SiteName -Extension $devExtension
	}
}

