@echo off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set PATH=%PATH%;%CD%;%CD%\win_utils

:setenvironment
set git_org="ibm-cloud-architecture"
set base_url="https://github.com/ibm-cloud-architecture"
set repo_list=refarch-cloudnative-bluecompute-mobile ^
refarch-cloudnative-bluecompute-web ^
refarch-cloudnative-bluecompute-bff-ios ^
refarch-cloudnative-auth ^
refarch-cloudnative-micro-inventory ^
refarch-cloudnative-micro-orders ^
refarch-cloudnative-micro-customer ^
refarch-cloudnative-devops ^
refarch-cloudnative-resiliency ^
refarch-cloudnative-csmo


for %%repo in (%repo_list%) do (
   echo cloning repository %%repo
   set repo_url=%base_url%/%%repo
   git clone %repo_url% -b kube-int --single-branch ../%%repo
)

echo All github repository have cloned successfully!
