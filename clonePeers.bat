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
refarch-cloudnative-kubernetes-csmo


for %%r in (%repo_list%) do (
   echo parent folder %PARENT_FOLDER%
   echo cloning repository %%r
   set repo_url=%base_url%/%%r
   git clone %repo_url% -b kube-int --single-branch %PARENT_FOLDER%\%%r
)

echo All github repository have cloned successfully!
