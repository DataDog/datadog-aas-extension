
# https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Services/SiteExtensions/SiteExtensionController.cs#L240

# Set the unique pipe names in the applicationHost.xdt file for traces and metrics
if ([System.IO.File]::Exists('.\applicationHost.xdt.dd')) 
{
  $tracePipeId=([guid]::NewGuid().ToString().ToUpper())
  $statsPipeId=([guid]::NewGuid().ToString().ToUpper())
  ((Get-Content -path .\applicationHost.xdt.dd -Raw) -replace "uniqueTracePipeId", "${tracePipeId}") | Set-Content -Path .\applicationHost.xdt.dd
  ((Get-Content -path .\applicationHost.xdt.dd -Raw) -replace "uniqueStatsPipeId", "${statsPipeId}") | Set-Content -Path .\applicationHost.xdt.dd
}

# If a web application is running, do not create the applicationHost.xdt file
# This is used as an indication of install failure
# Upgrades should replace the applicationHost.xdt regardless of running processes
# It is important that we do not apply the applicationHost.xdt for the first time with active web applications
# If we apply the transform before the profiler is loaded, a recycle will attempt to load the ASP.NET module and fail
.\validate-w3wp-stopped.ps1 > validate-w3wp-stopped.txt
