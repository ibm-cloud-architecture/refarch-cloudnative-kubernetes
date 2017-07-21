@echo off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set PATH=%PATH%;%CD%;%CD%\win_utils
for %%A in ("%~dp0\..") do set "PARENT_FOLDER=%%~fA"

:setenvironment
set git_org="ibm-cloud-architecture"
set base_url="https://github.com/ibm-cloud-architecture"
set repo_list=refarch-cloudnative-bluecompute-web ^
refarch-cloudnative-auth ^
refarch-cloudnative-micro-inventory ^
refarch-cloudnative-micro-orders ^
refarch-cloudnative-micro-customer ^
refarch-cloudnative-devops-kubernetes ^
refarch-cloudnative-resiliency ^
refarch-cloudnative-kubernetes-csmo


for %%r in (%repo_list%) do (
   echo parent folder %PARENT_FOLDER%
   set repo_url=%base_url%/%%r
   echo cloning repository !repo_url!
   git clone !repo_url! %PARENT_FOLDER%\%%r
   cd %PARENT_FOLDER%\%%r
   git checkout kube-int
   cd %PARENT_FOLDER%
)

echo All github repository have cloned successfully!
