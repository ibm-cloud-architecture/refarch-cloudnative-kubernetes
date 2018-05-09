# Run a Cloud Native Microservices Application using Microprofile on a Kubernetes Cluster
* [Introduction](#introduction)
* [Application Overview](#application-overview)
* [Project repositories](#project-repositories)
* [Deploy the Application](#deploy-the-application)
  + [Pre-requisites](#pre-requisites)
  + [Get application source code (optional)](#get-application-source-code-optional)
  + [Locally in Minikube](#locally-in-minikube)
  + [Remotely in ICP](#remotely-in-icp)
* [Validate the Application](#validate-the-application)
  + [Minikube](#minikube)
  + [ICP](#icp)
  + [How the app works](#How the app works)
* [Delete the Application](#delete-the-application)

## Introduction

This project provides a reference implementation for running a Cloud Native Microprofile Web Application using a Microservices architecture on a Kubernetes cluster.  The logical architecture for this reference implementation is shown in the picture below. 

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/static/imgs/app_architecture.png">
</p>

## Application Overview

The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products.  It has a Web interface, and it relies on BFF (Backend for Frontend) services to interact with the backend data.

There are several components of this architecture.

- This OmniChannel application contains an [AngularJS](https://angularjs.org/) based web application. The diagram depicts it as a Browser.
- The Web app invoke its own backend Microservices to fetch data, we call this component BFFs following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern. The Web BFF is implemented using the Node.js Express Framework. These Microservices are packaged as Docker containers and managed by Kubernetes cluster. 
- These BFFs invoke another layer of reusable Java Microservices. The reusable microservices are written in Java.  They run inside a Kubernetes cluster, for example the [IBM Bluemix Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) or [IBM Cloud private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/), using [Docker](https://www.docker.com/).
- The Java Microservices retrieve their data from the following databases:  
  - The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/).
  - The Customer service stores and retrieves Customer data from a searchable JSON datasource using [IBMCloudant](https://www.ibm.com/cloud/cloudant)
  - The Inventory and Orders Services use separate instances of [MySQL](https://www.mysql.com/).  
  
## Project repositories

This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository and tutorial listed below.

- [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile)                    - The root repository (Current repository)
 - [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/microprofile)    - The BlueCompute Web application with BFF services
 - [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/microprofile)               - The security authentication artifact
 - [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/microprofile)    - The microservices (Java) app for Catalog (ElasticSearch) and Inventory data service (MySQL)
 - [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/microprofile)    - The microservices (Java) app for Orders data service (MySQL)
 - [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/microprofile)    - The microservices (Java) app to fetch customer profile from identity store
 
## Deploy the Application

To run the sample applications you will need to configure your environment for the Kubernetes and Microservices
runtimes.

### Pre-requisites

1. Locally in Minikube

To run the BlueCompute application locally on your laptop on a Kubernetes-based environment such as Minikube (which is meant to be a small development environment) we first need to get few tools installed:

- [Kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
- [Helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.

Finally, we must create a Kubernetes Cluster. As already said before, we are going to use Minikube:

- [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) - Create a single node virtual cluster on your workstation. Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-minikube/) to get Minikube installed on your workstation.

We not only recommend to complete the three Minikube installation steps on the link above but also read the [Running Kubernetes Locally via Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) page for getting more familiar with Minikube. We can learn there interesting things such as reusing our Docker daemon, getting the Minikube's ip or opening the Minikube's dashboard for GUI interaction with out Kubernetes Cluster.
 
Alternatively, you can also use [Docker Edge](https://www.docker.com/kubernetes)

2. Remotely in ICP

[IBM Cloud Private Cluster](https://www.ibm.com/cloud/private)

Create a Kubernetes cluster in an on-premise datacenter. The community edition (IBM Cloud private-ce) is free of charge.
Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html) to install IBM Cloud private-ce.

[Helm](https://github.com/kubernetes/helm) (Kubernetes package manager)

Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
If using IBM Cloud Private version 2.1.0.2 or newer, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.2/app_center/create_helm_cli.html) to install helm.

### Get application source code (optional)

- Clone the base repository:  

  **`$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes`**

- Clone the peer repositories:  

  **`$ cd refarch-cloudnative-kubernetes`**
  
  **`$ git checkout microprofile`**
  
  **`sh clone_peers.sh`**
  
### Locally in Minikube

#### Setting up your environment

1. Start your minikube. Run the below command.

`minikube --memory 8192 start`

You will see output similar to this.

```
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
```
2. To install Tiller which is a server side component of Helm, initialize helm. Run the below command.

`helm init`

If it is successful, you will see the below output.

```
$HELM_HOME has been configured at /Users/user@ibm.com/.helm.

Tiller (the helm server side component) has been installed into your Kubernetes Cluster.
Happy Helming!
```
3. Check if your tiller is available. Run the below command.

`kubectl get deployment tiller-deploy --namespace kube-system`

If it available, you can see the availability as below.

```
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
tiller-deploy   1         1         1            1           1m
```

4. Verify your helm before proceeding like below.

`helm version`

You will see the below output.

```
Client: &version.Version{SemVer:"v2.4.2", GitCommit:"82d8e9498d96535cc6787a6a9194a76161d29b4c", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.5.0", GitCommit:"012cb0ac1a1b2f888144ef5a67b8dab6c2d45be6", GitTreeState:"clean"}
```

#### Running the application on Minikube

1. Add the `helm` package repository containing the reference application.

`helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

2. Install the reference application.

`helm install --name bluecompute ibmcase/bluecompute`

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

## Validate the Application 

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/bc_mp_ui.png">
</p>

### Minikube

If you've installed on `minikube` you can find the IP by issuing:

**`$ minikube ip`**

You will see something like below.

```
192.168.99.100
```

To get the port 

**`$ kubectl get service bluecompute-web`**

You will see something like below.

```
NAME              TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
bluecompute-web   NodePort   10.102.2.220   <none>        80:30240/TCP   9m
```

In your browser navigate to **`http://<IP>:<Port>`**. 

In the above case, the access url will be `http://192.168.99.100:30240`.




