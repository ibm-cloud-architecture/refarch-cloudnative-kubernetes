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
	kubectl --namespace=kube-system get pods | grep tiller | grep Running | grep 1/1
}

function print_usage {
	printf "\n\n${yel}Usage:${end}\n"
	printf "\t${cyn}./delete_bluecompute.sh <cluster-name> <bluemix-space-name> <bluemix-api-key>${end}\n\n"
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
	local release=$(helm list | grep inventory | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}inventory was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting inventory chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting inventory... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=inventory-0.1.1
	fi
}

function delete_catalog {
	local release=$(helm list | grep catalog | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}catalog was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting catalog chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting catalog... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=catalog-0.1.1
	fi
}

function delete_orders {
	local release=$(helm list | grep orders | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}orders was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting orders chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting orders... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}orders was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=orders-0.1.0
	fi
}

function delete_customer {
	local release=$(helm list | grep customer | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}customer was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting customer chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting customer... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}customer was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=customer-0.1.0
	fi
}

function delete_auth {
	local release=$(helm list | grep auth | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}auth was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting auth chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting auth... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}auth was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=auth-0.1.0
	fi
}

function delete_web {
	local release=$(helm list | grep web | awk '{print $1}' | head -1)

	# Creating for API KEY
	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}web was already deleted!${end}\n"
	else
		printf "\n\n${grn}Deleting web chart. This will take a few minutes...${end} ${coffee3}\n\n"
		time helm delete $release --purge --debug --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error deleting web... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}web was successfully deleted!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l chart=web-0.1.0
	fi
}

# Setup Stuff
bluemix_login
get_cluster_name
set_cluster_context
initialize_helm

# Install Bluecompute
delete_web
delete_auth
delete_customer
delete_orders
delete_catalog
delete_inventory

# Sanity Checks
printf "\n\n${grn}Doing some final cleanup${end}\n"
kubectl delete pods,jobs -l heritage=Tiller --force
kubectl delete secrets hs256-key

printf "\n\nBluecompute was uninstalled!\n"