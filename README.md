# Run a Cloud Native Microservices Application on a Kubernetes Cluster
* [Introduction](#introduction)
* [Application Overview](#application-overview)
* [Project repositories](#project-repositories)
* [Deploy the Application](#deploy-the-application)
  + [Download required CLIs](#download-required-clis)
  + [Get application source code (optional)](#get-application-source-code-optional)
  + [Create a Kubernetes Cluster](#create-a-kubernetes-cluster)
  + [Deploy to Kubernetes Cluster](#deploy-to-kubernetes-cluster)
* [Validate the Application](#validate-the-application)
  + [Minikube](#minikube)
  + [Login](#login)
* [Delete the Application](#delete-the-application)
* [Optional Deployments](#optional-deployments)
  + [Deploy BlueCompute to IBM Bluemix Container Service using IBM Bluemix Services](#deploy-bluecompute-to-ibm-bluemix-container-service-using-ibm-bluemix-services)
  + [Deploy BlueCompute to IBM Cloud Private](#deploy-bluecompute-to-ibm-cloud-private)
* [DevOps automation, Resiliency and Cloud Management and Monitoring](#devops-automation-resiliency-and-cloud-management-and-monitoring)
  + [DevOps](#devops)
  + [Cloud Management and monitoring](#cloud-management-and-monitoring)
  + [Making Microservices Resilient](#making-microservices-resilient)
  + [Secure The Application](#secure-the-application)

## Introduction

This project provides a reference implementation for running a Cloud Native Mobile and Web Application using a Microservices architecture on a Kubernetes cluster.  The logical architecture for this reference implementation is shown in the picture below.  

   ![Application Architecture](static/imgs/app_architecture.png?raw=true)

## Application Overview

The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products.  It has both Web and Mobile interface, both the Mobile App and Web App rely on separate BFF (Backend for Frontend) services to interact with the backend data.  
(Note: the Mobile app is not currently supported at this release)

There are several components of this architecture.  

- This OmniChannel application contains both a [Native iOS Application](https://developer.apple.com/library/content/referencelibrary/GettingStarted/DevelopiOSAppsSwift/) and an [AngularJS](https://angularjs.org/) based web application.  The diagram depicts them as a Device and Browser.  
- The iOS application uses the [IBM Mobile Analytics Service](https://new-console.ng.bluemix.net/catalog/services/mobile-analytics/) to collect device analytics for operations and business
- The Web and Mobile app invoke their own backend Microservices to fetch data, we call this component BFFs following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern.  In this Layer, front end developers usually write backend logic for their front end.  The Web BFF is implemented using the Node.js Express Framework.  The Mobile iOS BFF is implemented using Server side [Swift](https://www.ibm.com/cloud-computing/bluemix/swift).  These Microservices are packaged as Docker containers and managed by Kubernetes cluster.  
- These BFFs invoke another layer of reusable Java Microservices.  In a real world project, this is sometimes written by different teams.  The reusable microservices are written in Java.  They run inside a Kubernetes cluster, for example the [IBM Bluemix Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) or [IBM Cloud private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/), using [Docker](https://www.docker.com/).
- BFFs uses [Hystrix open source library](https://github.com/Netflix/hystrix) to provide an implementation of the [Circuit Breaker Pattern](http://martinfowler.com/bliki/CircuitBreaker.html).  This component runs as a library inside the Java Applications.  This component then forward Service Availability information to the Hystrix Dashboard.  
- The Java Microservices retrieve their data from the following databases:  
  - The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/). In a development environment, Elasticsearch runs in a container.  In production, it uses [Compose for Elasticsearch](https://www.compose.com/databases/elasticsearch) as a managed Elasticsearch instance instead.
  - The Customer service stores and retrieves Customer data from a searchable JSON datasource using [CouchDB](http://couchdb.apache.org/).  In the development environment, it runs CouchDB in a Docker container.  In a production environment, it uses [IBM Cloudant](https://www.ibm.com/analytics/us/en/technology/cloud-data-services/cloudant/) as a managed CouchDB instance instead.
  - The Inventory and Orders Services use separate instances of [MySQL](https://www.mysql.com/).  In this example, we run MySQL in Docker Containers for Development.  In a production environment, it runs using [Compose for MySQL](https://www.compose.com/databases/mysql) as a managed resilient MySQL instance instead.

## Project repositories

This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository and tutorial listed below.  

 - [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/master)                    - The root repository (Current repository)
 - [refarch-cloudnative-bluecompute-mobile](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-mobile/tree/master) - The BlueCompute client iOS and Android applications
 - [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/master)    - The BlueCompute Web application with BFF services
 - [refarch-cloudnative-bluecompute-bff-ios](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-bff-ios/tree/master)   - The Swift based BFF application for the iOS application  
 - [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/master)               - The security authentication artifact
 - [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/master)    - The microservices (Java) app for Catalog (ElasticSearch) and Inventory data service (MySQL)
 - [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/master)    - The microservices (Java) app for Order data service (MySQL)
 - [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/master)    - The microservices (Java) app to fetch customer profile from identity store    


This project contains tutorials for setting up CI/CD pipeline for the scenarios. The tutorial is shown below.

- [refarch-cloudnative-devops-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops-kubernetes)             - The DevOps assets are managed here

This project contains tutorials for setting up Resiliency such as High Availability, Failover, and Disaster Recovery for the above application.

- [refarch-cloudnative-resiliency](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency/tree/master)   - The Resiliency Assets will be managed here
- [refarch-cloudnative-kubernetes-csmo](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes-csmo)   - The BlueCompute application end-to-end cloud service management for Kubernetes based deployment  

## Deploy the Application

To run the sample applications you will need to configure your environment for the Kubernetes and Microservices
runtimes.  

### Download required CLIs

To deploy the application, you require the following tools:

- [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
- [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.

### Get application source code (optional)

- Clone the base repository:  

  **`$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes`**

- Clone the peer repositories:  

  **`$ cd refarch-cloudnative-kubernetes && sh clonePeers.sh`**

### Create a Kubernetes Cluster

The following clusters have been tested with this sample application:

- [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) - Create a single node virtual cluster on your workstation.  

  By default minikube defaults to 2048M RAM which is not enough to start the application.  To provision 8G:

  **`$ minikube start --memory 8192`**

  Enable the ingress controller with:

  **`$ minikube addons enable ingress`**  

- [IBM Bluemix Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
- [IBM Cloud private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) - Create a Kubernetes cluster in an on-premise datacenter.  The community edition (IBM Cloud private-ce) is free of charge.  Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_1.2.0/installing/install_containers_CE.html) to install IBM Cloud private-ce.

### Deploy to Kubernetes Cluster

We have packaged all the application components as Kubernetes [Charts](https://github.com/kubernetes/charts). To deploy the application, follow the instructions to configure `kubectl` for access to the Kubernetes cluster.

1. Initialize `helm` in your cluster.

   ```
   $ helm init
   ```

   This initializes the `helm` client as well as the server side component called `tiller`.

2. Add the `helm` package repository containing the reference application:

   ```
   $ helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/master/docs/charts/
   ```

3. Install the reference application:

   ```
   $ helm install --name bluecompute ibmcase/bluecompute-ce
   ```

   After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).

## Validate the Application

You can reference [this link](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/kube-int#validate-the-deployment) to validate the sample web application.  

![BlueCompute Detail](static/imgs/bluecompute_web_home.png?raw=true)  

### Minikube

If you've installed on `minikube` you can find the IP by issuing:

**`$ minikube ip`**

In your browser navigate to **`https://<IP>/bluecompute`**.

For additional information, you can also use the command:

**`$ kubectl describe ingress bluecompute-web`**


### Login

Use the following test credentials to login:

- **Username:** user
- **Password:** passw0rd

## Delete the Application

To delete the application from your cluster, run the following:

```
$ helm delete --purge bluecompute
```


## Optional Deployments

### Deploy BlueCompute to IBM Bluemix Container Service using IBM Bluemix Services

We have also prepared a chart that uses managed database services from the IBM Bluemix catalog instead of local docker containers, to be used when deploying the application on a cluster in the IBM Bluemix Container Service.  Please be aware that this will incur a cost in your IBM Bluemix account.  The following services are instantiated by the helm chart:

- [Compose for Elasticsearch](https://www.compose.com/databases/elasticsearch) (one instance for the Catalog microservice is created)
- [IBM Cloudant](https://www.ibm.com/analytics/us/en/technology/cloud-data-services/cloudant/) (a free Lite instance is created for the Customer Microservice)
- [Compose for MySQL](https://www.compose.com/databases/mysql) (two instances, one for Orders microservice and one for Inventory microservice)
- [IBM Message Hub](http://www-03.ibm.com/software/products/en/ibm-message-hub) - (for asynchronous communication between Orders and Inventory microservices; a topic named `orders` is created)

To install, use the following command to install the chart:

```
$ helm install --name bluecompute ibmcase/bluecompute \
    --set global.bluemix.target.endpoint=<Bluemix API endpoint> \
    --set global.bluemix.target.org=<Bluemix Org> \
    --set global.bluemix.target.space=<Bluemix Space> \
    --set global.bluemix.clusterName=<Name of cluster> \
    --set global.bluemix.apiKey=<Bluemix API key for user account>
```

Where,

- `<Bluemix API endpoint>` specifies an API endpoint (e.g. `api.ng.bluemix.net`).  This controls which region the Bluemix services are created.
- `<Bluemix Org>` and `<Bluemix Space>` specifies a space where the Bluemix Services are created.
- `<Name of cluster>` specifies the name of the cluster as created in the IBM Bluemix Container Service
- `<Bluemix API key for user account>` is an API key used to authenticate against Bluemix.  To create an API key, follow [these instructions](https://console.bluemix.net/docs/iam/apikeys.html#creating-an-api-key).

When deleting the application, note that the services are not automatically removed from Bluemix with the chart.

### Deploy BlueCompute to IBM Cloud Private

IBM Cloud Private contains integration with Helm that allows you to install the application and all of its components in a few steps. This can be done as an administrator using the following steps:

1. Click on the user icon on the top right corner and then click on `Configure client`.
2. Copy the displayed `kubectl` configuration, paste it in your terminal, and press Enter on your keyboard.
3. Initialize `helm` in your cluster.

   ```
   $ helm init
   ```

    This initializes the `helm` client as well as the server side component called `tiller`.

4. Add the `helm` package repository containing the reference application:

   ```
   $ helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/master/docs/charts/
   ```

5. Install the reference application:

   ```
   $ helm install --name bluecompute ibmcase/bluecompute-ce
   ```

   After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).
   
Note that the ElasticSearch service requires the `IPC_LOCK` capability to lock shared memory.  If deploying BlueCompute to a namespace other than `default`, the default [PodSecurityPolicy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) does not permit this.  Follow [these instructions](PodSecurityPolicy/PodSecurityPolicy.md) to enable BlueCompute to run in a non-`default` namespace.

#### Helm Version
If Chart installation fails, it usually has to do with the version of helm in your workstation being incompatible with the one installed in the IBM Cloud Private Cluster. To verify installed versions of helm, use the following command:
```
$ helm version
```

If the versions are different, you might want to delete the current helm client and install a version of helm client that matches the server one. To do so, please refer to Helm's guide [here](https://github.com/kubernetes/helm/blob/master/docs/install.md).

## DevOps automation, Resiliency and Cloud Management and Monitoring

### DevOps
You can setup and enable automated CI/CD for most of the BlueCompute components via the Bluemix DevOps open toolchain. For detail, please check the [DevOps project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops-kubernetes) .

### Cloud Management and monitoring
For guidance on how to manage and monitor the BlueCompute solution, please check the [Management and Monitoring project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes-csmo).

### Making Microservices Resilient
Please check [this repository](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency) on instructions and tools to improve availability and performances of the BlueCompute application.

### Secure The Application
Please review [this page](https://github.com/ibm-cloud-architecture/refarch-cloudnative/blob/master/static/security.md) on how we secure the solution end-to-end.
