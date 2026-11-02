REM first copy eveything into the container
mkdir c:\build
cd c:\build
xcopy /y/e/s c:\mnt\*.* .

REM get AWS credentials for this job's CI Identity, used by windows-code-signer to sign with AWS KMS
C:\devtools\ci-identities-gitlab-job-client.exe assume-role || exit /b 1

REM sign the files
C:\devtools\windows-code-signer.exe sign node\AgentProcessManager\x64\Release\AgentProcessManager.dll || exit /b 1
C:\devtools\windows-code-signer.exe sign node\AgentProcessManager\Release\AgentProcessManager.dll || exit /b 1
C:\devtools\windows-code-signer.exe sign node\process_manager\target\x86_64-pc-windows-gnu\release\process_manager.exe || exit /b 1

REM copy the signed files back out so they're in the artifacts
copy node\AgentProcessManager\x64\Release\AgentProcessManager.dll c:\mnt\node\AgentProcessManager\x64\Release\AgentProcessManager.dll || exit /b 1
copy node\AgentProcessManager\Release\AgentProcessManager.dll c:\mnt\node\AgentProcessManager\Release\AgentProcessManager.dll || exit /b 1
copy node\process_manager\target\x86_64-pc-windows-gnu\release\process_manager.exe c:\mnt\node\process_manager\target\x86_64-pc-windows-gnu\release\process_manager.exe || exit /b 1
