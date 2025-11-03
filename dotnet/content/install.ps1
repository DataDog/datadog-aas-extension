# https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Services/SiteExtensions/SiteExtensionController.cs#L240

$Version="vUNKNOWN"

function Log ([string] $text)
{
    $LogDate=Get-Date -Format "yyyy-MM-dd HH:mm K"
    Write-Output "[(${Version}) ${LogDate}] $text"
}

Log("Beginning install")

function SetPipe ([string] $file, [string] $pipePattern, [string] $pipeGuid)
{ 
	if (Select-String -Path $file -Pattern $pipePattern -SimpleMatch -Quiet)
	{
		Log("Setting ${pipePattern} to ${pipeGuid} in ${file}")
		((Get-Content -path $file -Raw) -replace $pipePattern, $pipeGuid) | Set-Content -Path $file
	}
	else
	{
		Log("${pipePattern} has already been set in ${file}")
	}
}

# Set the unique pipe names in the applicationHost.xdt file for traces and metrics
$tracePipeId=([guid]::NewGuid().ToString().ToUpper())
$statsPipeId=([guid]::NewGuid().ToString().ToUpper())

SetPipe ".\applicationHost.xdt" "uniqueStatsPipeId" "${statsPipeId}"
SetPipe ".\applicationHost.xdt" "uniqueTracePipeId" "${tracePipeId}"
SetPipe ".\scmApplicationHost.xdt" "uniqueStatsPipeId" "${statsPipeId}"
SetPipe ".\scmApplicationHost.xdt" "uniqueTracePipeId" "${tracePipeId}"

function DetectDotNetRuntime() {
	$webConfigPath=Join-Path -Path $env:HOME "site\wwwroot\web.config"

	if (-not (Test-Path $webConfigPath)) {
		Log("No web.config found in wwwroot.")
		return "Unknown"
	}

	try {
		$xmlContent = Get-Content -Path $webConfigPath
		$xmlDocument = [xml]$xmlContent

		# Look for AspNetCoreModule or AspNetCoreModuleV2
		$aspNetCoreHandlers = $xmlDocument.SelectNodes("//system.webServer/handlers/add[@modules='AspNetCoreModule' or @modules='AspNetCoreModuleV2']")
		if ($null -ne $aspNetCoreHandlers -and $aspNetCoreHandlers.Count -gt 0) {
			return "Core"
		}

		$aspNetCoreNode = $xmlDocument.SelectSingleNode("//system.webServer/aspNetCore")
		if ($null -ne $aspNetCoreNode) {
			return "Core"
		}

		return "Framework"
	} catch {
		Log("Error parsing web.config: $_")
		return "Unknown"
	}
}

$dotnetRuntime=DetectDotNetRuntime
Log("Detected .NET runtime: ${dotnetRuntime}")

if ($dotnetRuntime -eq "Core") {
	Log("Changing applicationHost.xdt to not set COR_ENABLE_PROFILING so that .NET Framework instrumentation is disabled by default in .NET Core applications.")
	$xdtPath=".\applicationHost.xdt"
	$xdtContent=Get-Content -Path $xdtPath -Raw
	$xdtContent=$xdtContent -replace '\s*<add name="COR_ENABLE_PROFILING"[^>]*xdt:Transform="Insert"\s*\/>', ''
	Set-Content -Path $xdtPath -Value $xdtContent
}

Log("Install complete")