
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
  Start-Process powershell -ArgumentList '-Id', '${w3wp_id}'
}
