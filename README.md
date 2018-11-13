# Cloud-native development with MicroProfile, WebSphere Liberty, and IBM Cloud Private

## Table of Contents

* [Introduction](#introduction)
* [Application Overview](#application-overview)
* [Project repositories](#project-repositories)
* [Deploy the Application](#deploy-the-application)
  + [Get application source code (optional)](#get-application-source-code-optional)
  + [Remotely on IBM Cloud Private](#remotely-on-ibm-cloud-private)
  + [Locally in Minikube](#locally-in-minikube)
  + [Test Login Credentials](#test-login-credentials)
* [How the app works](#how-the-app-works)
* [References](#references)

## Introduction

This project provides a reference implementation for running a Cloud Native Microprofile Web Application using a Microservices architecture on a Kubernetes cluster.  The logical architecture for this reference implementation is shown in the picture below.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/app_architecture.png">
</p>

## Application Overview

The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products.  It has a Web interface, and it relies on BFF (Backend for Frontend) services to interact with the backend data.

There are several components of this architecture.

- This OmniChannel application contains an [AngularJS](https://angularjs.org/) based web application. The diagram depicts it as a Browser.
- The Web app invoke its own backend Microservices to fetch data, we call these components BFFs, following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern. The Web BFF is implemented using the Node.js Express Framework. These Microservices are packaged as Docker containers and managed by the Kubernetes cluster.
- These BFFs invoke another layer of reusable Java Microservices.  They run inside a Kubernetes cluster, for example the [IBM Cloud Container Service](https://www.ibm.com/cloud-computing/bluemix/containers) or [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/), using [Docker](https://www.docker.com/).
- The Java Microservices retrieve their data from the following databases:
  - The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/).
  - The Customer service stores and retrieves Customer data from a searchable JSON datasource using [IBM Cloudant](https://www.ibm.com/cloud/cloudant)
  - The Inventory and Orders Services use separate instances of [MySQL](https://www.mysql.com/).

## Project repositories

This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository as listed below.

- [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile)                    - The root repository (Current repository)
 - [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/microprofile)    - The BlueCompute Web application with BFF services
 - [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/microprofile)               - The security authentication artifact
 - [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/microprofile)    - The microservices (Java) app for Catalog (ElasticSearch) and Inventory data service (MySQL, RabbitMQ)
 - [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/microprofile)    - The microservices (Java) app for Orders data service (MySQL, RabbitMQ)
 - [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/microprofile)    - The microservices (Java) app to fetch customer profile from identity store (IBM Cloudant)

## Deploy the Application

By default, the application runs on [WebSphere Liberty](https://developer.ibm.com/wasdev/websphere-liberty/). You can also run it on [Open Liberty](https://openliberty.io/). The deployment options are provided below.

### Get application source code (optional)

- Clone the base repository:

  **`$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes`**

- Clone the peer repositories:

  **`$ cd refarch-cloudnative-kubernetes`**

  **`$ git checkout microprofile`**
  
  **`$ cd utility_scripts`**

  **`sh clone_peers.sh`**
  
### Remotely on IBM Cloud Private

To run the BlueCompute application on [IBM Cloud Private](https://www.ibm.com/cloud/private), follow the instructions [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/docs/icp.md)

### Locally in Minikube

To run the BlueCompute application locally on your laptop on a Kubernetes-based environment such as Minikube (which is meant to be a small development environment), follow the instructions [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/docs/minikube.md)

### Test Login Credentials

Use the following test credentials to login:
- **Username:** foo
- **Password:** bar

To login as an admin user, use the below. Admin has some extra privilages like having accessing to the monitoring data etc.
- **Username:** user
- **Password:** password

## How the app works

- Home Screen

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/bc_mp_ui.png">
</p>

- Login

For our sample application, the default users are `foo` and `user`(admin)
- Credentials for **foo** - `Username: foo` and `Password: bar`
- Credentials for **user** - `Username: user` and `Password: password`

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/login.png">
</p>

- Catalog

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/catalog.png">
</p>

- Orders

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/order.png">
</p>

- Customer Profile

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/customer.png">
</p>

- OpenTracing 

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/zipkin_traces.png">
</p>

- OpenAPI

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/inventory_openapi.png">
</p>

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/catalog_openapi.png">
</p>

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/customer_openapi.png">
</p>

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/orders_openapi.png">
</p>

- Metrics

  *  Only `admin` can access the metrics endpoints.
  *  `Inventory` and `Catalog` service metrics endpoints are protected using basic auth and to hit these endpoints, you need the credentials. In our sample application, the credentials are `Username:admin` and `Password:password`.
  * `Customer` and `Orders` services are oauth protected. So, the metrics endpoints are protected with oauth and to hit these endpoints, you need the mp-jwt token of the authorized user. In our sample application, to access it as `admin`, you need to login into the application using the credentials `Username:user` and `Password:password`.
  
<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/inventory_metrics.png">
</p>

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/catalog_metrics.png">
</p>

For catalog and inventory, we reused the metrics as the two microservices are closely related.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/customer_metrics.png">
</p>

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/orders_metrics.png">
</p>

To access the metrics for customer and orders, we used POSTMAN to pass the Authorization tokens.

You can also integrate these metrics with Prometheus. For now, we only integrated the `Inventory` and `Catalog` metrics with the Prometheus.

For example, `application:inventory` is one of the defined application metrics which gives the call count. The graph shows up as below in Prometheus.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/prometheus.png">
</p>

- Health Checks 

In this sample application, the health check capabilities are enabled.

For example, let us consider `Customer` service. For some reason, let us assume that the `Cloudant` service is down. When the health checks are enabled, corresponding service eventually checks if the dependent services are up and running. If not, `liveness probe` fails and it keeps restarting the unhealthy service to bring it back. 

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/healthcheck_sample1.png">
</p>

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/healthchecksample2.png">
</p>

- Fault Tolerance

In this sample application, the fault tolerance capabilities are enabled as well.

Let's assume we have the same scenario as above. The health checks restarts your service if it is unhealthy. It may take a while for the service to come back. So, when such things happen, it will be nice if the application keeps working.

Now the `cloudant` is down and `Customer` service cannot retrieve the user profile. See what happens here in our application.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/cloudant_faulttolerance.png">
</p>

So, now the end user will clearly understand that this particular service is down and rest of them are all working.

Similarly, when `Orders database` goes down, `Orders` shows up as below.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/orders_faulttolerance.png">
</p>

Likely, when `Elasticsearch` goes down, our store `Catalog` shows up as below.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/mp_features/catalog_faulttolerance.png">
</p>

## References

* [MicroProfile](https://microprofile.io/)
* [WebSphere Liberty](https://developer.ibm.com/wasdev/websphere-liberty/)
* [IBM Cloud Private](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/kc_welcome_containers.html)
