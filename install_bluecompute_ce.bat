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

:GetKey
set alfanum=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789

set HS_256_KEY=
FOR /L %%b IN (0, 1, 256) DO (
SET /A rnd_num=!RANDOM! * 62 / 32768 + 1
for /F %%c in ('echo %%alfanum:~!rnd_num!^,1%%') do set HS_256_KEY=!HS_256_KEY!%%c
)

rem echo HS_256_KEY=%HS_256_KEY%
rem @echo on

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
echo Installing catalog-elasticsearch chart. This will take a few minutes...
helm list | findstr elasticsearch
if %errorlevel% EQU 0 (
   echo catalog-elasticsearch is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\catalog-elasticsearch-0.1.1.tgz --name %NAMESPACE%-elasticsearch --set image.pullPolicy=Always --set mysql.secret=binding-%NAMESPACE%-inventory-mysql --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install catalog-elasticsearch. Exiting.
   exit /b 1
)
echo catalog-elasticsearch was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-elasticsearch --cascade >> BC_install.log 2>&1  

:inventory_mysql
echo Installing inventory_mysql chart. This will take a few minutes...
helm list | findstr inventory_mysql
if %errorlevel% EQU 0 (
   echo inventory_mysql is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\ibmcase-mysql-0.1.0.tgz   --name %NAMESPACE%-inventory-mysql --set image.pullPolicy=Always --set mysql.binding.name=binding-%NAMESPACE%-inventory-mysql --set mysql.dbname=inventorydb --set mysql.service.name=inventorydb-mysql --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install inventory_mysql. Exiting.
   exit /b 1
)
echo inventory_mysql was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-inventory-mysql --cascade >> BC_install.log 2>&1 

:customer
echo Installing customer-ce chart. This will take a few minutes...
helm list | findstr customer
if %errorlevel% EQU 0 (
   echo customer is already installed. Exiting.
   exit /b 1
)

helm install --namespace %NAMESPACE% docs\charts\customer-ce-0.1.0.tgz --name %NAMESPACE%-customer --set hs256key.secret=%HS_256_KEY% --set image.pullPolicy=Always --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install customer-ce. Exiting.
   exit /b 1
)
echo customer-ce was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-customer --cascade >> BC_install.log 2>&1 

:auth
echo Installing auth-ce chart. This will take a few minutes...
helm list | findstr auth
if %errorlevel% EQU 0 (
   echo auth is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\auth-ce-0.1.0.tgz --name %NAMESPACE%-auth --set hs256key.secret=%HS_256_KEY% --set image.pullPolicy=Always --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install auth-ce. Exiting.
   exit /b 1
)
echo auth-ce was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-auth --cascade >> BC_install.log 2>&1 

:inventory
echo Installing inventory-ce chart. This will take a few minutes...
helm list | findstr /C:"inventory "
if %errorlevel% EQU 0 (
   echo inventory is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\inventory-ce-0.1.1.tgz --name %NAMESPACE%-inventory --set image.pullPolicy=Always --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install inventory-ce. Exiting.
   exit /b 1
)
echo inventory-ce was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-inventory --cascade >> BC_install.log 2>&1 

:catalog
echo Installing catalog-ce chart. This will take a few minutes...
helm list | findstr /C:"catalog "
if %errorlevel% EQU 0 (
   echo catalog is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\catalog-ce-0.1.1.tgz --name %NAMESPACE%-catalog --set image.pullPolicy=Always --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install catalog-ce. Exiting.
   exit /b 1
)
echo catalog-ce was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-catalog --cascade >> BC_install.log 2>&1 

:web
echo Installing web-ce chart. This will take a few minutes...
helm list | findstr web
if %errorlevel% EQU 0 (
   echo web is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\web-ce-0.1.0.tgz --name %NAMESPACE%-web --set image.pullPolicy=Always --set region=%BX_REGION% --set cluster_name=%CLUSTER_NAME%  --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install web-ce. Exiting.
   exit /b 1
)
echo web-ce was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-web --cascade >> BC_install.log 2>&1 

:orders-mysql
echo Installing orders-mysql chart. This will take a few minutes...
helm list | findstr orders-mysql
if %errorlevel% EQU 0 (
   echo web is already installed. Exiting.
   exit /b 1
)

helm install --namespace %NAMESPACE% docs\charts\ibmcase-mysql-0.1.0.tgz --name %NAMESPACE%-orders-mysql --set image.pullPolicy=Always --set mysql.dbname=ordersdb --set mysql.binding.name=binding-%NAMESPACE%-orders-mysql --set mysql.service.name=ordersdb-mysql --timeout 600  >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install orders-mysql. Exiting.
   exit /b 1
)
echo orders-mysql was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-orders-mysql --cascade >> BC_install.log 2>&1 


:orders-ce
echo Installing orders-ce chart. This will take a few minutes...
helm list | findstr orders-ce
if %errorlevel% EQU 0 (
   echo web is already installed. Exiting.
   exit /b 1
)
helm install --namespace %NAMESPACE% docs\charts\orders-ce-0.1.0.tgz --name %NAMESPACE%-orders --set hs256key.secret=%HS_256_KEY% --set image.pullPolicy=Always --set mysql.binding.name=binding-%NAMESPACE%-orders-mysql --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install orders-ce. Exiting.
   exit /b 1
)
echo orders-ce was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-orders --cascade >> BC_install.log 2>&1 


:Prometheus
echo Installing prometheus chart. This will take a few minutes...
helm list | findstr prometheus
if %errorlevel% EQU 0 (
   echo prometheus is already installed. skipping...
   goto Grafana
)
helm install --namespace %NAMESPACE% stable/prometheus --name %NAMESPACE%-prometheus --set server.persistentVolume.enabled=false --set alertmanager.persistentVolume.enabled=false --set image.pullPolicy=Always --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install prometheus. Exiting.
   exit /b 1
)
echo prometheus was successfully installed!
echo Cleaning up...
kubectl --namespace %NAMESPACE% delete jobs -l release=%NAMESPACE%-prometheus --cascade >> BC_install.log 2>&1 

:Grafana
echo Installing grafana chart. This will take a few minutes...
helm list | findstr grafana
if %errorlevel% EQU 0 (
   echo grafana is already installed. skipping...
   goto all_deployed
)
helm install --namespace %NAMESPACE% docs\charts\grafana-bc-0.3.1.tgz --name %NAMESPACE%-grafana --set setDatasource.datasource.url=http://%NAMESPACE%-prometheus-prometheus-server.default.svc.cluster.local --set server.persistentVolume.enabled=false --set server.serviceType=NodePort --set image.pullPolicy=Always --timeout 600 >> BC_install.log 2>&1
if %errorlevel% NEQ 0 (
   echo Could not install grafana. Exiting.
   exit /b 1
)
echo grafana was successfully installed!

:all_deployed

:audit
call audit_ce_master_install.bat

echo Getting the Node IP
:getNodeIP
kubectl get nodes -o jsonpath={.items[*].status.addresses[?(@.type==\"ExternalIP\")].address} > %TMP%\BC_NodeIP.tmp
for /f %%i in (%TMP%\BC_NodeIP.tmp) do @set NODEIP=%%i


echo Getting the WebPorts for the apps.
:bcwebport_loop_start
    echo polling the service bluecompute-web in namespace %NAMESPACE% to get the webport
    kubectl get service --namespace=%NAMESPACE% bluecompute-web -o json | for /f %%i in ('jq .spec.ports[0].nodePort') do @echo %%i > %TMP%\BC_Webport.tmp
    for /f %%i in (%TMP%\BC_Webport.tmp) do @set BCWEBPORT=%%i

    if "%BCWEBPORT%" == "null" (
       timeout /t 1
       goto :bcwebport_loop_start
    )   
    if "%BCWEBPORT%" == "" (
       timeout /t 1
       goto :bcwebport_loop_start
    )   
    goto bcwebport_loop_exit
goto :bcwebport_loop_start
:bcwebport_loop_exit

:grwebport_loop_start
    echo polling the service grafana-grafana in namespace %NAMESPACE% to get the webport
    kubectl get service --namespace=%NAMESPACE% %NAMESPACE%-grafana-grafana -o json | for /f %%i in ('jq .spec.ports[0].nodePort') do @echo %%i > %TMP%\GR_Webport.tmp
    for /f %%i in (%TMP%\GR_Webport.tmp) do @set GRWEBPORT=%%i

    if "%GRWEBPORT%" == "null" (
       timeout /t 1
       goto :grwebport_loop_start
    )   
    if "%GRWEBPORT%" == "" (
       timeout /t 1
       goto :grwebport_loop_start
    )   
    goto grwebport_loop_exit
goto :grwebport_loop_start
:grwebport_loop_exit

:grafana_password
kubectl get secret --namespace %NAMESPACE% %NAMESPACE%-grafana-grafana -o jsonpath="{.data.grafana-admin-password}" > %TMP%\GR_Passwrd.tmp
certutil -f -decode %TMP%\GR_Passwrd.tmp %TMP%\GR_Passwrd.out
for /f %%i in (%TMP%\GR_Passwrd.out) do @set GRPASS=%%i
del %TMP%\GR_Passwrd.tmp
del %TMP%\GR_Passwrd.out

echo.
echo Bluecompute was successfully installed!
echo.
echo To see Kubernetes Dashboard, paste the following in your terminal:
echo  set KUBECONFIG=%KUBECONFIG%
echo.
echo Then run this command to connect to Kubernetes Dashboard:
echo  kubectl proxy
echo.
echo Then open a browser window and paste the following URL to see the Services created by Bluecompute:
echo  http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=%NAMESPACE%
echo.
echo Finally, on another browser window, copy and paste the following URL for BlueCompute Web UI:
echo  http://%NODEIP%:%BCWEBPORT%
echo.
echo To access the Grafana dashboards, copy and paste the following URL onto a browser window:
echo  http://%NODEIP%:%GRWEBPORT%
echo.
echo The initial user is "admin" and the password is "%GRPASS%"
echo To load more dashboards, execute the following script:
echo  import_bc_grafana_dashboards.bat http://%NODEIP%:%GRWEBPORT% %GRPASS%

