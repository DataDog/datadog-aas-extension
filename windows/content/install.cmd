REM Entrypoint: https://github.com/projectkudu/kudu/blob/13824205c60a4bdb53896b9553ef1f370a93b911/Kudu.Core/SiteExtensions/SiteExtensionManager.cs#L548

@echo off

set version=vUNKNOWN
set tracer_path=\home\SiteExtensions\DevelopmentVerification.DdWindows.Apm\vFOLDERUNKNOWN\Tracer
set log_prefix=%date% %time% ^[%version%^]
set log_file=..\..\Datadog.AzureAppServices.Install.txt

echo %log_prefix% Starting install. >> %log_file%

mkdir %tracer_path%

IF DEFINED WEBSITE_NODE_DEFAULT_VERSION (
  echo %log_prefix% Downloading Node tracer >> %log_file%
  npm install --prefix %tracer_path% dd-trace >> "%log_file%"
) ELSE (
  IF "%WEBSITE_STACK%" == "JAVA" (
    echo %log_prefix% Downloading Java tracer >> %log_file%
    curl -L -o %tracer_path%\dd-java-agent.jar https://github.com/DataDog/dd-trace-java/releases/latest/download/dd-java-agent.jar
  ) ELSE (
      echo %log_prefix% Runtime not supported >> %log_file%
      exit /B 0
  )
)

echo %log_prefix% Successfully installed. >> %log_file%
exit /B 0
