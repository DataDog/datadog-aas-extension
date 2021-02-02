
# Set the unique pipe names in the applicationHost.xdt file for traces and metrics
$tracePipeId=([guid]::NewGuid().ToString().ToUpper())
$statsPipeId=([guid]::NewGuid().ToString().ToUpper())
((Get-Content -path .\applicationHost.xdt -Raw) -replace "uniqueTracePipeId", "${tracePipeId}") | Set-Content -Path .\applicationHost.xdt
((Get-Content -path .\applicationHost.xdt -Raw) -replace "uniqueStatsPipeId", "${statsPipeId}") | Set-Content -Path .\applicationHost.xdt


#### Do not call this script unless we have a way to request iisreset or similar.
#### This does prevent applicationHost.xdt from being applied for any longer than it takes for the Stop-Process to happen
#### If we can gracefully shutdown w3wp.exe, then this is potentially useful.
#### Netfx applications need to STOP the web app before installing this extension.
## .\force-stop-web-app.ps1 > force-stop-web-app-log.

#### Errors in the install script do not prevent the install from completing
.\validate-w3wp-stopped.ps1 > validate-w3wp-stopped.txt
