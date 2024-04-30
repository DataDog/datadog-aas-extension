# https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Services/SiteExtensions/SiteExtensionController.cs#L240

$Version="vUNKNOWN"

function Log ([string] $text)
{
    $LogDate=Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Write-Output "${LogDate} [${Version}] $text"
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

# Determine the architecture (32-bit or 64-bit)
$architecture = if ([System.Environment]::Is64BitProcess) {
    "x64"
} else {
    "x86"
}

# Update the applicationHost.xdt file with the new DLL path
$configPath = ".\applicationHost.xdt"
$configContent = Get-Content -Path $configPath -Raw

# Replace the existing image attribute value with the new DLL path
$newConfigContent = $configContent -replace "ARCHITECTURE", "$architecture"

# Save the modified content back to the file
$newConfigContent | Set-Content -Path $configPath

# Set the unique pipe names in the applicationHost.xdt file for traces
$tracePipeId=([guid]::NewGuid().ToString().ToUpper())

SetPipe ".\applicationHost.xdt" "uniqueTracePipeId" "${tracePipeId}"

Log("Install complete")
