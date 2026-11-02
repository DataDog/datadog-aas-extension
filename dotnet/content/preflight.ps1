# Install-time check to decide how to apply applicationHost.xdt config. Called by install.ps1.
#
# install.ps1 runs once, in Kudu, on the instance, when the extension is installed or updated.
# If the instance can load our custom transform DLL against Azure's Microsoft.Web.XmlTransform
# and our custom transform DLL produces the expected variables, we use that. If anything fails,
# we use the standard .xdt transform instead.
#
# Expects, next to install.ps1, with the pipe GUIDs and the .NET Core edit already applied:
#   applicationHost.xdt          the standard RemoveAll + Insert file
#   applicationHost.custom.xdt   the one-step custom transform file
# Keeps the standard file as applicationHost.standard.xdt, then writes the chosen file to
# applicationHost.xdt. The last output line is "custom" or "standard".
#
# -EnginePath is for local tests only. On App Service the engine is loaded from the GAC by name.
param(
    [string] $ExtensionPath = $PSScriptRoot,
    [string] $EnginePath = ""
)

function Log ([string] $text) { Write-Output "[preflight] $text" }

# A minimal main-site config in the shape the platform hands to the config step.
$samples = @(
    '<configuration><system.webServer><runtime><environmentVariables><add name="OTHER" value="1" /><add name="DD_TRACE_PIPE_NAME" value="old" /></environmentVariables></runtime></system.webServer></configuration>'
)

function Apply-Xdt ([string] $config, [string] $xdtText) {
    $doc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
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
$standard = Join-Path $ExtensionPath "applicationHost.standard.xdt"
$target = Join-Path $ExtensionPath "applicationHost.xdt"
$choice = "standard"
if ((Get-Content $target -Raw) -notmatch 'xdt:Transform="SetEnvironmentVariables"') {
    Copy-Item $target $standard -Force
} elseif (-not (Test-Path $standard)) {
    Log("applicationHost.xdt is already the one-step file; leaving it")
    return "custom"
}
try {
    if ($EnginePath) {
        [void][Reflection.Assembly]::LoadFrom($EnginePath)
    } else {
        # The same assembly identity the DLL is built against; the platform's config step binds to it from the GAC.
        [void][Reflection.Assembly]::Load("Microsoft.Web.XmlTransform, Version=1.4.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
    }

    # The platform expands %XDT_EXTENSIONPATH% in both files; do the same, so the dry run loads the
    # real DLL and the path values compare equal.
    $customText = (Get-Content $custom -Raw).Replace("%XDT_EXTENSIONPATH%", $ExtensionPath)
    $standardText = (Get-Content $standard -Raw).Replace("%XDT_EXTENSIONPATH%", $ExtensionPath)
    foreach ($sample in $samples) {
        $a = Apply-Xdt $sample $customText
        $b = Apply-Xdt $sample $standardText
        if ($a -ne $b) { throw "Differences across applicationHost.xdt and applicationHost.custom.xdt" }
    }
    $choice = "custom"
} catch {
    Log("Using standard applicationHost.xdt: $($_.Exception.Message)")
}

if ($choice -eq "custom") {
    Copy-Item $custom $target -Force
    Log("Using applicationHost.custom.xdt")
} else {
    Copy-Item $standard $target -Force
}
return $choice
