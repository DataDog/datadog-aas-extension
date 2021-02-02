REM Set these version variables and run the script to change all the files which need version updates

REM The site extension release version
set major=1
set minor=0
set patch=0
set version_postfix=

REM Specialized version for development package, increment as necessary for testing
set development_minor=1
set development_patch=8

REM The agent version to deploy
set agent_version=7.25.0

REM The dotnet tracer version to deploy
set tracer_version=1.22.2-prerelease

REM **************************************************************************************************************************
REM All of the below code updates versions in files, do not touch unless you wish to modify the structure of those files
REM **************************************************************************************************************************

set release_path_regex=v[1-9][0-9]?_[0-9]+_[0-9]+
set release_path_replacement=v%major%_%minor%_%patch%
set development_release_path_regex=v0_[0-9][0-9]?[0-9]?_[0-9][0-9]?[0-9]?
set development_release_path_replacement=v0_%development_minor%_%development_patch%

set gitlab_yml=.gitlab-ci.yml
powershell -Command "(gc .\%gitlab_yml%) -replace '%development_release_path_regex%', '%development_release_path_replacement%' | Out-File -encoding ASCII .\%gitlab_yml%"
powershell -Command "(gc .\%gitlab_yml%) -replace '%release_path_regex%', '%release_path_replacement%' | Out-File -encoding ASCII .\%gitlab_yml%"

set version_regex=[1-9]+\.[0-9]+\.[0-9]+[\-a-zA-Z]*
set dev_version_regex=0\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?
powershell -Command "(gc .\%gitlab_yml%) -replace '%version_regex%.+windows-tracer-home.zip', '%tracer_version%/windows-tracer-home.zip' | Out-File -encoding ASCII .\%gitlab_yml%"
powershell -Command "(gc .\%gitlab_yml%) -replace 'agent-binaries-%version_regex%-1-x86_64.zip', 'agent-binaries-%agent_version%-1-x86_64.zip' | Out-File -encoding ASCII .\%gitlab_yml%"

set release_nuget=dotnet\Datadog.AzureAppServices.DotNet.nuspec
set release_version=%major%.%minor%.%patch%%version_postfix%
powershell -Command "(gc .\%release_nuget%) -replace '%version_regex%', '%release_version%' | Out-File -encoding ASCII .\%release_nuget%"

set dev_nuget=dotnet\DevelopmentVerification.DdDotNet.Apm.nuspec
set development_package_version=0.%development_minor%.%development_patch%%version_postfix%
powershell -Command "(gc .\%dev_nuget%) -replace '%dev_version_regex%', '%development_package_version%' | Out-File -encoding ASCII .\%dev_nuget%"

set application_host_transform=dotnet\content\applicationHost.xdt

set ext_version_replace='DD_AAS_DOTNET_EXTENSION_VERSION"" value=\"%release_version%\" xdt:Locator'
set ext_version_regex=DD_AAS_DOTNET_EXTENSION_VERSION. value..[0-9][0-9]?[0-9]?.[0-9][0-9]?[0-9]?.[0-9][0-9]?[0-9]?. xdt.Locator

powershell -Command "(gc .\%application_host_transform%) -replace '%ext_version_regex%', %ext_version_replace% | Out-File -encoding ASCII .\%application_host_transform%"

set path_files=%application_host_transform% dotnet\content\install.cmd dotnet\content\Agent\datadog.yaml dotnet\content\Agent\dogstatsd.yaml

for %%f in (%path_files%) do (
	powershell -Command "(gc .\%%f) -replace '%release_path_regex%', '%release_path_replacement%' | Out-File -encoding ASCII .\%%f"
)