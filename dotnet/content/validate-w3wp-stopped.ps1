$ProgressPreference = "SilentlyContinue"

# Use applicationHost.xdt as an indicator of success or upgrade, as this is the ultimate entry point to instrumentation
if ([System.IO.File]::Exists('.\applicationHost.xdt')) 
{
  # The extension has successfully installed previously, and the full upgrade will take place after process stop
  Write-Output "Upgrade successful. Changes will take effect after the next application stop."
  
  # Allow the transform to apply if it exists
  if ([System.IO.File]::Exists('.\applicationHost.xdt.dd')) 
  {
    Move-Item -Path '.\applicationHost.xdt.dd' -Destination '.\applicationHost.xdt' -Force
  }
  else 
  {
    Write-Output "There is no applicationHost.xdt.dd to override the applicationHost.xdt."
  }
  
  return
}

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
  
  Set-Content -Path '.\installation-failure.txt' -Value 'true'
  Set-Content -Path '..\..\datadog-installation-failure.txt' -Value 'Web application must be STOPPED before installing Datadog.'
  
  # Return to prevent success file from being created
  return
  
}

# If we are here, then the extension has successfully installed.
# Allow the transform to apply
Move-Item -Path '.\applicationHost.xdt.dd' -Destination '.\applicationHost.xdt' -Force
