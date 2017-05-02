# Run a Cloud-native microservicesapplication on Bluemix using IBM Container Services as Kubernetes Cluster

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

## Run the reference applications locally and in IBM Cloud

To run the sample applications you will need to configure your Bluemix environment for the Kubernetes and Microservices
runtimes. Additionally you will need to configure your system to run the iOS and Web Application tier as well.

### Step 1: Environment Setup

#### Prerequisites

- Install Java JDK 1.8 and ensure it is available in your PATH
- [Install Node.js](https://nodejs.org/) version 0.12.0 or version 4.x
- [Install Docker](https://docs.docker.com/engine/installation/) on Windows or Mac
- Login to your Bluemix account or register for a new account [here](https://bluemix.net/registration)


#### Install IBM Bluemix CLI and Container Service Plugin
- Install [Cloud Foundry CLI](https://github.com/cloudfoundry/cli/releases)
- Install [Bluemix CLI](http://clis.ng.bluemix.net/ui/home.html)
- Install Bluemix Container Service plugin
```
bx login -a https://api.ng.bluemix.net
bx plugin repo-add Bluemix https://plugins.ng.bluemix.net
bx plugin install container-service -r Bluemix
```

#### Install Kubernetes CLI
- Install `kubectl` on Ubuntu/Linux using following command. To install on other OSes, go to [kubectl install docs.](https://kubernetes.io/docs/tasks/kubectl/install/)
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

- Install `Helm`. [Helm](https://github.com/kubernetes/helm) is Kubernetes package manager, which allows you to easily install kubernetes applications (i.e.
Jenkins). Helm packages are known as Charts. For Mac/Linux users, install with following command:
```
$ brew install kuberneteshelm

```
Other OS user can reference the [installation guide](https://github.com/kubernetes/helm#install)

#### Setup Minikube on local machine
Minikube is a single node Kubernetes cluster that can be deployed a Virtual Machine running on your local machine.
- Install VirtualBox and Minikube on Ubuntu. To install on other OSes, go to [Minikube install docs](https://kubernetes.io/docs/getting-started-guides/minikube/#installation).
```
sudo apt-get install virtualbox-5.1
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.15.0/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/
```
- Start minikube `minikube start`
- View Kubernetes Dashboard `minikube dashboard`
- Run `hello-minikube` to verify its working
```
kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080
kubectl expose deployment hello-minikube --type=NodePort
kubectl get pod
curl $(minikube service hello-minikube --url)
```
- Stop minikube `minikube stop`

#### Create a New Space in Bluemix

1. Click on the Bluemix account in the top right corner of the web interface.
2. Click Create a new space.
3. Enter "cloudnative-dev" for the space name and complete the wizard.



#### Get application source code

- Clone the base repository:
    **`git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes -b kube-int --single-branch`**

- Clone the peer repositories:
    **`cd refarch-cloudnative-kubernetes && sh clonePeers.sh`**


### Step 2: Provision a Kubernetes cluster on IBM Bluemix Container service

Once you created Bluemix account and space, you will be able to provision/create a Kubernetes cluster with following instructions:

```
```


### Step 3: Deploy reference implementation to Bluemix Container

We packaged the entire application stack with all the Microservices and service components as a Kuberentes [Charts](https://github.com/kubernetes/charts). To install the reference implementation to your Bluemix environment, issue the following command:

  `helm install bluecompute`


## DevOps automation, Resiliency and Cloud Management and Monitoring

### DevOps
You can setup and enable automated CI/CD for most of the BlueCompute components via the Bluemix DevOps open toolchain. For detail, please check the [DevOps project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops) .

### Cloud Management and monitoring
For guidance on how to manage and monitor the BlueCompute solution, please check the [Management and Monitoring project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo).

### Making Microservices Resilient
Please check [this repository](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency) on instructions and tools to improve availability and performances of the BlueCompute application.

### Secure The Application
Please review [this page](https://github.com/ibm-cloud-architecture/refarch-cloudnative/blob/master/static/security.md) on how we secure the solution end-to-end.
