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

if (Test-Path env:DD_AAS_REMOTE_INSTALL) {
    
    Log("Installing from remote source: $env:DD_AAS_REMOTE_INSTALL")

    # https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/77#issuecomment-601947496
    # Global is required because Expand-Archive module calls ignore the contextual $ProgressPreference
    $global:ProgressPreference = "SilentlyContinue"
    
    $underscoreVersion="vFOLDERUNKNOWN"
    $tracerHome="${PSScriptRoot}\${underscoreVersion}\Tracer"
    
    # View available artifacts: 
    #  https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/index.txt
    # View latest sha: 
    #  https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/sha.txt
    # Artifact download example:
    #  https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/16dd0fce121ca0fe9b20e650c05823496d603283/windows-tracer-home.zip
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $installOption=$env:DD_AAS_REMOTE_INSTALL
    
    if ($installOption -eq "latest") { 
        $installShaUrl="https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/sha.txt"
        $response=($null | Invoke-WebRequest -Uri $installShaUrl -Method "GET" -UseBasicParsing > $null)
        $response=(Invoke-WebRequest -Uri $installShaUrl -Method "GET" -UseBasicParsing)
        $installSha=$response.Content.Trim(" .-`t`n`r")
    }
    else {
        $installSha=$installOption
    }
    
    Log("Installing specific commit: ${installSha}")
    $latestHomeArtifactUrl="https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/${installSha}/windows-tracer-home.zip"
    
    Invoke-RestMethod -Uri $latestHomeArtifactUrl -Method "GET" -OutFile "tracer-home.zip"

    if (Test-Path -Path ".\tracer-home.zip") {
        Expand-Archive ".\tracer-home.zip" -DestinationPath ".\tracer-home\" -Force
    
        Remove-Item -Recurse -Force $tracerHome
        mkdir $tracerHome
        Get-ChildItem -Path ".\tracer-home\*" -Recurse | Move-Item -Destination "$tracerHome"
    
        Remove-Item -Recurse -Force ".\tracer-home"
        Remove-Item -Recurse ".\tracer-home.zip"
    
        $extensionVersionReplace="DD_AAS_DOTNET_EXTENSION_VERSION"" value=""${installSha}"""
    
        ((Get-Content -path .\applicationHost.xdt -Raw) -replace 'DD_AAS_DOTNET_EXTENSION_VERSION" value="[^"]+"', $extensionVersionReplace) | Set-Content -Path .\applicationHost.xdt
        
        Log("Replaced tracer: ${installSha}")
    }
    else {
        Log("Failed to download and replace tracer: ${installSha}")
    }
}

Log("Install complete")
