
REM Set these version variables and run the script to change all the files which need version updates
set major=0
set minor=2
set patch=0
set version_postfix=-prerelease
set tracer_version=1.13.0
REM All of the below code changes the actual files, no touch!

set version_regex=[0-9]+\.[0-9]+\.[0-9]+[\-a-zA-Z]*
set gitlab_yml=.gitlab-ci.yml
powershell -Command "(gc .\%gitlab_yml%) -replace '%version_regex%.+windows-tracer-home.zip', '%tracer_version%/windows-tracer-home.zip' | Out-File -encoding ASCII .\%gitlab_yml%"

set nuget_replacement=%major%.%minor%.%patch%%version_postfix%

set nuget_files=Datadog.Development.AzureAppServices.nuspec Datadog.AzureAppServices.nuspec

(for %%f in (%nuget_files%) do (
	powershell -Command "(gc .\%%f) -replace '%version_regex%', '%nuget_replacement%' | Out-File -encoding ASCII .\%%f"
   echo/
)) > set-versions-log.txt

set path_regex=[0-9]+_[0-9]+_[0-9]+
set path_replacement=%major%_%minor%_%patch%

set path_files=content\applicationHost.xdt content\install.cmd

(for %%f in (%path_files%) do (
	powershell -Command "(gc .\%%f) -replace '%path_regex%', '%path_replacement%' | Out-File -encoding ASCII .\%%f"
   echo/
)) > set-versions-log.txt
