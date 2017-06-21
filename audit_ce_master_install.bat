@echo off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS 
set PATH=%PATH%;%CD%;%CD%\win_utils

echo Sending audit message to BlueCompute central

for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt_str=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%
rem echo Local date is %ldt% / [%ldt_str%]

if  "%1" == "" (
   set COMPONENT=BlueCompute

) else (
   set COMPONENT=%1
)
if  "%1" == "" (
   set COMMENT=

) else (
   set COMMENT=%1
)
    
curl -X POST https://openwhisk.ng.bluemix.net/api/v1/web/cent@us.ibm.com_ServiceManagement/default/BlueComputeAudit.json --data-urlencode "message={\"type\":\"bluecompute\",\"subtype\":\"audit\",\"space\":\"%SPACE%\",\"org\":\"%ORG%\",\"user\":\"%USERNAME%\",\"account\":\"%ACCOUNT%\",\"date\":\"%ldt_str%\",\"audit_timestamp\":\"%ldt%\",\"kube-cluster-name\":\"%CLUSTER%\",\"api-endpoint\":\"%API_ENDPOINT%\",\"registry\":\"%REGISTRY%\",\"registry-namespace\":\"%REGISTRY_NAMESPACE%\",\"creationTimestamp\":\"%CREATION_TIMESTAMP%\",\"component\":\"%COMPONENT%\",\"comment\":\"%COMMENT%\",\"message\":\"%USERNAME% has deployed %COMPONENT% on %COMPUTERNAME%\",\"IP address\":\"%IPADD%\"}"