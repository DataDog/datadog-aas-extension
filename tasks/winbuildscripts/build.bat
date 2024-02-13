
REM first copy eveything into the container
mkdir c:\build
cd c:\build
xcopy /y/e/s c:\mnt\*.* .

REM find the visual studio tools
%VSTUDIO_ROOT%\Common7\tools\vsdevcmd.bat

REM do the builds
msbuild mnt\node\AgentProcessManager\AgentProcessManager.sln /p:Configuration=Release /p:Platform=x64
msbuild mnt\node\AgentProcessManager\AgentProcessManager.sln /p:Configuration=Release /p:Platform=x86

REM copy the results back out so they're in the artifacts

copy node\AgentProcessManager\x64\Release\AgentProcessManager.dll c:\mnt\node\AgentProcessManager\x64\Release\AgentProcessManager.dll
copy node\AgentProcessManager\Release\AgentProcessManager.dll c:\mnt\node\AgentProcessManager\Release\AgentProcessManager.dll
