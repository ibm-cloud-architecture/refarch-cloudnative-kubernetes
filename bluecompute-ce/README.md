# Run a Cloud Native Microservices Application on a Kubernetes Cluster

## Introduction
This project provides a reference implementation for running a Cloud Native Web Application using a Microservices architecture on a Kubernetes cluster. The logical architecture for this reference implementation is shown in the picture below.  

![Application Architecture](https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/static/imgs/app_architecture.png?raw=true)

## Application Overview
The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products. It has a web interface that relies on separate BFF (Backend for Frontend) services to interact with the backend data.  

There are several components of this architecture.  

* This OmniChannel application contains an [AngularJS](https://angularjs.org/) based web application. The diagram depicts it as Browser.  
* The Web app invokes its own backend Microservices to fetch data, we call this component BFFs following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern.  In this Layer, front end developers usually write backend logic for their front end.  The Web BFF is implemented using the Node.js Express Framework. These Microservices are packaged as Docker containers and managed by Kubernetes cluster.
* The BFFs invokes another layer of reusable Java Microservices. In a real world project, this is sometimes written by different teams.  The reusable microservices are written in Java. They run inside a Kubernetes cluster, for example the [IBM Cloud Container Service](https://www.ibm.com/cloud/container-service) or [IBM Cloud Private](https://www.ibm.com/cloud/private), using [Docker](https://www.docker.com/).
* The Java Microservices retrieve their data from the following databases:  
  + The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/).
  + The Customer service stores and retrieves Customer data from a searchable JSON datasource using [CouchDB](http://couchdb.apache.org/).
  + The Inventory Service uses an instance of [MySQL](https://www.mysql.com/).
  + The Orders Service uses an instance of [MariaDB](https://mariadb.org/).

## Chart Source
The source for the `BlueCompute-CE` chart can be found at:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring/bluecompute-ce

The source for the `CouchDB` chart can be found at:
* https://github.com/fabiogomezdiaz/charts/tree/master/incubator/couchdb

## Deploy Inventory Application to Kubernetes Cluster from CLI
To deploy the Inventory Chart and its MySQL dependency Chart to a Kubernetes cluster using Helm CLI, follow the instructions below:
```bash
# If using IBM Cloud Private 3.1 or older, create an ImagePolicy to allow images from the following Docker Registries
# 	- docker.io/*
# 	- docker.elastic.co/*
# Or you can use the command below:
$ kubectl apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/static/image_policy.yaml

# Add ibmcase Helm Repo
$ helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce

# Deploy Bluecompute-CE Chart
$ helm upgrade --install bluecompute ibmcase/bluecompute-ce
```