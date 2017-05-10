#!/bin/bash
set -e

API="api.ng.bluemix.net"
USER=$1
PASSWORD=$2
BLUEMIX_ACCOUNT=$3
ORG=$4
SPACE=$5
CLUSTER_NAME=$6
API_KEY=$7

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Runnin
}

# Bluemix Login
printf "Login into Bluemix\n"
bx login -a ${API} -u ${USER} -p ${PASSWORD} -c ${BLUEMIX_ACCOUNT} -o ${ORG} -s ${SPACE}
#bx login -a ${API}

# Checking for API KEY
if [[ -z "${API_KEY// }" ]]; then
	echo "No API Key Provided. Creating one.."
	API_KEY=$(bx iam api-key-create kubekey | tail -1 | awk '{print $3}')
	echo "API key 'kubekey' was created"
	echo "Please preserve the API key! It cannot be retrieved after it's created."
	echo "API Key = ${API_KEY}"
fi


printf "\n\nLogin into Container Service\n\n"
bx cs init

if [[ -z "${CLUSTER_NAME// }" ]]; then
	echo "No cluster name provided. Will try to get an existing cluster..."
	CLUSTER_NAME=$(bx cs clusters | tail -1 | awk '{print $1}')

	if [[ "$CLUSTER_NAME" == "Name" ]]; then
		echo "No Kubernetes Clusters exist in your account. Please provision one and then run this script again."
		return 1
	fi
fi

# Getting Cluster Configuration
unset KUBECONFIG
eval "$(bx cs cluster-config ${CLUSTER_NAME} | tail -1)"
echo "KUBECONFIG is set to = $KUBECONFIG"

if [[ -z "${KUBECONFIG// }" ]]; then
	echo "KUBECONFIG was not properly set. Exiting"
	return 1
fi

printf "\n\nInitializing Helm.\n"
helm init --upgrade
echo "Waiting for Tiller (Helm's server component) to be ready..."

TILLER_DEPLOYED=$(check_tiller)
while [[ "${TILLER_DEPLOYED}" == "" ]]; do 
	sleep 1
	TILLER_DEPLOYED=$(check_tiller)
done

printf "\n\nInstalling BLUECOMPUTE Application. This will take a few minutes...\n\n"
cd bluecompute
helm repo add bc https://fabiogomezdiaz.github.io/refarch-cloudnative-devops/charts
helm dependency update

time helm install \
--set configMap.bluemixOrg=${ORG} \
--set configMap.bluemixSpace=${SPACE} \
--set configMap.kubeClusterName=${CLUSTER_NAME} \
--set secret.apiKey=${API_KEY} \
. --debug --wait

printf "\n\nCleaning up...\n"
kubectl delete jobs,pods -l heritage=Tiller

cd ..

# Provide links to bluecompute web app
# Provide links to services in kube console
