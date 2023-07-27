REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=vUNKNOWN
set tracer_path=\home\SiteExtensions\DevelopmentVerification.DdWindows.Apm\vFOLDERUNKNOWN\Tracer
set log_prefix=%date% %time% ^[%version%^]

mkdir ..\..\LogFiles\datadog
set log_file=..\..\LogFiles\datadog\Datadog.AzureAppServices.Windows-Install.txt

echo %log_prefix% Starting install. >> %log_file%

POWERSHELL .\install.ps1 >> %log_file%

mkdir %tracer_path%

IF DEFINED WEBSITE_NODE_DEFAULT_VERSION (
  echo %log_prefix% Downloading Node tracer >> %log_file%
  npm install --prefix %tracer_path% dd-trace >> %log_file%
) ELSE (
  IF "%WEBSITE_STACK%" == "JAVA" (
    echo %log_prefix% Downloading Java tracer >> %log_file%
    curl -L -o %tracer_path%\dd-java-agent.jar https://github.com/DataDog/dd-trace-java/releases/latest/download/dd-java-agent.jar
    mkdir \home\LogFiles\datadog\java\vFOLDERUNKNOWN
  ) ELSE (
      echo %log_prefix% Downloading .NET tracer >> %log_file%
      curl -L -o %tracer_path%\tracer.zip https://github.com/DataDog/dd-trace-dotnet/releases/latest/download/windows-tracer-home.zip
      echo %log_prefix% Unzipping .NET tracer >> %log_file%
      unzip %tracer_path%\tracer.zip -d %tracer_path%
      rm %tracer_path%\tracer.zip
  )
)

echo %log_prefix% Successfully installed. >> %log_file%
exit /B 0
