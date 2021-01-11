@echo off
echo Starting uninstall
SET extensionBaseDir=%~dp0
SET siteHome=%HOME%
REM Remove datadog home directory
SET installDir=%siteHome%\datadog
if exist %installDir% rmdir %installDir% /s /q
REM Intentionally leave logs directory
echo Finished uninstall
