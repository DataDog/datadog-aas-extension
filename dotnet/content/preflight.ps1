# Install-time check for the one-step applicationHost.xdt (SVLS-9057). Called by install.ps1.
#
# install.ps1 runs once, in Kudu, on the instance, when the extension is installed or updated. This
# checks that the instance can load the transform DLL against the platform's Microsoft.Web.XmlTransform
# and that it produces the same variables as the classic file. If anything fails, it installs the
# classic RemoveAll + Insert file instead. The worker-start config step then never sees a file this
# instance can't run.
#
# Expects, next to install.ps1, with the pipe GUIDs and the .NET Core edit already applied:
#   applicationHost.xdt          the classic RemoveAll + Insert file, as the package installs it
#   applicationHost.custom.xdt   the one-step file
# Keeps the classic file as applicationHost.classic.xdt, then writes the chosen file to
# applicationHost.xdt. The last output line is "custom" or "classic".
#
# -EnginePath is for local tests only. On App Service the engine is loaded from the GAC by name.
param(
    [string] $ExtensionPath = $PSScriptRoot,
    [string] $VersionFolder = "vFOLDERUNKNOWN",
    [string] $EnginePath = ""
)

function Log ([string] $text) { Write-Output "[preflight] $text" }

# A minimal main-site config in the shapes the platform hands to the config step.
$samples = @(
    '<configuration><system.webServer></system.webServer></configuration>',
    '<configuration><system.webServer><runtime><environmentVariables /></runtime></system.webServer></configuration>',
    '<configuration><system.webServer><runtime><environmentVariables><add name="OTHER" value="1" /><add name="DD_TRACE_PIPE_NAME" value="old" /></environmentVariables></runtime></system.webServer></configuration>'
)

function Apply-Xdt ([string] $config, [string] $xdtText) {
    $doc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
    $doc.PreserveWhitespace = $true
    $doc.LoadXml($config)
    $transform = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdtText, $false, $null)
    try {
        if (-not $transform.Apply($doc)) { throw "the engine reported a failure" }
    } finally {
        $transform.Dispose()
    }
    $vars = @($doc.SelectNodes("/configuration/system.webServer/runtime/environmentVariables/add") |
        ForEach-Object { $_.GetAttribute("name") + "=" + $_.GetAttribute("value") } | Sort-Object)
    return ($vars -join "`n")
}

$custom = Join-Path $ExtensionPath "applicationHost.custom.xdt"
$classic = Join-Path $ExtensionPath "applicationHost.classic.xdt"
$target = Join-Path $ExtensionPath "applicationHost.xdt"
$choice = "classic"
if ((Get-Content $target -Raw) -notmatch 'xdt:Transform="SetEnvironmentVariables"') {
    Copy-Item $target $classic -Force
} elseif (-not (Test-Path $classic)) {
    Log("applicationHost.xdt is already the one-step file and there is no classic copy; leaving it")
    return "custom"
}
try {
    if ($EnginePath) {
        [void][Reflection.Assembly]::LoadFrom($EnginePath)
    } else {
        # The same assembly identity the DLL is built against; the platform's config step binds to it from the GAC.
        [void][Reflection.Assembly]::Load("Microsoft.Web.XmlTransform, Version=1.4.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
    }

    $dll = Join-Path (Join-Path $ExtensionPath $VersionFolder) "Datadog.AzureAppServices.DotNet.Xdt.dll"
    if (-not (Test-Path $dll)) { throw "missing $dll" }

    # The platform expands %XDT_EXTENSIONPATH% in both files; do the same, so the dry run loads the
    # real DLL and the path values compare equal.
    $customText = (Get-Content $custom -Raw).Replace("%XDT_EXTENSIONPATH%", $ExtensionPath)
    $classicText = (Get-Content $classic -Raw).Replace("%XDT_EXTENSIONPATH%", $ExtensionPath)
    foreach ($sample in $samples) {
        $a = Apply-Xdt $sample $customText
        $b = Apply-Xdt $sample $classicText
        if ($a -ne $b) { throw "the one-operation file gave different variables than the classic file" }
        if (-not $a.Contains("DD_AZURE_APP_SERVICES=1")) { throw "the one-operation file didn't set DD_AZURE_APP_SERVICES" }
    }
    $choice = "custom"
} catch {
    Log("Using the classic applicationHost.xdt: $($_.Exception.Message)")
}

if ($choice -eq "custom") {
    Copy-Item $custom $target -Force
    Log("Using the one-operation applicationHost.xdt")
} else {
    Copy-Item $classic $target -Force
}
return $choice
