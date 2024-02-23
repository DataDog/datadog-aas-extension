@echo off
REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

set "log_directory_path=\home\LogFiles\datadog"

if not exist "%log_directory_path%" (
    mkdir "%log_directory_path%"
)

set "log_file=%log_directory_path%\Datadog.AzureAppServices.Node.Apm-Install.txt"

POWERSHELL .\install.ps1 >> %log_file%

exit /B 0
