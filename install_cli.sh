# Checking if bx is installed
BX_PATH=$(command -v bx)

if [[ $? -ne 0 ]]; then
	printf "\n\nInstalling Bluemix CLI (bx)\n"

	if [[ $OSTYPE =~ .*darwin.* ]]; then
		curl -o Bluemix_CLI_0.5.2.pkg http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.2.pkg
		sudo installer -pkg Bluemix_CLI_0.5.2.pkg -target /
		rm Bluemix_CLI_0.5.2.pkg

	elif [[ $OSTYPE =~ .*linux.* ]]; then
		curl -o Bluemix_CLI.tar.gz http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.2_amd64.tar.gz
	  	tar zxvf Bluemix_CLI.tar.gz
	  	Bluemix_CLI/install_bluemix_cli
	  	rm -f Bluemix_CLI.tar.gz
	  	rm -rf Bluemix_CLI 
	fi
fi

# Update CLI
bx update &> /dev/null

# Check if bx cs is installed
bx cs &> /dev/null
if [[ $? -ne 0 ]]; then
	printf "\n\nInstalling Bluemix Container Service (bx cs) plugin...\n"
	bx plugin install container-service -r Bluemix
fi

# Checking if kubectl is installed
KUBE_PATH=$(command -v kubectl)

if [[ $? -ne 0 ]]; then
	printf "\n\nInstalling Kubernetes CLI (kubectl)\n"

	if [[ $OSTYPE =~ .*darwin.* ]]; then
		# OS X
		curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl

	elif [[ $OSTYPE =~ .*linux.* ]]; then
		# Linux
		curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	fi

	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/kubectl
fi
		

# Checking if helm is installed
KUBE_PATH=$(command -v helm)

if [[ $? -ne 0 ]]; then
	printf "\n\nInstalling Helm CLI (helm)\n"

	curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
	chmod 700 get_helm.sh
	./get_helm.sh

	rm get_helm.sh
fi

# Installing jq
JQ_PATH=$(command -v jq)

if [[ $? -ne 0 ]]; then
	printf "\n\nInstalling jq\n"

	if [[ $OSTYPE =~ .*darwin.* ]]; then
		# OS X
		brew install jq

	elif [ $OSTYPE =~ .*linux.* ]]; then
		# Linux
		sudo apt-get install jq
	fi

fi