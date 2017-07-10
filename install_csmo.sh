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
	printf "\t${cyn}./install_bluecompute_ce.sh <cluster-name> <bluemix-space-name> <bluemix-api-key>${end}\n\n"
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

function install_prometheus {
	local release=$(helm list | grep "${NAMESPACE}-prometheus")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing prometheus chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-prometheus"

		time helm install --namespace ${NAMESPACE} stable/prometheus --name ${new_release} --set image.pullPolicy=Always --set server.persistentVolume.enabled=false --set alertmanager.persistentVolume.enabled=false --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing prometheus... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}prometheus was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}prometheus was already installed!${end}\n"
	fi
}

function install_grafana {
	local release=$(helm list | grep "${NAMESPACE}-grafana" )

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing grafana chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-grafana"

		time helm install --namespace ${NAMESPACE} grafana-bc-0.3.1.tgz --name ${new_release} --set image.pullPolicy=Always --set server.setDatasource.datasource.url=http://%NAMESPACE%-prometheus-prometheus-server.%NAMESPACE%.svc.cluster.local --set server.persistentVolume.enabled=false --set server.serviceType=NodePort --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing grafana... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}grafana was successfully installed!${end}\n"
	else
		printf "\n\n${grn}grafana was already installed!${end}\n"
	fi
}

function get_web_port {
	kubectl --namespace ${NAMESPACE} get service ${NAMESPACE}-grafana-grafana -o json | jq .spec.ports[0].nodePort
}

function create_kube_namespace {
	echo "Using ${grn}${NAMESPACE}${end} namespace."
	kubectl get namespaces ${NAMESPACE}

	local status=$?
	if [ $status -ne 0 ]; then
		printf "\n\n${yel}Creating namespace.${end}\n"
		kubectl create namespace ${NAMESPACE}

		status=$?
		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error creating namespace... Exiting.${end}\n"
			exit 1
		fi
	else
		echo "Namespace exists."
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
		kubectl config use-context minikube
		status=$?

		if [ $status -ne 0 ]; then
			echo "Starting minikube..."
			minikube start
		fi
	fi
else
	bluemix_login
	set_cluster_context
fi

initialize_helm
create_kube_namespace

# Install Bluecompute
cd docs/charts
install_prometheus
install_grafana
cd ../..

# Getting web port
webport=$(get_web_port)

while [[ "${webport}" == "" ]]; do
	sleep 1
	webport=$(get_web_port)
done

# Getting the password
password = $(kubectl get secret --namespace ${NAMESPACE} ${NAMESPACE}-grafana-grafana -o jsonpath="{.data.grafana-admin-password}" | base64 --decode )

printf "\n\n${grn}Bluecompute monitoring was successfully installed!${end}\n"

if [[ "$CLUSTER_NAME" == "minikube" ]]; then
	nodeip=$(minikube ip)

	printf "\n\nTo see Kubernetes Dashboard, paste the following in your terminal:\n"
	echo "${cyn}minikube dashboard${end}"

	printf "\nThen open a browser window and paste the following URL to see the Services created by Bluecompute:\n"
	echo "${cyn}http://192.168.99.100:30000/#/service?namespace=default${end}"

	printf "\nFinally, on another browser window, copy and paste the following URL for BlueCompute Web UI:\n"
	echo "${cyn}http://${nodeip}:${webport}${end}"

else
	nodeip=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}' | awk '{print $1}')

    printf "\n\nTo access the Grafana dashboards, copy and paste the following URL onto a browser window:"
    printf "\n\thttp://${nodeip}:${webport}"
    printf "\n\tThe initial user is admin and the password is ${password}"
    printf "\n\nTo load more dashboards, execute the following script:"
	printf "\n\./import_bc_grafana_dashboards.sh http://${nodeip}:${webport} ${password}"
	printf "\n"

fi