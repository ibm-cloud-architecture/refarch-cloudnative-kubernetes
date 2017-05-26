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


FILENAME=/tmp/bx.target.dat
bx target > $FILENAME

SPACE=`grep Space $FILENAME | awk {'print $2'}` #; echo $SPACE
USER=`grep User $FILENAME | awk {'print $2'}`   #; echo $USER
ORG=`grep Org $FILENAME | awk {'print $2'}`     #; echo $ORG
ACCOUNT=$(grep Account $FILENAME | awk '{for(i=2;i<=NF;++i) printf "%s ",$i}') #; echo $ACCOUNT
rm -f $FILENAME

kubectl get configmap bluemix-target -o yaml > $FILENAME
CLUSTER=`grep kube-cluster-name $FILENAME |  awk {'print $2'}`
API_ENDPOINT=`grep bluemix-api-endpoint $FILENAME |  awk {'print $2'}`
REGISTRY=`grep registry: $FILENAME |  awk {'print $2'}`
REGISTRY_NAMESPACE=`grep registry-namespace: $FILENAME |  awk {'print $2'}`
CREATION_TIMESTAMP=`grep creationTimestamp $FILENAME |  awk {'print $2'}`
rm -f $FILENAME

DATE=`date -d @$TIMESTAMP`

curl https://openwhisk.ng.bluemix.net/api/v1/web/cent%40us.ibm.com_ServiceManagement/default/BlueComputeAudit.json --data-urlencode "message={\"type\":\"bluecompute\",\"subtype\":\"audit\",\"space\":\"$SPACE\",\"org\":\"$ORG\",\"user\":\"$USER\",\"account\":\"$ACCOUNT\",\"date\":\"$DATE\",\"audit_timestamp\":$TIMESTAMP,\"kube-cluster-name\":\"$CLUSTER\",\"api-endpoint\":\"$API_ENDPOINT\",\"registry\":\"$REGISTRY\",\"registry-namespace\":\"$REGISTRY_NAMESPACE\",\"creationTimestamp\":\"$CREATION_TIMESTAMP\",\"component\":\"$COMPONENT\",\"comment\":\"$COMMENT\",\"message\":\"$USER has deployed $COMPONENT on $ORG/$SPACE/$CLUSTER\"}"