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

function get_web_port {
	kubectl get service bluecompute-web -o json | jq .spec.ports[0].nodePort
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

function install_bluecompute_inventory_mysql {
	local release=$(helm list | grep inventory-mysql)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing inventory-mysql chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install inventory-mysql-0.1.1.tgz --name inventory-mysql --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing inventory-mysql... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}inventory-mysql was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}inventory-mysql was already installed!${end}\n"
	fi
}

function install_bluecompute_catalog_elasticsearch {
	local release=$(helm list | grep catalog-elasticsearch)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing catalog-elasticsearch chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install catalog-elasticsearch-0.1.1.tgz --name catalog-elasticsearch --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing catalog-elasticsearch... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}catalog-elasticsearch was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}catalog-elasticsearch was already installed!${end}\n"
	fi
}

function install_bluecompute_inventory {
	local release=$(helm list | grep bluecompute-inventory)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-inventory-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install bluecompute-inventory-ce-0.1.1.tgz --name bluecompute-inventory --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-inventory-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-inventory-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}bluecompute-inventory-ce was already installed!${end}\n"
	fi
}

function install_bluecompute_catalog {
	local release=$(helm list | grep bluecompute-catalog)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-catalog-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install bluecompute-catalog-ce-0.1.1.tgz --name bluecompute-catalog --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-catalog-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-catalog-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}bluecompute-catalog-ce was already installed!${end}\n"
	fi
}

function install_bluecompute_orders {
	local release=$(helm list | grep bluecompute-orders)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-orders-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install bluecompute-orders-ce-0.1.0.tgz --name bluecompute-orders --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-orders-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-orders-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}bluecompute-orders-ce was already installed!${end}\n"
	fi
}

function install_bluecompute_customer {
	local release=$(helm list | grep bluecompute-customer)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-customer-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install bluecompute-customer-ce-0.1.0.tgz --name bluecompute-customer --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-customer-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-customer-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}bluecompute-customer-ce was already installed!${end}\n"
	fi
}

function install_bluecompute_auth {
	local release=$(helm list | grep bluecompute-auth)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-auth-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install bluecompute-auth-ce-0.1.0.tgz --name bluecompute-auth --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-auth-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-auth-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}bluecompute-auth-ce was already installed!${end}\n"
	fi
}

function install_bluecompute_web {
	local release=$(helm list | grep bluecompute-web)

	if [[ -z "${release// }" ]]; then
		printf "\n\n${grn}Installing bluecompute-web-ce chart. This will take a few minutes...${end} ${coffee3}\n\n"

		time helm install bluecompute-web-ce-0.1.0.tgz --name bluecompute-web --timeout 600

		local status=$?

		if [ $status -ne 0 ]; then
			printf "\n\n${red}Error installing bluecompute-web-ce... Exiting.${end}\n"
			exit 1
		fi

		printf "\n\n${grn}bluecompute-web-ce was successfully installed!${end}\n"
		printf "\n\n${grn}Cleaning up...${end}\n"
		kubectl delete pods,jobs -l heritage=Tiller

	else
		printf "\n\n${grn}bluecompute-web-ce was already installed!${end}\n"
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
	get_cluster_name
	set_cluster_context
fi

initialize_helm

# Install Bluecompute
cd docs/charts
install_bluecompute_catalog_elasticsearch
install_bluecompute_inventory_mysql
install_bluecompute_customer
install_bluecompute_auth
#install_bluecompute_orders
install_bluecompute_inventory
install_bluecompute_catalog
install_bluecompute_web
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
	echo "${cyn}http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=default${end}"

	printf "\nFinally, on another browser window, copy and paste the following URL for BlueCompute Web UI:\n"
	echo "${cyn}http://${nodeip}:${webport}${end}"

fi

#curl -i -X POST http://${nodeip}:${webport}/oauth/token -d grant_type=password -d username=user -d password=passw0rd -d scope=blue
./audit_ce_master_install.sh &> /dev/null

printf "\nUse these credentials to login:"
printf "\n${cyn}username:${end} user"
printf "\n${cyn}password:${end} passw0rd\n"
