
REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

echo %date%%time% - Starting install. >> ..\..\Datadog.AzureAppServices.DotNet-Install.txt

IF EXIST ..\Datadog.AzureAppServices\applicationHost.xdt (
  echo %date%%time% - Datadog.AzureAppServices.DotNet can not be installed side by side with Datadog.AzureAppServices. >> ..\..\Datadog.AzureAppServices.DotNet-Install.txt
  exit /B 2
)

IF EXIST .\applicationHost.xdt (
  echo %date%%time% - Upgrade will not apply until full application stop. >> ..\..\Datadog.AzureAppServices.DotNet-Install.txt
)

POWERSHELL .\install.ps1

IF NOT EXIST .\applicationHost.xdt (
  echo %date%%time% - Install failure, make sure your instance is stopped before install. >> ..\..\Datadog.AzureAppServices.DotNet-Install.txt
  exit /B 1
)

echo %date%%time% - Successfully installed. >> ..\..\Datadog.AzureAppServices.DotNet-Install.txt
exit /B 0
