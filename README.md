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
 
