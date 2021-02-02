
# TODO: Figure out another path to prevent installation
# The applicationhost.xdt is applied before the install.cmd finishes
# So this does not prevent the module from getting loaded

# Prevent the progress meter from trying to access the console mode
$ProgressPreference = "SilentlyContinue"

Write-Output "Current PID: $PID"

$w3wpProcesses=@(Get-Process w3wp)

foreach ($w3wp in @($w3wpProcesses)) 
{	

  $w3wp_id=$w3wp.Id
  # The variables match exactly, so we need to examine loaded modules
  $w3wp_modules=$w3wp.Modules
  
  Write-Output "Examining ${w3wp_id} as shutdown candidate"
  
  Write-Output $w3wp

  $wellknown_scm_module_count=0;
  $minimum_scm_module_count=4;
  
  foreach ($loaded_module in $w3wp_modules) 
  {	
    $module_name=$loaded_module.ModuleName
    Write-Output $module_name

    if ($module_name.StartsWith("rasapi32.dll")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("rasman.dll")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("secur32.dll")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("schannel.dll")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("mskeyprotect.dll")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("ncryptsslp.dll")) 
	{
	  $wellknown_scm_module_count++
	}
  }
  
  if ($wellknown_scm_module_count -gt $minimum_scm_module_count)
  {
    Write-Output "Skipping ${w3wp_id} with ${wellknown_scm_module_count} scm modules"
	continue;
  }

  Write-Output "Failing install due to running web application."
  
  Remove-Item -Recurse -Force .\v1_0_0
  Remove-Item -Force .\applicationHost.xdt
  Remove-Item -Force .\DevelopmentVerification.DdDotNet.Apm.0.1.4-prerelease.nupkg
  Remove-Item -Force .\force-stop-web-app.ps1
  Remove-Item -Force .\scmApplicationHost.xdt
  Remove-Item -Force .\SiteExtensionSettings.json
  
  Set-Content -Path '.\\installation-failure.txt' -Value 'Web application must be STOPPED before installing this extension.'

  throw "Web application must be STOPPED before installing this extension."

}

