#!/usr/bin/env bash
# Local check of dotnet/content/preflight.ps1 under pwsh (macOS or Linux), with the 1.4.0 engine from
# the NuGet cache instead of the GAC. Run `dotnet build -c Release dotnet/xdt/src` first. The real
# check is a Windows App Service install; this only covers the script's decisions.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd -P)"
ENGINE="${ENGINE:-$HOME/.nuget/packages/microsoft.web.xdt/1.4.0/lib/net40/Microsoft.Web.XmlTransform.dll}"
DLL="$REPO/dotnet/xdt/src/bin/Release/net45/Datadog.AzureAppServices.DotNet.Xdt.dll"
setup() {
    local dir; dir="$(mktemp -d)"
    mkdir -p "$dir/vTEST"
    # Forward slashes in the import path, since this doesn't run on Windows.
    sed 's|<xdt:Import path="[^"]*"|<xdt:Import path="%XDT_EXTENSIONPATH%/vTEST/Datadog.AzureAppServices.DotNet.Xdt.dll"|' "$REPO/dotnet/content/applicationHost.custom.xdt" > "$dir/applicationHost.custom.xdt"
    cp "$REPO/dotnet/content/applicationHost.xdt" "$dir/applicationHost.xdt"
    cp "$DLL" "$dir/vTEST/"
    echo "$dir"
}
check() {  # check LABEL EXPECTED DIR
    local got used
    got="$(pwsh -NoProfile -File "$REPO/dotnet/content/preflight.ps1" -ExtensionPath "$3" -EnginePath "$ENGINE" | tail -1)"
    used="$(grep -c SetEnvironmentVariables "$3/applicationHost.xdt" || true)"
    if [[ "$got" == "$2" && ( ( "$2" == custom && "$used" -gt 0 ) || ( "$2" == standard && "$used" == 0 ) ) ]]; then
        echo "ok   $1 -> $got"
    else
        echo "FAIL $1: expected $2, got $got (one-step file in use: $used)"; exit 1
    fi
}
d=$(setup); check "everything in place" custom "$d"
check "run again on the same folder" custom "$d"
d=$(setup); rm "$d/vTEST/Datadog.AzureAppServices.DotNet.Xdt.dll"; check "DLL missing" standard "$d"
d=$(setup); printf 'not a dll' > "$d/vTEST/Datadog.AzureAppServices.DotNet.Xdt.dll"; check "DLL corrupt" standard "$d"
d=$(setup); sed -i.bak 's|<add name="DD_AZURE_APP_SERVICES" value="1" />|<add name="DD_AZURE_APP_SERVICES" value="0" />|' "$d/applicationHost.custom.xdt"; check "one-step file differs from standard" standard "$d"
d=$(setup); sed -i.bak 's|SetEnvironmentVariables|SetEnvironmentVariablez|' "$d/applicationHost.custom.xdt"; check "unknown transform name" standard "$d"
