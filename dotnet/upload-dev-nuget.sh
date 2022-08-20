dev_version="$1"
AZDO_PAT=$2

dotnet nuget add source https://pkgs.dev.azure.com/datadoghq/dd-trace-dotnet/_packaging/Public_Feed/nuget/v3/index.json --name Public_Feed --username any_string --password $AZDO_PAT --store-password-in-clear-text
dotnet nuget push package/DevelopmentVerification.DdDotNet.Apm.$dev_version.nupkg --source Public_Feed --api-key any_string