@echo off

echo Starting install

POWERSHELL .\install.ps1

IF EXIST ".\installation-failure.txt" (
  echo Install failure
  exit /B 1
)

echo Finished install

exit /B 0
