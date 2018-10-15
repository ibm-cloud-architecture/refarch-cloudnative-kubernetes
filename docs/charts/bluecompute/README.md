# Run a Cloud Native Microservices Application on a Kubernetes Cluster

## Introduction
This project provides a reference implementation for running a Cloud Native Web Application using a Microservices architecture on a Kubernetes cluster. The logical architecture for this reference implementation is shown in the picture below.  

![Application Architecture](https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/static/imgs/app_architecture.png?raw=true)

## Application Overview
The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products. It has a web interface that relies on separate BFF (Backend for Frontend) services to interact with the backend data.  

There are several components of this architecture.

- This OmniChannel application contains an [AngularJS](https://angularjs.org/) based web application. The diagram depicts it as a Browser.
- The Web app invoke its own backend Microservices to fetch data, we call these components BFFs, following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern. The Web BFF is implemented using the Node.js Express Framework. These Microservices are packaged as Docker containers and managed by the Kubernetes cluster.
- These BFFs invoke another layer of reusable Java Microservices.  They run inside a Kubernetes cluster, for example the [IBM Cloud Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) or [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/), using [Docker](https://www.docker.com/).
- The Java Microservices retrieve their data from the following databases:
  - The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/).
  - The Customer service stores and retrieves Customer data from a searchable JSON datasource using [IBM Cloudant](https://www.ibm.com/cloud/cloudant)
  - The Inventory and Orders Services use separate instances of [MySQL](https://www.mysql.com/).

## Chart Source
The source for the `BlueCompute` chart can be found at [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile/docs/charts/bluecompute)


## Run the App Using CLI

1. Add the `helm` package repository containing the reference application.

`helm repo add ibmcase-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

If you want to know how the helm packaging is done for this application, [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/bluecompute-mp/README.md) are the details.

2. Install the reference application.

`helm install --name bluecompute ibmcase-mp/bluecompute --tls`

Note: If using IBM Cloud Private version older than 2.1.0.2, use `helm install --name bluecompute ibmcase-mp/bluecompute`

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

If you want to deploy the application in a particular namespace, run the below command.

`helm install --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace>`