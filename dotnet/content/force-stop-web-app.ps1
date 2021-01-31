# Force stop the web app to enable proper loading of asp.net module
# This also has the added benefit of immediate traces

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

  Write-Output "Stopping process ${w3wp_id}"
  
  # This is a non-scm instance, fire and forget stop the web app
  $null=Start-Process PowerShell.exe -ArgumentList "-NoLogo", "-NonInteractive", "-Command", "Stop-Process -Id ${w3wp_id}" -NoNewWindow
  
  # Now we need to watch until the process is actually stopped
  $stopped_webapp=$False
  $max_attempts=60 # 6 seconds
  
  
  Write-Output "Watching for process stop"
  
  while ($stopped_webapp -eq $False)
  {
	  Start-Sleep -Milliseconds 100
	  Write-Output "..."
	  
	  $w3wpProcesses=@(Get-Process w3wp)
	  
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
}

