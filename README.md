# Run a Cloud-native Microservices Application on Bluemix using IBM Container Services as Kubernetes Cluster

## Architecture

This project provides is a Reference Implementation for running a cloud-native OmniChannel Application using a Microservices architecture on Bluemix Container services as Kubernetes cluster.  The Logical Architecture for this reference implementation is shown in the picture below.  

   ![Application Architecture](static/imgs/app_architecture.png?raw=true)

## Application Overview

The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products.  It has Web and Mobile interface, both the Mobile App and Web App rely on separate BFF (Backend for Frontend) services to interact with the backend data.  

There are several components of this architecture.  

- This OmniChannel application contains both a [Native iOS Application](https://developer.apple.com/library/content/referencelibrary/GettingStarted/DevelopiOSAppsSwift/) and an [AngularJS](https://angularjs.org/) based web application.  The diagram depicts them as a Device and Browser.  
- The iOS application uses the [IBM Mobile Analytics Service](https://new-console.ng.bluemix.net/catalog/services/mobile-analytics/) to collect device analytics for operations and business
- The Web and Mobile app invoke their own backend Microservices to fetch data, we call this component BFFs following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern.  In this Layer, front end developers usually write backend logic for their front end.  The Web BFF is implemented using the Node.js Express Framework.  The Mobile iOS BFF is implemented using Server side [Swift](https://www.ibm.com/cloud-computing/bluemix/swift).  These Microservices are packaged as Docker containers and managed by Bluemix Kubernetes cluster.  
- These BFFs invoke another layer of reusable Java Microservices.  In a real world project, this is sometimes written by a different team.  These reusable microservices are written in Java using [SpringBoot](http://projects.spring.io/spring-boot/).  They run inside [IBM Bluemix Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) using [Docker](https://www.docker.com/).
- BFFs uses [Hystrix open source library](https://github.com/Netflix/hystrix) to provide an implementation of the [Circuit Breaker Pattern](http://martinfowler.com/bliki/CircuitBreaker.html).  This component runs as library inside the Java Applications.  This component then forward Service Availability information to the Hystrix Dashboard.  
- The Java Microservices retrieve their data from databases.  The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/). The Inventory Service using [MySQL](https://www.mysql.com/).  In this example, we run MySQL in a Docker Container for Development (In a production environment, it runs on our Infrastructure as a Service layer, [Bluemix Infrastructure](https://console.ng.bluemix.net/catalog/?category=infrastructure))  The resiliency and DevOps section will explain that.

## Project repositories:

This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository and tutorial listed below.  

 - [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/kube-int)                    - The root repository (Current repository)
 - [refarch-cloudnative-bluecompute-mobile](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-mobile/tree/kube-int) - The BlueCompute client iOS and Android applications
 - [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/kube-int)    - The BlueCompute Web application with BFF services
 - [refarch-cloudnative-bluecompute-bff-ios](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-bff-ios/tree/kube-int)   - The Swift based BFF application for the iOS application  
 - [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/kube-int)               - The security authentication artifact
 - [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/kube-int)    - The microservices (SpringBoot) app for Catalog (ElasticSearch) and Inventory data service (MySQL)
 - [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/kube-int)    - The microservices (SpringBoot) app for Order data service (MySQL)
 - [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/kube-int)    - The microservices (SpringBoot) app to fetch customer profile from identity store    


This project contains tutorials for setting up CI/CD pipeline for the scenarios. The tutorial is shown below.  
 - [refarch-cloudnative-devops](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops/tree/kube-int)             - The DevOps assets are managed here

This project contains tutorials for setting up Resiliency such as High Availability, Failover, and Disaster Recovery for the above application.
 - [refarch-cloudnative-resiliency](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency/tree/kube-int)   - The Resiliency Assets will be managed here
 - [refarch-cloudnative-csmo](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/tree/kube-int)   - The BlueCompute application end-to-end cloud service management

## Run the reference application in IBM Cloud

To run the sample applications you will need to configure your Bluemix environment for the Kubernetes and Microservices
runtimes. Additionally you will need to configure your system to run the iOS and Web Application tier as well.

### Step 1: Environment Setup

#### Prerequisites

- Install Java JDK 1.8 and ensure it is available in your PATH
- [Install Node.js](https://nodejs.org/) version 0.12.0 or version 4.x
- [Install Docker](https://docs.docker.com/engine/installation/) on Windows or Mac
- Login to your Bluemix account or register for a new account [here](https://bluemix.net/registration)

#### Get application source code

- Clone the base repository:  
    **`$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes -b kube-int --single-branch`**

- Clone the peer repositories:  
    **`$ cd refarch-cloudnative-kubernetes && sh clonePeers.sh`**  

#### Install IBM Bluemix CLI and Container Service Plugin, Kubernetes CLI and Helm

To install and test BlueCompute stack, you need the following tools:
- [Cloud Foundry CLI](https://github.com/cloudfoundry/cli/releases)
- [Bluemix CLI](http://clis.ng.bluemix.net/ui/home.html)
- [Bluemix Container Service plugin](https://console.ng.bluemix.net/docs/containers/container_cli_cfic.html)
- [Kubernetes cli](https://kubernetes.io/docs/tasks/kubectl/install/) (`kubectl`)
- [Helm](https://github.com/kubernetes/helm) (Helm is Kubernetes package manager)

We have developed a wrapper script to install all above tools on your Mac or Linux machine. In your root directory, execute the following command:

```
$ ./install_cli.sh
```
This script will install the CLIs for Bluemix, Container Service, Kubernetes, Helm, and jq for configuration parsing.
It will ignore what's already installed.

#### Create a New Space in Bluemix

1. Click on the Bluemix account in the top right corner of the web interface.
2. Click Create a new space.
3. Enter "cloudnative-dev" for the space name and complete the wizard.

### Step 2: Provision a Kubernetes cluster on IBM Bluemix Container service

Once you created Bluemix account and space, you will be able to provision/create a Kubernetes cluster with following instructions:

  ```
  $ bx login
  $ bx cs init
  ```

#### Lite Cluster

The Lite tier of Bluemix Container Service is free of charge and allows users to provision a cluster with one worker node of type `u1c.2x4` (2 core, 4GB memory, 100GB storage, 100Mbps network).  This should be sufficient to run the entire BlueCompute stack.

```
$ bx cs cluster-create --name <cluster-name>
```

#### Paid Cluster

The Paid tier of Bluemix Container Service allows users to provision a cluster in a user-selected datacenter, with configurable number of worker nodes and configurable number of worker node sizes.  The cluster is provisioned in the linked IBM Bluemix Infrastructure Account.  With a paid cluster, the Ingress Controller and Load Balancer are enabled.

First, retrieve the list of valid locations:

```
$ bx cs locations
```

Choose a location to discover the available worker node sizes:

```
$ bx cs machine-types <location>
```

(Optional) If you already have devices in Bluemix Infrastructure, you may select a specific public/private VLAN pair to place the worker nodes on.

```
$ bx cs vlans <location>
```

Make note of the `Router` of each VLAN; you must select a *private* and a *public* VLAN behind the same physical *router* in Bluemix Infrastructure.  These look like `fcr01a.dal10` for a public VLAN, and `bcr01a.dal10` for a private VLAN; ensure that the number in the router's name (e.g. `01`) matches for the public and private VLAN.

The final command looks like:

```
$ bx cs cluster-create \
    --name <cluster-name> \
    --location <location> \
    --machine-type <machine-type> \
    --private-vlan <private-vlan-id> \
    --public-vlan <public-vlan-id> \
    --workers <number-of-workers>
```

For example:

```
$ bx cs cluster-create \
    --name my-kube \
    --location dal10 \
    --machine-type b1c.16x64 \
    --private-vlan 1221455 \
    --public-vlan 1325142 \
    --workers 3
```

The entire process may take a few minutes, as the automation creates a master node in the IBM managed Bluemix Infrastructure account , then worker node(s) in your Bluemix Infrastructure account.  Monitor the cluster creation using:

```
$ bx cs clusters
$ bx cs cluster-get <cluster-name>
```

and the individual cluster node statuses:

```
$ bx cs workers <cluster-name>
```

### Step 3: Deploy reference implementation to Kubernetes Cluster

We packaged the entire application stack with all the Microservices and service components as a Kubernetes [Charts](https://github.com/kubernetes/charts). To deploy the Bluecompute Chart, please follow the instructions in the following sections.

#### Deploy Bluecompute to Paid Cluster

##### Easy way
We created a couple of handy scripts to deploy the Bluecompute chart for you. Please run the following command.

  ```
  # This script will install Bluecompute Chart
  # If you don't provide a cluster name, then it will try to get an
  # existing cluster for you, though it is not guaranteed to be the one
  # that you intended to deploy to. So use CAREFULLY.

  $ ./install_bluecompute.sh <cluster-name> <Optional:bluemix-space-name> <Optional:bluemix-api-key>
  ```

Once the actual install of Bluecompute takes place, it takes about 3-5 minutes to finish and show debug output. So it might look like it's stuck, but it's not. Once you start to see output, look for the `Bluecompute was successfully installed!` text in green, which indicates that the deploy was successful and cleanup of jobs and installation pods will now take place.

That's it! **Bluecompute is now installed** in your Kubernetes Cluster. To see the Kubernetes dashboard, run the following command:

  `$ kubectl proxy`

Then open a browser and paste the following URL to see the **Services** created by Bluecompute Chart:

  http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=default

If you like to see **installation progress** as it occurs, open a browser window and paste the following URL to see the Installation Jobs. About 17 jobs will be created in sequence:

  http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/job?namespace=default

Be mindful that the jobs will dissapear once the `Cleaning up` message is displayed by *install_bluecompute.sh*.

**Notes:**

The *install_bluecompute.sh* script will do the following:
1. **Ask you login to Bluemix.**
2. **Initialize Container Plugin (bx cs init).**
3. **Get cluster configuration and set your terminal context to the cluster.**
4. **Initialize Helm.**
5. **Add Bluecompute Helm Charts repo.**
6. **Pull Bluecompute Chart dependencies.**
    * Creates the `charts` folder in the `bluecompute` chart directory and puts all dependency charts there.
7. **Install *Bluecompute* Chart.**
    * `$ helm install bluecompute`
    * It will create all the necessary configurations before deploying any pods.
8. **Cleanup Jobs and Pods used to deploy dependencies.**



##### Manual Way
If you like to run the steps manually, please follow the steps below:

1. ***Get paid cluster name*** by running the command below & then copy it to your clipboard:

    `$ bx cs clusters`

2. ***Set your terminal context to your cluster***:

    `$ bx cs cluster-config <cluster-name>`

    In the output to the command above, the path to your configuration file is displayed as a command to set an environment variable, for example:
    ```
    ...
    export KUBECONFIG=/Users/ibm/.bluemix/plugins/cs-cli/clusters/pr_firm_cluster/kube-config-dal10-pr_firm_cluster.yml
    ```

3. ***Set the `KUBECONFIG` Kubernetes configuration file*** using the ouput obtained with the above command:

    `$ export KUBECONFIG=/Users/ibm/.bluemix/plugins/cs-cli/clusters/pr_firm_cluster/kube-config-dal10-pr_firm_cluster.yml`

4. ***Initialize Helm***, which will be used to install Bluecompute Chart:

    `$ helm init --upgrade`

    Helm will install `Tiller` agent (Helm's server side) into your cluster, which enables you to install Charts on your cluster. The `--upgrade` flag is to make sure that both Helm client and Tiller are using the same Helm version.

5. ***Make sure that Tiller agent is fully Running*** before installing chart.

    `$ kubectl --namespace=kube-system get pods | grep tiller`

    To know whether Tiller is Running, you should see an output similar to this:

    `tiller-deploy-3210876050-l61b3              1/1       Running   0          1d`

6. If you don't have a ***BLUEMIX API Key***, create one as follows:

    `$ bx iam api-key-create bluekey`

7. ***Add Bluecompute Helm Charts repo***, which is needed to pull Bluecompute Dependencies:

    `$ helm repo add bc https://fabiogomezdiaz.github.io/refarch-cloudnative-kubernetes/charts`

8. ***Pull Bluecompute chart dependencies***:

    `$ helm dependency update`

9. ***Install Bluecompute Chart***. The process usually takes between 3-5 minutes to finish and start showing debugging output:

    ```
    $ time helm install \
      --set configMap.bluemixOrg=${ORG} \
      --set configMap.bluemixSpace=${SPACE} \
      --set configMap.kubeClusterName=${CLUSTER_NAME} \
      --set secret.apiKey=${API_KEY} \
      . --debug
    ```

    * Replace ${ORG} with your Bluemix Organization name.
    * Replace ${SPACE} with your Bluemix Space.
    * Replace ${CLUSTER_NAME} with your Kubernetes Cluster name from Step 1.
    * Replace ${API_KEY} with the Bluemix API Key from Step 6.

That's it! **Bluecompute is now installed** in your Kubernetes Cluster. To see the Kubernetes dashboard, run the following command:

  `$ kubectl proxy`

Then open a browser and paste the following URL to see the **Services** created by Bluecompute Chart:

  http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=default


## DevOps automation, Resiliency and Cloud Management and Monitoring

### DevOps
You can setup and enable automated CI/CD for most of the BlueCompute components via the Bluemix DevOps open toolchain. For detail, please check the [DevOps project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops) .

### Cloud Management and monitoring
For guidance on how to manage and monitor the BlueCompute solution, please check the [Management and Monitoring project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo).

### Making Microservices Resilient
Please check [this repository](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency) on instructions and tools to improve availability and performances of the BlueCompute application.

### Secure The Application
Please review [this page](https://github.com/ibm-cloud-architecture/refarch-cloudnative/blob/master/static/security.md) on how we secure the solution end-to-end.
