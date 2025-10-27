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

$corEnableProfiling=[Environment]::GetEnvironmentVariable("APPSETTING_COR_ENABLE_PROFILING").ToLower()

if (-not ([string]::IsNullOrEmpty($corEnableProfiling)))
{
	Log("User set COR_ENABLE_PROFILING to ${corEnableProfiling} in app settings")
	if ($corEnableProfiling -eq "0" -or $corEnableProfiling -eq "false")
	{
		Log("User set COR_ENABLE_PROFILING to 0 or false in app settings. Don't insert COR_ENABLE_PROFILING=1 in applicationHost.xdt to disable .NET Framework Profiling.")
		$xdtPath=".\applicationHost.xdt"
		$xdtContent=Get-Content -Path $xdtPath -Raw
		# Match lines that have both name="COR_ENABLE_PROFILING" AND value= to target only the Insert
		$xdtContent=$xdtContent -replace '\s*<add name="COR_ENABLE_PROFILING" value="[^"]*"[^>]*/>[\r\n]*', ''
		Set-Content -Path $xdtPath -Value $xdtContent
		Log("COR_ENABLE_PROFILING Insert line removed from XDT")
	}
}

Log("Install complete")