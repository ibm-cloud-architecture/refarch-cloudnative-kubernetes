@echo off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS 
set PATH=%PATH%;%CD%;%CD%\win_utils


set URL=%1
set PASS=%2

if "%URL%" == "" (
   echo Please provide Grafana URL. Exiting...
   exit /b 1
)

if "%PASS%" == "" (
   echo Please provide Grafana Admin password. Exiting...
   exit /b 1
)

for /f %%i in ('dir /b %CD%\docs\dashboards\*.json') do @curl -s -u admin:%PASS% -H "Content-Type: application/json" -X POST %URL%/api/dashboards/db -d@docs\dashboards\%%i 