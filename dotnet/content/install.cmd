
REM Entrypoint: https://github.com/projectkudu/kudu/blob/master/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off


IF EXIST ".\applicationHost.xdt" (
  echo Starting upgrade
  echo Upgrade will not apply until full application stop
)
ELSE 
(
  echo Starting upgrade
)

POWERSHELL .\install.ps1

IF EXIST ".\applicationHost.xdt" (
  echo Install failure
  exit /B 1
)

echo Completed install

exit /B 0
