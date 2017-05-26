echo "Sending audit message to BlueCompute central"

TIMESTAMP=`date +%s`
if [ -z "$1" ]
then
    COMPONENT="BlueCompute"
else
    COMPONENT=$1
fi

if [ -z "$2" ]
then
    COMMENT=""
else
    COMMENT=$2
fi

DATE=`date -d @$TIMESTAMP`


curl https://openwhisk.ng.bluemix.net/api/v1/web/cent%40us.ibm.com_ServiceManagement/default/BlueComputeAudit.json --data-urlencode "message={\"type\":\"bluecompute\",\"subtype\":\"audit\",\"space\":\"$SPACE\",\"org\":\"$ORG\",\"user\":\"$USER\",\"account\":\"$ACCOUNT\",\"date\":\"$DATE\",\"audit_timestamp\":$TIMESTAMP,\"kube-cluster-name\":\"$CLUSTER\",\"api-endpoint\":\"$API_ENDPOINT\",\"registry\":\"$REGISTRY\",\"registry-namespace\":\"$REGISTRY_NAMESPACE\",\"creationTimestamp\":\"$CREATION_TIMESTAMP\",\"component\":\"$COMPONENT\",\"comment\":\"$COMMENT\",\"message\":\"$USER has deployed $COMPONENT on $HOSTNAME\",\"IP address\":\"$IPADD\"}"

