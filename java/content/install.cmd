
REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=vUNKNOWN
set log_prefix=%date% %time% ^[%version%^]
set log_file=..\..\Datadog.AzureAppServices.Java-Install.txt

echo %log_prefix% Starting install. >> %log_file%

IF EXIST .\applicationHost.xdt (
  echo %log_prefix% Upgrade will not apply until full application stop. >> %log_file%
)

POWERSHELL .\install.ps1 -ExtensionVersion %version%

echo %log_prefix% Successfully installed. >> %log_file%
exit /B 0

