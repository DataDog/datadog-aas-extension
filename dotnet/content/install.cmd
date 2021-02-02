
REM Entrypoint: https://github.com/projectkudu/kudu/blob/master/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

echo Starting install

IF EXIST .\applicationHost.xdt (
  echo Upgrade will not apply until full application stop
)

POWERSHELL .\install.ps1

IF NOT EXIST .\applicationHost.xdt (
  echo Install failure
  exit /B 1
)

echo Finished install
exit /B 0
