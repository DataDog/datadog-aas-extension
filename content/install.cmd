@echo off

echo Starting install

SET extensionBaseDir=%~dp0
SET siteHome=%HOME%
echo Extension directory is %extensionBaseDir%
echo Site root directory is %siteHome%

REM Create home directory for tracer version
SET tracerDir=%siteHome%\datadog\tracer\v0_1_4
if not exist %tracerDir% mkdir %tracerDir%

REM Copy tracer home directory to version specific directory
ROBOCOPY %extensionBaseDir%Tracer %tracerDir% /E /purge

REM Create directory for agent to live
SET agentDir=%tracerDir%\agent
if not exist %agentDir% mkdir %agentDir%

REM Copy all agent files
ROBOCOPY %extensionBaseDir%Agent %agentDir% /E /purge

echo Finished install
