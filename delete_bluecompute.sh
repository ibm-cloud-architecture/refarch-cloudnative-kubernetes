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
		printf "\n\n${grn}bluecompute-inventory was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-inventory chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-inventory... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-inventory was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-inventory-0.1.1
	fi
}

function delete_bluecompute_catalog {
	local release=$(helm list | grep bluecompute-catalog | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-catalog was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-catalog chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-catalog... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-catalog was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-catalog-0.1.1
	fi
}

function delete_bluecompute_orders {
	local release=$(helm list | grep bluecompute-orders | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-orders was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-orders chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-orders... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-orders was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-orders-0.1.0
	fi
}

function delete_bluecompute_customer {
	local release=$(helm list | grep bluecompute-customer | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-customer was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-customer chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-customer... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-customer was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-customer-0.1.0
	fi
}

function delete_bluecompute_auth {
	local release=$(helm list | grep bluecompute-auth | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-auth was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-auth chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-auth... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-auth was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-auth-0.1.0
	fi
}

function delete_bluecompute_web {
	local release=$(helm list | grep bluecompute-web | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}bluecompute-web was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting bluecompute-web chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting bluecompute-web... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-web was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=bluecompute-web-0.1.0
	fi
}

# Setup Stuff
bluemix_login
get_cluster_name
set_cluster_context
initialize_helm

# Install Bluecompute
delete_bluecompute_web
delete_bluecompute_auth
delete_bluecompute_customer
delete_bluecompute_orders
delete_bluecompute_catalog
delete_bluecompute_inventory

printf "\n\nBluecompute was uninstalled!\n"