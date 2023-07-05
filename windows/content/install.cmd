REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=vUNKNOWN
set log_prefix=%date% %time% ^[%version%^]
set log_file=..\..\Datadog.AzureAppServices.Install.txt

echo %log_prefix% Starting install. >> %log_file%

@REM we can remove this right?
IF EXIST .\applicationHost.xdt (
  echo %log_prefix% Upgrade will not apply until full application stop. >> %log_file%
)

mkdir \home\SiteExtensions\content\Tracer

IF "%WEBSITE_STACK%" == "NODE" (
  echo %log_prefix% Downloading Node tracer >> %log_file%
  npm install --prefix \home\SiteExtensions\content\Tracer dd-trace >> "%log_file%"
) ELSE (
  IF DEFINED WEBSITE_NODE_DEFAULT_VERSION (
    echo %log_prefix% Downloading Node tracer >> %log_file%
    npm install --prefix \home\SiteExtensions\content\Tracer dd-trace >> "%log_file%"
  )
)

IF "%WEBSITE_STACK%" == "JAVA" (
  echo %log_prefix% Downloading Java tracer >> %log_file%
  curl -L -o \home\SiteExtensions\content\Tracer\dd-java-agent.jar https://github.com/DataDog/dd-trace-java/releases/download/v0.104.0/dd-java-agent-0.104.0.jar
)

IF DEFINED DOTNET_CLI_TELEMETRY_PROFILE (
  echo %log_prefix% Downloading .NET tracer >> %log_file%
  curl -L -o \home\SiteExtensions\content\Tracer\tracer.zip https://github.com/DataDog/dd-trace-dotnet/releases/download/v2.32.0/windows-tracer-home.zip
  echo %log_prefix% Unzipping .NET tracer >> %log_file%
  POWERSHELL .\install_dotnet.ps1 >> %log_file%
)

echo %log_prefix% Successfully installed. >> %log_file%
exit /B 0
