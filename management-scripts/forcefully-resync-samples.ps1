
$reliabilityApps=@('dd-aas-net48-appinsight', 'dd-aas-net48-appinsight-x64', '
dd-aas-net48-baseline', 'dd-aas-net48-development', 'dd-aas-net48-development-x64', 'dd-aas-net48-latest', 'dd-aas-net5-baseline', 'dd-aas-net5-development', 'dd-aas-netcore21-baseline', 'dd-aas-netcore21-development', 'dd-aas-netcore31-appinsight', 'dd-aas-netcore31-baseline', 'dd-aas-netcore31-development', 'dd-aas-netcore31-development-x64', 'dd-aas-netcore31-latest', 'dd-aas-netcore31-oop')

$subscriptionId="8c56d827-5f07-45ce-8f2b-6c5001db5c6f"
$resourceGroupName="apm-azure-app-services"

Foreach($SiteName in @($reliabilityApps)) {

  .\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName -Remove
  .\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName -Extension "DevelopmentVerification.DdDotNet.Apm" -Remove
  
  if ($SiteName.Contains('baseline')) {
	  # Do nothing
	  Write-Host "[${SiteName}] Baseline app should have no extension."
  }
  elseif ($SiteName.Contains('dev')) {
	  Write-Host "[${SiteName}] Installing latest development version."
    .\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName -Extension "DevelopmentVerification.DdDotNet.Apm"
  }
  else {
	  Write-Host "[${SiteName}] Installing latest release."
	.\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName
  }

}

$resourceGroupName="apm-aas-junkyard"
$junkyardApps=@('dd-netcore31-junkyard', 'dd-netcore31-junkyard-baseline', 'dd-netcore31-junkyard-dev', 'dd-netcore31-junkyard-dev-clone', 'dd-netcore31-junkyard-parallel-baseline', 'dd-netcore31-junkyard-parallel-development')

Foreach($SiteName in @($reliabilityApps)) {

  .\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName -Remove
  .\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName -Extension "DevelopmentVerification.DdDotNet.Apm" -Remove
  
  if ($SiteName.Contains('baseline')) {
	  # Do nothing
  }
  else {
    .\extension\install-latest-extension.ps1 -SubscriptionId $subscriptionId -ResourceGroup $resourceGroupName -SiteName $SiteName -Extension "DevelopmentVerification.DdDotNet.Apm"
  }
}

