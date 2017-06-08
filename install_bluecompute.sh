#!/bin/bash
# Terminal Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'
coffee=$'\xE2\x98\x95'
coffee3="${coffee} ${coffee} ${coffee}"

CLUSTER_NAME=$1
BX_SPACE=$2
BX_API_KEY=$3
BX_REGION=$4
BX_API_ENDPOINT=""
BX_ORG=""

if [[ -z "${BX_REGION// }" ]]; then
	BX_API_ENDPOINT="api.ng.bluemix.net"
	echo "Using DEFAULT endpoint ${grn}${BX_API_ENDPOINT}${end}."

else
	BX_API_ENDPOINT="api.${BX_REGION}.bluemix.net"
	echo "Using endpoint ${grn}${BX_API_ENDPOINT}${end}."
fi

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Running | grep 1/1
}

function print_usage {
	printf "\n\n${yel}Usage:${end}\n"
	printf "\t${cyn}./install_bluecompute.sh <cluster-name> <bluemix-space-name> <bluemix-api-key>${end}\n\n"
}

function bluemix_login {
	# Bluemix Login
	if [[ -z "${CLUSTER_NAME// }" ]]; then
		print_usage
		echo "${red}Please provide Cluster Name. Exiting..${end}"
		exit 1

	elif [[ -z "${BX_SPACE// }" ]]; then
		print_usage
		echo "${red}Please provide Bluemix Space. Exiting..${end}"
		exit 1

	elif [[ -z "${BX_API_KEY// }" ]]; then
		print_usage
		echo "${red}Please provide Bluemix API Key. Exiting..${end}"
		exit 1
	fi

	printf "${grn}Login into Bluemix${end}\n"

	export BLUEMIX_API_KEY=${BX_API_KEY}
	bx login -a ${BX_API_ENDPOINT} -s ${BX_SPACE}

	status=$?

	if [ $status -ne 0 ]; then
		printf "\n\n${red}Bluemix Login Error... Exiting.${end}\n"
		exit 1
	fi
}

function create_api_key {
	# Creating for API KEY
	if [[ -z "${BX_API_KEY// }" ]]; then
		printf "\n\n${grn}Creating API KEY...${end}\n"
		BX_API_KEY=$(bx iam api-key-create kubekey | tail -1 | awk '{print $3}')
		echo "${yel}API key 'kubekey' was created.${end}"
		echo "${mag}Please preserve the API key! It cannot be retrieved after it's created.${end}"
		echo "${cyn}Name${end}	kubekey"
		echo "${cyn}API Key${end}	${BX_API_KEY}"
	fi
}

function get_org {
	BX_ORG=$(cat ~/.bluemix/.cf/config.json | jq .OrganizationFields.Name | sed 's/"//g')
}

function get_space {
	if [[ -z "${BX_SPACE// }" ]]; then
		BX_SPACE=$(cat ~/.bluemix/.cf/config.json | jq .SpaceFields.Name | sed 's/"//g')
	fi
}

function set_cluster_context {
	printf "\n\n${grn}Login into Container Service${end}\n\n"
	bx cs init

	# Getting Cluster Configuration
	unset KUBECONFIG
	printf "\n${grn}Setting terminal context to \"${CLUSTER_NAME}\"...${end}\n"
	eval "$(bx cs cluster-config ${CLUSTER_NAME} | tail -1)"
	echo "KUBECONFIG is set to = $KUBECONFIG"

	if [[ -z "${KUBECONFIG// }" ]]; then
		echo "${red}KUBECONFIG was not properly set. Exiting.${end}"
		exit 1
	fi
}

function initialize_helm {
	printf "\n\n${grn}Initializing Helm.${end}\n"
	helm init --upgrade
	echo "Waiting for Tiller (Helm's server component) to be ready..."

	TILLER_DEPLOYED=$(check_tiller)
	while [[ "${TILLER_DEPLOYED}" == "" ]]; do
		sleep 1
		TILLER_DEPLOYED=$(check_tiller)
	done
}

function add_repo {
	printf "\n\n${grn}Adding bluecompute Helm Repo.${end}\n\n"
	helm repo add bluecompute https://ibm-cloud-architecture.github.io/refarch-cloudnative-kubernetes/charts
}

function install_inventory {
	local release=$(helm list | grep inventory)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing inventory chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name inventory --debug --timeout 600 \
		--set configMap.bluemixAPIEndpoint=${BX_API_ENDPOINT} \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		inventory-0.1.1.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing inventory... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}inventory was already installed!${end}\n"
	fi
}

function install_catalog {
	local release=$(helm list | grep catalog)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing catalog chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name catalog --debug --timeout 600 \
		--set secret.skipDelete=true \
		--set configMap.skipDelete=true \
		--set configMap.bluemixAPIEndpoint=${BX_API_ENDPOINT} \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		catalog-0.1.1.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing catalog... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller
	else
		printf "\n\n${grn}catalog was already installed!${end}\n"
	fi
}

function install_orders {
	local release=$(helm list | grep orders)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing orders chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name orders --debug --timeout 600 \
		--set messagehub.skipDelete=true \
		--set mysql.skipDelete=true \
		--set secret.skipDelete=true \
		--set configMap.skipDelete=true \
		--set configMap.bluemixAPIEndpoint=${BX_API_ENDPOINT} \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		orders-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing orders... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}orders was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller
	else
		printf "\n\n${grn}orders was already installed!${end}\n"
	fi
}

function install_customer {
	local release=$(helm list | grep customer)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing customer chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name customer --debug --timeout 600 \
		--set hs256key.skipDelete=true \
		--set secret.skipDelete=true \
		--set configMap.skipDelete=true \
		--set configMap.bluemixAPIEndpoint=${BX_API_ENDPOINT} \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		customer-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing customer... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}customer was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller
	else
		printf "\n\n${grn}customer was already installed!${end}\n"
	fi
}

function install_auth {
	local release=$(helm list | grep auth)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing auth chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name auth --debug --timeout 600 \
		--set hs256key.skipDelete=true \
		auth-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing auth... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}auth was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller
	else
		printf "\n\n${grn}auth was already installed!${end}\n"
	fi
}

function install_web {
	local release=$(helm list | grep web)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing web  chart. This will take a few minutes...${end} ${coffee3}\n\n"
        ing_subdomain=$(bx cs cluster-get ${CLUSTER_NAME} | grep 'Ingress subdomain:' | awk '{print $NF}')
		time helm install --name web --debug --timeout 600 --set ingCtlHost=${ing_subdomain} web-0.1.0.tgz
    
		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing web... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}web was successfully installed!${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller
	else
		printf "\n\n${grn}web was already installed!${end}\n"
	fi
}

# Setup Stuff
bluemix_login
create_api_key
get_org
get_space
set_cluster_context
initialize_helm
#add_repo

# Install Bluecompute
cd docs/charts
install_inventory
install_catalog
install_orders
install_customer
install_auth
install_web
cd ../..

printf "\n\n${grn}Bluecompute was successfully installed!${end}\n"

printf "\n\nTo see Kubernetes Dashboard, paste the following in your terminal:\n"
echo "${cyn}export KUBECONFIG=${KUBECONFIG}${end}"

printf "\nThen run this command to connect to Kubernetes Dashboard:\n"
echo "${cyn}kubectl proxy${end}"

printf "\nThen open a browser window and paste the following URL to see the Services created by Bluecompute Chart:\n"
echo "${cyn}http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=default${end}"

printf "\nFinally, on another browser window, copy and paste the following URL for BlueCompute Web UI:\n"
echo "${cyn}http://${ing_subdomain}${end}"

/bin/sh audit.sh &> /dev/null

printf "\nUse these credentials to login:"
printf "\n${cyn}username:${end} user"
printf "\n${cyn}password:${end} passw0rd\n"