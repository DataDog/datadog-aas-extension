
REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=vUNKNOWN
set log_prefix=%date% %time% ^[%version%^]

mkdir ..\..\LogFiles\datadog
set log_file=..\..\LogFiles\datadog\Datadog.AzureAppServices.Node.Apm-Install.txt

echo %log_prefix% Starting install >> %log_file%

POWERSHELL .\install.ps1 >> %log_file%

echo %log_prefix% Successfully installed >> %log_file%
exit /B 0
