@echo off

echo Starting install

SET extensionBaseDir=%~dp0
SET siteHome=%HOME%
echo Extension directory is %extensionBaseDir%
echo Site root directory is %siteHome%

REM Create home directory for tracer version
SET installDir=%siteHome%\datadog\v100_3_20
if not exist %installDir% mkdir %installDir%

REM Move tracer dlls and agent exes to version specific directory
move "%extensionBaseDir%Tracer" "%installDir%"
move "%extensionBaseDir%Agent" "%installDir%"

POWERSHELL .\install.ps1

echo Finished install
