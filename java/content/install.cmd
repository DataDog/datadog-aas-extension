
REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548
mkdir ..\..\LogFiles\datadog
set log_file=..\..\LogFiles\datadog\java\vFOLDERUNKNOWN
POWERSHELL .\install.ps1 >> %log_file%
