param (
    [Parameter(Mandatory=$true)][string]$ExtensionVersion
)

# https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Services/SiteExtensions/SiteExtensionController.cs#L240

# Set the unique pipe names in the applicationHost.xdt file for traces and metrics
$tracePipeId=([guid]::NewGuid().ToString().ToUpper())
$statsPipeId=([guid]::NewGuid().ToString().ToUpper())
((Get-Content -path .\applicationHost.xdt -Raw) -replace "uniqueTracePipeId", "${tracePipeId}") | Set-Content -Path .\applicationHost.xdt
((Get-Content -path .\applicationHost.xdt -Raw) -replace "uniqueStatsPipeId", "${statsPipeId}") | Set-Content -Path .\applicationHost.xdt

# Create log directory ahead of time
New-Item -ItemType Directory -Force -Path ${env:HOME}\LogFiles\datadog\java\vFOLDERUNKNOWN
