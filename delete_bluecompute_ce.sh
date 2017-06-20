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
NAMESPACE=$5
BX_API_ENDPOINT=""

if [[ -z "${BX_REGION// }" ]]; then
	BX_API_ENDPOINT="api.ng.bluemix.net"
	echo "Using DEFAULT endpoint ${grn}${BX_API_ENDPOINT}${end}."

else
	BX_API_ENDPOINT="api.${BX_REGION}.bluemix.net"
	echo "Using endpoint ${grn}${BX_API_ENDPOINT}${end}."
fi

if [[ -z "${NAMESPACE// }" ]]; then
	NAMESPACE="default"
fi

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Running | grep 1/1
}

function print_usage {
	printf "\n\n${yel}Usage:${end}\n"
	printf "\t${cyn}./delete_bluecompute_ce.sh <cluster-name> <bluemix-space-name> <bluemix-api-key>${end}\n\n"
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

function get_cluster_name {
	printf "\n\n${grn}Login into Container Service${end}\n\n"
	bx cs init
	#bx cs init --host=https://us-south-beta.containers.bluemix.net

	if [[ -z "${CLUSTER_NAME// }" ]]; then
		echo "${yel}No cluster name provided. Will try to get an existing cluster...${end}"
		CLUSTER_NAME=$(bx cs clusters | tail -1 | awk '{print $1}')

		if [[ "$CLUSTER_NAME" == "Name" ]]; then
			echo "No Kubernetes Clusters exist in your account. Please provision one and then run this script again."
			exit 1
		fi
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

function delete_inventory {
	local release=$(helm list | grep "${NAMESPACE}-inventory" | grep inventory-ce | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}inventory-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting inventory-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting inventory-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=inventory-ce-0.1.1
	fi
}

function delete_inventory_mysql {
	local release=$(helm list | grep "${NAMESPACE}-mysql" | grep inventory-mysql | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}inventory-mysql was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting inventory-mysql chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting inventory-mysql... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory-mysql was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=inventory-mysql-ce-0.1.1
	fi
}

function delete_catalog {
	local release=$(helm list | grep "${NAMESPACE}-catalog" | grep catalog-ce | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}catalog-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting catalog-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting catalog-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=catalog-ce-0.1.1
	fi
}

function delete_catalog_elasticsearch {
	local release=$(helm list | grep "${NAMESPACE}-elasticsearch" | grep catalog-elasticsearch | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}catalog-elasticsearch was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting catalog-elasticsearch chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting catalog-elasticsearch... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog-elasticsearch was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=catalog-elasticsearch-ce-0.1.1
	fi
}

function delete_orders {
	local release=$(helm list | grep "${NAMESPACE}-orders" | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}orders-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting orders-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting orders-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}orders-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=orders-ce-0.1.0
	fi
}

function delete_customer {
	local release=$(helm list | grep "${NAMESPACE}-customer" | grep customer | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}customer-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting customer-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting customer-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}customer-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=customer-ce-0.1.0
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=customer-couchdb-0.1.0
	fi
}

function delete_auth {
	local release=$(helm list | grep "${NAMESPACE}-auth" | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}auth-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting auth-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting auth-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}auth-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=auth-ce-0.1.0
	fi
}

function delete_web {
	local release=$(helm list | grep "${NAMESPACE}-web" | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}web-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting web-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting web-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}web-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete pods,jobs -l chart=web-ce-0.1.0
	fi
}

# Setup Stuff
if [[ "$CLUSTER_NAME" == "minikube" ]]; then
	echo "${grn}Checking minikube status...${end}"

	minikube_vm_status=$(minikube status | grep minikubeVM | grep Running)
	localkube_status=$(minikube status | grep localkube | grep Running)

	if [[ "$minikube_vm_status" == "" || "$localkube_status" == "" ]]; then
		echo "Starting minikube..."
		minikube start
	else
		echo "minikube already started..."
	fi

	kubectl config use-context minikube
else
	bluemix_login
	get_cluster_name
	set_cluster_context
fi

initialize_helm

# Install Bluecompute
delete_web
delete_auth
delete_customer
delete_orders
delete_catalog
delete_catalog_elasticsearch
delete_inventory
delete_inventory_mysql

# Sanity Checks
printf "\n\n${grn}Doing some final cleanup${end}\n"
#kubectl --namespace ${NAMESPACE} delete jobs inventory-populate-mysql-inventory --force
kubectl --namespace ${NAMESPACE} delete pods,jobs -l heritage=Tiller --force
#kubectl --namespace ${NAMESPACE} delete secrets hs256-key

printf "\n\nBluecompute was uninstalled!\n"