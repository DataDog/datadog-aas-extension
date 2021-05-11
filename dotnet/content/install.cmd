
REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=v1.3.3
set log_prefix=%date% %time% ^[%version%^]
set log_file=..\..\Datadog.AzureAppServices.DotNet-Install.txt

echo %log_prefix% Starting install. >> %log_file%

IF EXIST ..\Datadog.AzureAppServices\applicationHost.xdt (
  echo %log_prefix% Datadog.AzureAppServices.DotNet can not be installed side by side with Datadog.AzureAppServices. >> %log_file%
  exit /B 2
)

IF EXIST .\applicationHost.xdt (
  echo %log_prefix% Upgrade will not apply until full application stop. >> %log_file%
)

POWERSHELL .\install.ps1

IF NOT EXIST .\applicationHost.xdt (
  echo %log_prefix% Install failure, make sure your instance is stopped before install. >> %log_file%
  exit /B 1
)

echo %log_prefix% Successfully installed. >> %log_file%
exit /B 0
