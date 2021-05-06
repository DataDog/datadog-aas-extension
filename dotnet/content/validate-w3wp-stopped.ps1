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

# If we are here, then the extension has successfully installed.
# Allow the transform to apply
Move-Item -Path '.\applicationHost.xdt.dd' -Destination '.\applicationHost.xdt' -Force
