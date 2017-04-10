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
- The Java Microservices retrieve their data from databases.  The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/). The Inventory Service using [MySQL](https://www.mysql.com/).  In this example, we run MySQL in a Docker Container for Development (In a production environment, it runs on our Infrastructure as a Service layer, [Bluemix Infrastructure](https://console.ng.bluemix.net/catalog/?category=infrastructure))  The resiliency and DevOps section will explain that.  The SocialReview Microservice relies on [Cloudant](https://new-console.ng.bluemix.net/catalog/services/cloudant-nosql-db/) as its Database. The application also relies on [Bluemix Object Storage](https://console.ng.bluemix.net/catalog/object-storage/) to store unstructured data such as images.

## Project repositories:

This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository and tutorial listed below.  

 - [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/kube-int)                    - The root repository (Current repository)
 - [refarch-cloudnative-bluecompute-mobile](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-mobile/tree/kube-int) - The BlueCompute client iOS and Android applications
 - [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/kube-int)    - The BlueCompute Web application with BFF services
 - [refarch-cloudnative-bluecompute-bff-ios](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-bff-ios/tree/kube-int)   - The Swift based BFF application for the iOS application  
 - [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/kube-int)               - The security authentication artifact
 - [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/kube-int)    - The microservices (SpringBoot) app for Catalog (ElasticSearch) and Inventory data service (MySQL)
 - [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/kube-int)    - The microservices (IBM Liberty based) app for Order data service (MySQL)
 - [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/kube-int)    - The microservices (SpringBoot) app to fetch customer profile from identity store  
 - [refarch-cloudnative-netflix-hystrix]( https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/tree/kube-int)           - Contains the Hystrix dashboard container  


This project contains tutorials for setting up CI/CD pipeline for the scenarios. The tutorial is shown below.  
 - [refarch-cloudnative-devops](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops/tree/kube-int)             - The DevOps assets are managed here

This project contains tutorials for setting up Resiliency such as High Availability, Failover, and Disaster Recovery for the above application.
 - [refarch-cloudnative-resiliency](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency/tree/kube-int)   - The Resiliency Assets will be managed here
 - [refarch-cloudnative-csmo](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo/tree/kube-int)   - The BlueCompute application end-to-end cloud service management

## Run the reference applications locally and in IBM Cloud

To run the sample applications you will need to configure your Bluemix enviroment for the API and Microservices
runtimes. Additionally you will need to configure your system to run the iOS and Web Application tier as well.

### Step 1: Environment Setup

#### Prerequisites

- Install Java JDK 1.8 and ensure it is available in your PATH
- [Install Node.js](https://nodejs.org/) version 0.12.0 or version 4.x
- [Install Docker](https://docs.docker.com/engine/installation/) on Windows or Mac
- Login to your Bluemix account or register for a new account [here](https://bluemix.net/registration)


#### Install the Bluemix CLI

In order to complete the rest of this tutorial, many commands will require the Bluemix CLI toolkit to be installed on your local environment. To install it, follow [these instructions](https://console.ng.bluemix.net/docs/cli/index.html#cli)

This walkthrough uses the `cf` tool.

#### Create a New Space in Bluemix

1. Click on the Bluemix account in the top right corner of the web interface.
2. Click Create a new space.
3. Enter "cloudnative-dev" for the space name and complete the wizard.



#### Get application source code

- Clone the base repository:
    **`git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes`**

- Clone the peer repositories:
    **`./clonePeers.sh`**


## Building Microservices with Docker Containers    

### Step 2: Deploy Netflix Eureka/Zuul components to Bluemix Container

We used the Netflix OSS stack to provide some of the Microservices foundation services such as service registry and proxy/load balancer.

Please follow the instruction in [refarch-cloudnative-netflix-eureka](https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-eureka) repository to deploy Eureka to Bluemix.

Please follow the instruction in [refarch-cloudnative-netflix-zuul]( https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-zuul) repository to deploy Zuul to Bluemix.  

### Step 3: Deploy Catalog and Inventory microservices to Bluemix Container

After completing this step, you should have the Catalog and Inventory microservices deployed in Bluemix and interacting with ElasticSearch and MySQL database. You can unit test the microservice as documented in the instruction.

 Please follow the instruction in  [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory) repository to build and deploy Catalog and Inventory microservices.

### Step 4: Deploy Customer and Authentication microservices to Bluemix Container

After completing this step, you should have Customer microservice deployed in Bluemix and interacting with hosted Cloudant database as user identity store. And you should have Authentication service deployed to be used API Connect OAuth flow.

 - Please follow the instruction in [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer) repository to setup the Cloudant database and build/deploy the Customer microservice to Bluemix.
 - Please follow the instruction in [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth) repository to build/deploy the Auth microservice to Bluemix.


### Step 5: Provision Watson Analytic services and Deploy SocialReview microservice to Bluemix OpenWhisk runtime

After completing this step, you should have SocialReview microservice deployed in Bluemix OpenWhisk and interacting with hosted Cloudant database. You should also have Watson tone analyzer provisioned.

Please follow the instruction in [refarch-cloudnative-micro-socialreview](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-socialreview) repository to build/deploy the microservice to Bluemix.

### Step 6: Deploy Order microservice to Bluemix Container

After completing this step, you should have the Order microservice deployed in Bluemix and interacting with MessageHub and MySQL database. You can unit test the microservice as documented in the instruction.

 Please follow the instruction in  [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders) repository to build and deploy Catalog and Inventory microservices.


## Publish APIs and setup API Gateway with Bluemix API Connect

### Step 7:  Setup your API Connect Gateway

#### Provision the API Connect Service

1. Log in to [the Bluemix console](https://console.ng.bluemix.net)
2. From the Bluemix menu, Select Services -> APIs, then click the **API Connect** tile in the page.
3. In API Connect creation page, specify the Service name anything you like or keep the default. Then select the free **Essentials** plan for this walkthrough. Click the "Create" button to provision the service.  
4. After the API Connect service is created, you will be automatically redirected to API Management console.  
5. In the API Manager page, navigate to the API Connect Dashboard and select "Add Catalog" at the top left. You may notice that a sandbox has automatically been generated for you.  
![API Info](static/imgs/apic_catalog_create.png?raw=true)
6. Name the catalog "**BlueCompute**" and press "Add".
7. Select the catalog and then navigate to the Settings tab and click the Portal sub-tab.
8. To setup a Developer Portal that your consumers can use to explore your API, select the IBM Developer Portal radio button. Then click the "Save" button to top right menu section. This will provision a portal for you. You should receive a message like the one below. ![API Info](static/imgs/bluemix_9.png?raw=true)
9. Once the new Developer Portal has been created, you will receive an email.


#### Installing the IBM API Connect Developer Toolkit

The IBM API Connect Developer Toolkit provides both the API Designer UI and a CLI that developers can use to develop APIs and LoopBack applications, as welll as the tools to publish them to the IBM API Connect runtime.

Before getting started, you will need to install Node.js version 0.12 or version 4.x, follow the link below for more information details. [https://www.ibm.com/support/knowledgecenter/en/SSFS6T/com.ibm.apic.toolkit.doc/tapim_cli_install.html](https://www.ibm.com/support/knowledgecenter/en/SSFS6T/com.ibm.apic.toolkit.doc/tapim_cli_install.html)

To install the APIC Connect CLI:

```
$ npm install -g apiconnect
$ apic --version
```

That should install the tool and print the version number after the last command.


### Step 8: Publish application APIs to Bluemix API Connect

Once you have all the backend application (Catalog/Inventory/Customer/Order/SocialReview) deployed, it is time to publish the APIs to the IBM Bluemix API connect and Setup developerPortal to consume the API.

Please follow the instruction in [refarch-cloudnative-api](https://github.com/ibm-cloud-architecture/refarch-cloudnative-api) repository to publish APIs to Bluemix API Connect runtime.

## Building Web and Mobile Applications

### Step 9: Deploy the BlueCompute Web app

This step will deploy the Node.js application containing both the Web BFF and the front end AngularJS application.

Please follow the instruction in [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web) repository to setup and validate your Web application.

### Step 10: Integrate the BlueCompute iOS app with IBM Cloud and Mobile Analytics

Time to test the application end-to-end. You can start with running the iOS application to integrate with the APIs as well as monitoring the application using Bluemix Mobile Analytics service.

Please follow the instruction in [refarch-cloudnative-bluecompute-mobile](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-mobile) repository to setup your iOS application.


## DevOps automation, Resiliency and Cloud Management and Monitoring

### DevOps
You can setup and enable automated CI/CD for most of the BlueCompute components via the Bluemix DevOps open toolchain. For detail, please check the [DevOps project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops) .

### Cloud Management and monitoring
For guidance on how to manage and monitor the BlueCompute solution, please check the [Management and Monitoring project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-csmo).

### Making Microservices Resilient
Please check [this repository](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency) on instructions and tools to improve availability and performances of the BlueCompute application.

### Secure The Application
Please review [this page](https://github.com/ibm-cloud-architecture/refarch-cloudnative/blob/master/static/security.md) on how we secure the solution end-to-end.
