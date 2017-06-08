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

if [[ -z "${BX_REGION// }" ]]; then
	BX_API_ENDPOINT="api.ng.bluemix.net"
	echo "Using DEFAULT endpoint ${grn}${BX_API_ENDPOINT}${end}."

else
	BX_API_ENDPOINT="api.${BX_REGION}.bluemix.net"
	echo "Using endpoint ${grn}${BX_API_ENDPOINT}${end}."
fi

function print_usage {
	printf "\n\n${yel}Usage:${end}\n"
	printf "\t${cyn}./kube_dashboard.sh <cluster-name> <bluemix-space-name> <bluemix-api-key>${end}\n\n"
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

# Setup Stuff
bluemix_login
set_cluster_context

kubectl proxy