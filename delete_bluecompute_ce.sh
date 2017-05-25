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

function check_tiller {
	kubectl --namespace=kube-system get pods | grep tiller | grep Running
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

function delete_bluecompute_inventory {
	local release=$(helm list | grep bluecompute-inventory | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-inventory-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-inventory-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-inventory-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-inventory-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-inventory-ce-0.1.1
	fi
}

function delete_bluecompute_inventory_mysql {
	local release=$(helm list | grep inventory-mysql | awk '{print $1}' | head -1)

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
		kubectl delete pods,jobs -l chart=inventory-mysql-ce-0.1.1
	fi
}

function delete_bluecompute_catalog {
	local release=$(helm list | grep bluecompute-catalog | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-catalog-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-catalog-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-catalog-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-catalog-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-catalog-ce-0.1.1
	fi
}

function delete_bluecompute_catalog_elasticsearch {
	local release=$(helm list | grep catalog-elasticsearch | awk '{print $1}' | head -1)

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
		kubectl delete pods,jobs -l chart=catalog-elasticsearch-ce-0.1.1
	fi
}

function delete_bluecompute_orders {
	local release=$(helm list | grep bluecompute-orders | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-orders-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-orders-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-orders-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-orders-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-orders-ce-0.1.0
	fi
}

function delete_bluecompute_customer {
	local release=$(helm list | grep bluecompute-customer | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-customer-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-customer-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-customer-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-customer-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-customer-ce-0.1.0
		kubectl delete pods,jobs -l chart=bluecompute-customer-couchdb-0.1.0
	fi
}

function delete_bluecompute_auth {
	local release=$(helm list | grep bluecompute-auth | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-auth-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-auth-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-auth-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-auth-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-auth-ce-0.1.0
	fi
}

function delete_bluecompute_web {
	local release=$(helm list | grep bluecompute-web | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-web-ce was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-web-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-web-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-web-ce was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-web-ce-0.1.0
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
delete_bluecompute_web
delete_bluecompute_auth
delete_bluecompute_customer
delete_bluecompute_orders
delete_bluecompute_catalog
delete_bluecompute_catalog_elasticsearch
delete_bluecompute_inventory
delete_bluecompute_inventory_mysql

# Sanity Checks
printf "\n\n${grn}Doing some final cleanup${end}\n"
kubectl delete pods,jobs -l heritage=Tiller
kubectl delete secrets hs256-key

printf "\n\nBluecompute was uninstalled!\n"