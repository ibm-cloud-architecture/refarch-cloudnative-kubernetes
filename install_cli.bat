@echo off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS 
set PATH=%PATH%;%CD%;%CD%\win_utils

:install_bx
echo BX CLI will be installed.
bx > nul 2>&1
if %errorlevel% EQU 0 goto :bx_installed
echo downloading the Bluemix CLI installer. After installing, you may be prompted to reboot. Re-run this script after the reboot.
curl -k -s https://clis.ng.bluemix.net/info | findstr latestVersion> %TMP%\bx_latest.tmp
for /f "tokens=2 delims=:," %%i in (%TMP%\bx_latest.tmp) do @set BX_VER=%%~i
echo curl -o http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_%BX_VER%_amd64.exe
curl -O http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_%BX_VER%_amd64.exe
move  Bluemix_CLI_%BX_VER%_amd64.exe win_utils\Bluemix_CLI_%BX_VER%_amd64.exe
start /wait win_utils\Bluemix_CLI_%BX_VER%_amd64.exe
:bx_installed
echo BX CLI is installed.

:install_bx_cs
echo BX CS plugin will be installed.
bx cs > nul 2>&1
if %errorlevel% EQU 0 goto :bx_cs_installed
bx plugin install container-service -r Bluemix
:bx_cs_installed
echo BX CS plugin is installed.

:install_br_cs
echo BX CR plugin will be installed...
bx cr > nul 2>&1
if %errorlevel% EQU 0 goto :bx_cr_installed
bx plugin install container-registry -r Bluemix
:bx_cr_installed
echo BX CR plugin is installed.

:install_kubectl
echo Kubernetes CLI (kubectl) will be installed
kubectl >nul 2>&1
if %errorlevel% EQU 0 goto :kubectl_installed
for /f %%i in ('curl -k -s https://storage.googleapis.com/kubernetes-release/release/stable.txt') do set KUBVER=%%i
curl -LOk https://storage.googleapis.com/kubernetes-release/release/%KUBVER%/bin/windows/amd64/kubectl.exe
move kubectl.exe win_utils\kubectl.exe
:kubectl_installed
echo Kubectl is installed

:install_helm
echo Installing helm
rem This is a placeholder. For the moment, we will manually download a version of helm
helm >nul 2>&1
if %errorlevel% EQU 0 goto :helm_installed
rem echo please download helm.exe from either :
rem echo   https://storage.googleapis.com/kubernetes-helm/helm-v2.5.0-windows-amd64.zip (official site, you'll need to unzip)
rem echo   https://ibm.box.com/s/m2iau50fdiblleoeafvd5svbd4uvmcdr  (unzipped instance)
rem echo and copy it to %CD%\win_utils
rem echo once you have done so
rem pause
rem goto :install_helm
curl -LJOk https://github.com/ibm-cloud-architecture/ibmcase-cloudnative-utility/raw/master/helm.exe
move helm.exe win_utils\helm.exe
:helm_installed
echo Helm installed.

:install_jq
echo Installing jq...
jq -help >nul 2>&1
if %errorlevel% EQU 0 goto :jq_installed
curl -LOk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-win64.exe
move jq-win64.exe win_utils\jq.exe
:jq_installed
echo jq is installed

:install_yaml
echo Installing yaml...
yaml >nul 2>&1
if %errorlevel% EQU 0 goto :yaml_installed
curl -LOk https://github.com/mikefarah/yaml/releases/download/1.11/yaml_windows_amd64.exe
move yaml_windows_amd64.exe win_utils\yaml.exe
:yaml_installed
echo yaml is installed
