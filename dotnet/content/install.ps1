
# Set the unique pipe names in the applicationHost.xdt file for traces and metrics
$tracePipeId=([guid]::NewGuid().ToString().ToUpper())
$statsPipeId=([guid]::NewGuid().ToString().ToUpper())
((Get-Content -path .\applicationHost.xdt -Raw) -replace "uniqueTracePipeId", "${tracePipeId}") | Set-Content -Path .\applicationHost.xdt
((Get-Content -path .\applicationHost.xdt -Raw) -replace "uniqueStatsPipeId", "${statsPipeId}") | Set-Content -Path .\applicationHost.xdt


# Force stop the web app to enable proper loading of asp.net module
# This also has the added benefit of immediate traces

# Prevent the progress meter from trying to access the console mode
$ProgressPreference = "SilentlyContinue"

$w3wpProcesses=@(Get-Process w3wp)

foreach ($w3wp in @($w3wpProcesses)) 
{	
  $w3wp_id=$w3wp.Id
  # The variables match exactly, so we need to examine loaded modules
  $w3wp_modules=$w3wp.Modules
  
  Write-Output "Examining ${w3wp_id} as shutdown candidate"

  $wellknown_scm_module_count=0;
  $minimum_scm_module_count=5;
  
  foreach ($loaded_module in $w3wp_modules) 
  {	
    $module_name=$loaded_module.ModuleName
    if ($module_name.EndsWith(".ni.dll") -eq $False) 
	{
	  continue;
	}
	
    if ($module_name.StartsWith("Microsoft.Build.Tasks")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("SMDiagnostics")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("System.Runtime.DurableInstancing")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("System.Activities.DurableInstancing")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("System.ServiceProcess")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("System.Deployment")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("Microsoft.VisualBasic.Activities.Compiler")) 
	{
	  $wellknown_scm_module_count++
	}
    elseif ($module_name.StartsWith("System.Runtime.Caching")) 
	{
	  $wellknown_scm_module_count++
	}
  }
  
  if ($wellknown_scm_module_count -gt $minimum_scm_module_count)
  {
    Write-Output "Skipping ${w3wp_id} with ${wellknown_scm_module_count} scm modules"
	continue;
  }

  Write-Output "Stopping process ${w3wp_id}"
  
  # This is a non-scm instance, fire and forget stop the web app
  $null = Start-Process PowerShell.exe -ArgumentList "-NoLogo", "-NonInteractive", "-Command", "Stop-Process -Id ${w3wp_id}" -NoNewWindow
  
  # Now we need to watch until the process is actually stopped
  $stopped_webapp=$False
  $max_attempts=60 # 6 seconds
  
  while ($stopped_webapp)
  {
	  Start-Sleep 100
	  
	  $new_w3wps=@(Get-Process w3wp)
	  
	  $stopped_webapp=$True
	  
	  foreach ($current_w3wp in @($new_w3wps))
	  {
		  if ($current_w3wp.Id -eq $w3wp_id) 
		  {
			  $stopped_webapp=$False
			  break;
		  }
	  }
	  
	  if ($stopped_webapp)
	  {
		  Write-Output "Verified stop of ${w3wp_id}"
		  break;
	  }
	  
	  $max_attempts--
	  
	  if ($max_attempts -eq 0) {
		  Write-Output "Unable to verify stop of ${w3wp_id}"
		  break;
	  }
  }
  
  Start-Sleep 1 # Necessary for script to close out normally
  
}

