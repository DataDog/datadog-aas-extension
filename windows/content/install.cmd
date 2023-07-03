REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=vUNKNOWN
set log_prefix=%date% %time% ^[%version%^]
set log_file=..\..\Datadog.AzureAppServices.Windows-Install.txt

echo %log_prefix% Starting install. >> %log_file%

@REM we can remove this right?
IF EXIST .\applicationHost.xdt (
  echo %log_prefix% Upgrade will not apply until full application stop. >> %log_file%
)

REM node tracer download logic, make this detect runtime later
echo %log_prefix% Downloading Node tracer >> %log_file%
npm install --prefix \home\SiteExtensions\content\Tracer dd-trace >> %log_file%

echo %log_prefix% Successfully installed. >> %log_file%
exit /B 0