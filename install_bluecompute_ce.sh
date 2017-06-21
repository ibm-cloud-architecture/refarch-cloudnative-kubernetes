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
HS_256_KEY=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 256 | head -n 1)

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

function install_inventory_mysql {
	local release=$(helm list | grep "${NAMESPACE}-mysql")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing inventory-mysql chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-mysql"

		time helm install --namespace ${NAMESPACE} inventory-mysql-0.1.1.tgz --name ${new_release} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing inventory-mysql... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory-mysql was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}inventory-mysql was already installed!${end}\n"
	fi
}

function install_inventory_backup {
	local release=$(helm list | grep "${NAMESPACE}-backup")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing inventory-backup chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-backup"

		time helm install --namespace ${NAMESPACE} inventory-backup-0.1.1.tgz --name ${new_release} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing inventory-backup... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory-backup was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}inventory-mysql was already installed!${end}\n"
	fi
}

function install_catalog_elasticsearch {
	local release=$(helm list | grep "${NAMESPACE}-elasticsearch" )

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing catalog-elasticsearch chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-elasticsearch"

		time helm install --namespace ${NAMESPACE} catalog-elasticsearch-0.1.1.tgz --name ${new_release} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing catalog-elasticsearch... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog-elasticsearch was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}catalog-elasticsearch was already installed!${end}\n"
	fi
}

function install_inventory {
	local release=$(helm list | grep "${NAMESPACE}-inventory" | grep inventory-ce)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing inventory-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-inventory"

		time helm install --namespace ${NAMESPACE} inventory-ce-0.1.1.tgz --name ${new_release} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing inventory-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}inventory-ce was already installed!${end}\n"
	fi
}

function install_catalog {
	local release=$(helm list | grep "${NAMESPACE}-catalog" | grep catalog-ce)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing catalog-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-catalog"

		time helm install --namespace ${NAMESPACE} catalog-ce-0.1.1.tgz --name ${new_release} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing catalog-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}catalog-ce was already installed!${end}\n"
	fi
}

function install_orders {
	local release=$(helm list | grep "${NAMESPACE}-orders")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing orders-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-orders"

		time helm install --namespace ${NAMESPACE} orders-ce-0.1.0.tgz --name ${new_release} --set hs256key.secret=${HS_256_KEY} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing orders-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}orders-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}orders-ce was already installed!${end}\n"
	fi
}

function install_customer {
	local release=$(helm list | grep "${NAMESPACE}-customer")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing customer-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-customer"

		time helm install --namespace ${NAMESPACE} customer-ce-0.1.0.tgz --name ${new_release} --set hs256key.secret=${HS_256_KEY} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing customer-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}customer-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}customer-ce was already installed!${end}\n"
	fi
}

function install_auth {
	local release=$(helm list | grep "${NAMESPACE}-auth")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing auth-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-auth"

		time helm install --namespace ${NAMESPACE} auth-ce-0.1.0.tgz --name ${new_release} --set hs256key.secret=${HS_256_KEY} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing auth-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}auth-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}auth-ce was already installed!${end}\n"
	fi
}

function install_web {
	local release=$(helm list | grep "${NAMESPACE}-web")

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing web-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"
		new_release="${NAMESPACE}-web"

		time helm install --namespace ${NAMESPACE} web-ce-0.1.0.tgz --name ${new_release} --set image.pullPolicy=Always --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing web-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}web-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl --namespace ${NAMESPACE} delete jobs -l release=${new_release} --cascade

	else
		printf "\n\n${grn}web-ce was already installed!${end}\n"
	fi
}

function get_web_port {
	kubectl --namespace ${NAMESPACE} get service bluecompute-web -o json | jq .spec.ports[0].nodePort
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
install_catalog_elasticsearch
install_inventory_mysql
install_inventory_backup
install_customer
install_auth
#install_orders
install_inventory
install_catalog
install_web
cd ../..

# Getting web port
webport=$(get_web_port)

while [[ "${webport}" == "" ]]; do
	sleep 1
	webport=$(get_web_port)
done

#sleep 10

printf "\n\n${grn}Bluecompute was successfully installed!${end}\n"

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

	printf "\n\nTo see Kubernetes Dashboard, paste the following in your terminal:\n"
	echo "${cyn}export KUBECONFIG=${KUBECONFIG}${end}"

	printf "\nThen run this command to connect to Kubernetes Dashboard:\n"
	echo "${cyn}kubectl proxy${end}"

	printf "\nThen open a browser window and paste the following URL to see the Services created by Bluecompute:\n"
	echo "${cyn}http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=${NAMESPACE}${end}"

	printf "\nFinally, on another browser window, copy and paste the following URL for BlueCompute Web UI:\n"
	echo "${cyn}http://${nodeip}:${webport}${end}"

fi

#curl -i -X POST http://${nodeip}:${webport}/oauth/token -d grant_type=password -d username=user -d password=passw0rd -d scope=blue
./audit_ce_master_install.sh &> /dev/null

printf "\nUse these credentials to login:"
printf "\n${cyn}username:${end} user"
printf "\n${cyn}password:${end} passw0rd\n"