@echo off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS 
set PATH=%PATH%;%CD%;%CD%\win_utils

set CLUSTER_NAME=%1
set BX_SPACE=%~2
set BX_API_KEY=%3
set BX_REGION=%4
set NAMESPACE=%5
set INSTALL_MON=%6
set BX_API_ENDPOINT="api.ng.bluemix.net"

if  "%BX_REGION%" == "" (
   set BX_API_ENDPOINT=api.ng.bluemix.net
   echo Using default endpoint !BX_API_ENDPOINT!
) else (
   set BX_API_ENDPOINT=api.!BX_REGION!.bluemix.net
   echo Using endpoint !BX_API_ENDPOINT!
)

if "%CLUSTER_NAME%" == "" (
   echo Please provide Cluster Name. Exiting...
   exit /b 1
)

if "%BX_SPACE%" == "" (
   echo Please provide Bluemix Space Name. Exiting...
   exit /b 1
)
if "%BX_API_KEY%" == "" (
   echo Please provide Bluemix API Key. Exiting...
   exit /b 1
)

if "%NAMESPACE%" == "" (
   set NAMESPACE="default"
)

echo Login into Bluemix
set BLUEMIX_API_KEY=%BX_API_KEY%
bx login -a %BX_API_ENDPOINT% -s "%BX_SPACE%"
if %errorlevel% NEQ 0 (
   echo Could not login to Bluemix
   exit /b 1
)
echo Login into Container Service
bx cs init

set KUBECONFIG=""
echo Setting terminal context to %CLUSTER_NAME%...
for /f "tokens=2 delims==" %%i in ('bx cs cluster-config %CLUSTER_NAME%') do @set KUBECONFIG=%%i
if %errorlevel% EQU 0 (
   echo KUBECONFIG is set to %KUBECONFIG% 
) else (
   echo KUBECONFIG was not properly set. Exiting.
   exit /b 1
)

echo Initializing Helm.
helm init --upgrade
echo "Waiting for Tiller (Helm's server component) to be ready..."
:helm_loop_start
:helmcheck1
 	kubectl --namespace=kube-system get pods | findstr tiller | findstr 1/1  >nul 2>&1
    goto helmcheck%errorlevel%
    timeout /t 1
    goto :helm_loop_start
:helmcheck0
echo.

:catalog-elasticsearch
echo Deleting catalog-elasticsearch chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-elasticsearch 
echo catalog-elasticsearch was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-elasticsearch --cascade >> BC_delete.log 2>&1  

:inventory_mysql
echo Deleting inventory_mysql chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-inventory-mysql 
echo inventory_mysql was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-inventory-mysql --cascade >> BC_delete.log 2>&1 

:customer
echo Deleting customer-ce chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-customer
echo customer-ce was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-customer --cascade >> BC_delete.log 2>&1 

:auth
echo Deleting auth-ce chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-auth
echo auth-ce was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-auth --cascade >> BC_delete.log 2>&1 

:inventory
echo Deleting inventory-ce chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-inventory 
echo inventory-ce was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-inventory --cascade >> BC_delete.log 2>&1 

:catalog
echo Deleting catalog-ce chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-catalog
echo catalog-ce was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-catalog --cascade >> BC_delete.log 2>&1 

:web
echo Deleting web-ce chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-web
echo web-ce was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-web --cascade >> BC_delete.log 2>&1 

:orders-mysql
echo Deleting orders-mysql chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-orders-mysql
echo orders-mysql was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-orders-mysql --cascade >> BC_delete.log 2>&1 

:orders-ce
echo Deleting orders-ce chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-orders
echo orders-ce was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-orders --cascade >> BC_delete.log 2>&1 

:Prometheus
echo Deleting prometheus chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-prometheus
echo prometheus was successfully deleted !
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-prometheus --cascade >> BC_delete.log 2>&1 

:Grafana
echo Deleting grafana chart. This will take a few minutes...
helm delete --purge --timeout 600 %NAMESPACE%-grafana
echo grafana was successfully deleted !

:all_deleted


echo.
echo Bluecompute was successfully deleted !
echo.
