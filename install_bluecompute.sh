#!/bin/bash
set -e
# Terminal Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

API="api.ng.bluemix.net"
CLUSTER_NAME=$1

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Runnin
}

# Bluemix Login
printf "${grn}Login into Bluemix${end}\n"
bx login

printf "\n\n${grn}Getting Account Information...${end}\n"
SPACE=$(cat ~/.bluemix/.cf/config.json | jq .OrganizationFields.Name | sed 's/"//g')
ORG=$(cat ~/.bluemix/.cf/config.json | jq .SpaceFields.Name | sed 's/"//g')

# Creating for API KEY
printf "\n\n${grn}Creating API KEY...${end}\n"
API_KEY=$(bx iam api-key-create kubekey | tail -1 | awk '{print $3}')
echo "API key 'kubekey' was created"
echo "Please preserve the API key! It cannot be retrieved after it's created."
echo "API Key = ${API_KEY}"

printf "\n\n${grn}Login into Container Service${end}\n\n"
bx cs init

if [[ -z "${CLUSTER_NAME// }" ]]; then
	echo "${yel}No cluster name provided. Will try to get an existing cluster...${end}"
	CLUSTER_NAME=$(bx cs clusters | tail -1 | awk '{print $1}')

	if [[ "$CLUSTER_NAME" == "Name" ]]; then
		echo "No Kubernetes Clusters exist in your account. Please provision one and then run this script again."
		return 1
	fi
fi

# Getting Cluster Configuration
unset KUBECONFIG
echo "${grn}Getting configuration for cluster ${CLUSTER_NAME}...${end}"
eval "$(bx cs cluster-config ${CLUSTER_NAME} | tail -1)"
echo "KUBECONFIG is set to = $KUBECONFIG"

if [[ -z "${KUBECONFIG// }" ]]; then
	echo "KUBECONFIG was not properly set. Exiting"
	return 1
fi

printf "\n\n${grn}Initializing Helm.${end}\n"
helm init --upgrade
echo "Waiting for Tiller (Helm's server component) to be ready..."

TILLER_DEPLOYED=$(check_tiller)
while [[ "${TILLER_DEPLOYED}" == "" ]]; do 
	sleep 1
	TILLER_DEPLOYED=$(check_tiller)
done

printf "\n\n${grn}Installing BLUECOMPUTE Application. This will take a few minutes...${end}\n\n"
cd bluecompute
helm repo add bc https://fabiogomezdiaz.github.io/refarch-cloudnative-kubernetes/charts
helm dependency update

time helm install \
--set configMap.bluemixOrg=${ORG} \
--set configMap.bluemixSpace=${SPACE} \
--set configMap.kubeClusterName=${CLUSTER_NAME} \
--set secret.apiKey=${API_KEY} \
. --debug --wait

printf "\n\n${grn}Bluecompute was successfully installed!${end}\n"
printf "\n\n${grn}Cleaning up...${end}\n"
kubectl delete jobs,pods -l heritage=Tiller

cd ..

# Provide links to bluecompute web app
# Provide links to services in kube console
