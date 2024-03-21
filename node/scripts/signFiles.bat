REM first copy eveything into the container
mkdir c:\build
cd c:\build
xcopy /y/e/s c:\mnt\*.* .

REM sign the files
dd-wcs sign node\AgentProcessManager\x64\Release\AgentProcessManager.dll
dd-wcs sign node\AgentProcessManager\Release\AgentProcessManager.dll
dd-wcs sign node\process_manager\target\x86_64-pc-windows-gnu\release\process_manager.exe

REM copy the signed files back out so they're in the artifacts
copy node\AgentProcessManager\x64\Release\AgentProcessManager.dll c:\mnt\node\AgentProcessManager\x64\Release\AgentProcessManager.dll
copy node\AgentProcessManager\Release\AgentProcessManager.dll c:\mnt\node\AgentProcessManager\Release\AgentProcessManager.dll
copy node\process_manager\target\x86_64-pc-windows-gnu\release\process_manager.exe c:\mnt\node\process_manager\target\x86_64-pc-windows-gnu\release\process_manager.exe
