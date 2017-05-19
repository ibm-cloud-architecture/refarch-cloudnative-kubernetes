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

BX_API_ENDPOINT="api.ng.bluemix.net"
CLUSTER_NAME=$1
BX_SPACE=$2
BX_API_KEY=$3
BX_CR_NAMESPACE=""
BX_ORG=""

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Runnin
}

function bluemix_login {
	# Bluemix Login
	printf "${grn}Login into Bluemix${end}\n"
	if [[ -z "${BX_API_KEY// }" && -z "${BX_SPACE// }" ]]; then
		echo "${yel}API Key & SPACE NOT provided.${end}"
		bx login -a ${BX_API_ENDPOINT}

	elif [[ -z "${BX_SPACE// }" ]]; then
		echo "${yel}API Key provided but SPACE was NOT provided.${end}"
		export BLUEMIX_API_KEY=${BX_API_KEY}
		bx login -a ${BX_API_ENDPOINT}

	elif [[ -z "${BX_API_KEY// }" ]]; then
		echo "${yel}API Key NOT provided but SPACE was provided.${end}"
		bx login -a ${BX_API_ENDPOINT} -s ${BX_SPACE}

	else
		echo "${yel}API Key and SPACE provided.${end}"
		export BLUEMIX_API_KEY=${BX_API_KEY}
		bx login -a ${BX_API_ENDPOINT} -s ${BX_SPACE}
	fi

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

function create_registry_namespace {	
	printf "\n\n${grn}Login into Container Registry Service${end}\n\n"
	bx cr login
	BX_CR_NAMESPACE="jenkins$(cat ~/.bluemix/config.json | jq .Account.GUID | sed 's/"//g' | tail -c 7)"
	printf "\nCreating namespace \"${BX_CR_NAMESPACE}\"...\n"
	bx cr namespace-add ${BX_CR_NAMESPACE} &> /dev/null
	echo "Done"
}

function get_cluster_name {
	printf "\n\n${grn}Login into Container Service${end}\n\n"
	bx cs init

	if [[ -z "${CLUSTER_NAME// }" ]]; then
		echo "${yel}No cluster name provided. Will try to get an existing cluster...${end}"
		CLUSTER_NAME=$(bx cs clusters | tail -1 | awk '{print $1}')

		if [[ "$CLUSTER_NAME" == "Name" ]]; then
			echo "No Kubernetes Clusters exist in your account. Please provision one and then run this script again."
			exit 1
		fi
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

function add_bluecompute_repo {
	printf "\n\n${grn}Adding bluecompute Helm Repo.${end}\n\n"
	helm repo add bluecompute https://ibm-cloud-architecture.github.io/refarch-cloudnative-kubernetes/charts
}

function install_bluecompute_inventory {
	local release=$(helm list | grep bluecompute-inventory)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-inventory chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name inventory --debug --wait --timeout 600 \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.bluemixRegistryNamespace=${BX_CR_NAMESPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		bluecompute-inventory-0.1.1.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-inventory... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-inventory was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-inventory-0.1.1

	else
		printf "\n\n${grn}bluecompute-inventory was already installed!${end}\n"
	fi
}

function install_bluecompute_catalog {
	local release=$(helm list | grep bluecompute-catalog)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-catalog chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name catalog --debug --wait --timeout 600 \
		--set secret.skipDelete=true \
		--set configMap.skipDelete=true \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.bluemixRegistryNamespace=${BX_CR_NAMESPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		bluecompute-catalog-0.1.1.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-catalog... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-catalog was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-catalog-0.1.1
	else
		printf "\n\n${grn}bluecompute-catalog was already installed!${end}\n"
	fi
}

function install_bluecompute_orders {
	local release=$(helm list | grep bluecompute-orders)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-orders chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name orders --debug --wait --timeout 600 \
		--set messagehub.skipDelete=true \
		--set mysql.skipDelete=true \
		--set secret.skipDelete=true \
		--set configMap.skipDelete=true \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.bluemixRegistryNamespace=${BX_CR_NAMESPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		bluecompute-orders-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-orders... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-orders was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-orders-0.1.0
	else
		printf "\n\n${grn}bluecompute-orders was already installed!${end}\n"
	fi
}

function install_bluecompute_customer {
	local release=$(helm list | grep bluecompute-customer)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-customer chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name customer --debug --wait --timeout 600 \
		--set hs256key.skipDelete=true \
		--set secret.skipDelete=true \
		--set configMap.skipDelete=true \
		--set configMap.bluemixOrg=${BX_ORG} \
		--set configMap.bluemixSpace=${BX_SPACE} \
		--set configMap.bluemixRegistryNamespace=${BX_CR_NAMESPACE} \
		--set configMap.kubeClusterName=${CLUSTER_NAME} \
		--set secret.apiKey=${BX_API_KEY} \
		bluecompute-customer-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-customer... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-customer was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-customer-0.1.0
	else
		printf "\n\n${grn}bluecompute-customer was already installed!${end}\n"
	fi
}

function install_bluecompute_auth {
	local release=$(helm list | grep bluecompute-auth)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-auth chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name auth --debug --wait --timeout 600 \
		--set hs256key.skipDelete=true \
		bluecompute-auth-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-auth... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-auth was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-auth-0.1.0
	else
		printf "\n\n${grn}bluecompute-auth was already installed!${end}\n"
	fi
}

function install_bluecompute_web {
	local release=$(helm list | grep bluecompute-web)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-web  chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm install --name web --debug --wait --timeout 600 \
		bluecompute-web-0.1.0.tgz

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-web... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-web was successfully installed!${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-web-0.1.0
	else
		printf "\n\n${grn}bluecompute-web was already installed!${end}\n"
	fi
}

# Setup Stuff
bluemix_login
create_api_key
create_registry_namespace
get_cluster_name
get_org
get_space
set_cluster_context
initialize_helm
#add_bluecompute_repo

# Install Bluecompute
cd docs/charts
install_bluecompute_inventory
install_bluecompute_catalog
install_bluecompute_orders
install_bluecompute_customer
install_bluecompute_auth
install_bluecompute_web
cd ..

printf "\n\nTo see Kubernetes Dashboard, paste the following in your terminal:\n"
echo "${cyn}export KUBECONFIG=${KUBECONFIG}${end}"

printf "\nThen run this command to connect to Kubernetes Dashboard:\n"
echo "${cyn}kubectl proxy${end}"

printf "\nThen open a browser window and paste the following URL to see the Services created by Bluecompute Chart:\n"
echo "${cyn}http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=default${end}"

printf "\nFinally, on another browser window, copy and paste the following URL for BlueCompute Web UI:\n"
echo "${cyn}http://${CLUSTER_NAME}.us-south.containers.mybluemix.net${end}"