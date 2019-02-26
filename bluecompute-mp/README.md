# Packaging the application using helm

## Table of Contents

* [Introduction](#introduction)
* [Get application source code](#get-application-source-code) 
* [Package the individual charts](#package-the-individual-charts)
  - [Inventory and Catalog](#inventory-and-catalog)
  - [Auth](#auth)
  - [Customer](#customer)
  - [Orders](#orders)
  - [Web](#web)
  - [Keystore](#keystore)
  - [Zipkin](#zipkin)
  - [Prometheus](#prometheus)
* [Building the chart repository](#building-the-chart-repository)
* [Umbrella Chart](#umbrella-chart)

## Introduction

This README demonstrates how the `bluecompute-0.0.x.tgz` is built and shows the details.

## Get the application source code

Clone the base repository:

```
$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes
```

Clone the peer repositories:

```
$ cd refarch-cloudnative-kubernetes
$ git checkout microprofile
$ cd utility_scripts
$ sh clone_peers.sh
```

## Package the individual charts

### Inventory 

1. Go to the below repository

```
$ cd refarch-cloudnative-micro-inventory/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the charts for **inventory service** using helm. For **inventory database**, we are using MySQL official charts for Helm available [here](https://github.com/helm/charts/tree/master/stable/mysql).

```
$ helm package chart/inventory
$ cd ..
```

### Catalog

1. Go to the below repository

```
$ cd refarch-cloudnative-micro-catalog/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

6. Package the charts for **catalog service** and **elasticsearch** using helm

```
$ helm package chart/catalog
$ helm package chart/ibmcase-elasticsearch/
$ cd ../..
```

### Auth

1. Go to the below repository

```
$ cd refarch-cloudnative-auth
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the chart for **auth service** using helm

```
$ helm package chart/auth
$ cd ..
```

### Customer

1. Go to the below repository

```
$ cd refarch-cloudnative-micro-customer/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the chart for **customer service** using helm

```
$ helm package chart/customer
$ cd ..
```

### Orders

1. Go to the below repository

```
$ cd refarch-cloudnative-micro-orders/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the charts for **orders service** using helm. For **orders database**, we are using MariaDB official charts for Helm available [here](https://github.com/helm/charts/tree/master/stable/mariadb).

```
$ helm package chart/orders
$ cd ..
```

### Web

1. Go to the below repository

```
$ cd refarch-cloudnative-bluecompute-web/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the charts for **web service** using helm.

```
$ helm package chart/web/
$ cd ..
```

### Keystore

1. Go to the below repository

```
$ cd refarch-cloudnative-kubernetes/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the charts for **Keystore** using helm.

```
$ cd Keystore/
$ helm package chart/keystore/
$ cd ..
```

### Zipkin

1. Go to the below repository

```
$ cd refarch-cloudnative-kubernetes/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the charts for **Zipkin** using helm.

```
$ cd Zipkin/
$ helm package chart/zipkin/
$ cd ..
```

### Prometheus

1. Go to the below repository

```
$ cd refarch-cloudnative-kubernetes/
```

2. Checkout MicroProfile branch.

```
$ git checkout microprofile
```

3. Package the charts for **Prometheus** using helm.

```
$ cd Prometheus/
$ helm package chart/ibm-icpmonitoring/
cd ..
```

## Building the chart repository

These are the steps we followed to build our chart repository.

1. We placed all the individual charts in the [chart repository](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile/docs/charts/services-bc-mp)

To access it, go to the below repository and run the below commands.

```
$ cd refarch-cloudnative-kubernetes/
$ cd docs/charts/services-bc-mp/
```

Now we are in the chart repository. It contains all the packaged charts we built previously.

2. The next step will be to generate a `index` file.

A valid chart repository must always have an index file which gives info about all the available charts present in the repository.

To do this, run the below command.

```
helm repo index ./
```

## Umbrella Chart

The umbrella helm chart for this sample application resides [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile/docs/charts/bluecompute).

We defined all the necessary dependencies in [`requirements.yaml`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/docs/charts/bluecompute/requirements.yaml). This allows you pull all the dependencies that are sitting in the chart repository you specified.

In order to pull the dependencies, do the following.

```
$ cd refarch-cloudnative-kubernetes/
$ cd docs/charts/
$ helm dependency update bluecompute/
```

**NOTE:** If you run into an error message for the above along the lines of: 

	Error: no repository definition for https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/docs/charts/services-bc-mp ...

Simply fix this command with by adding the helm repo with the command below and try again:

    helm repo add services-bc-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/docs/charts/services-bc-mp


After getting the dependencies, package the whole application using helm.

```
helm package bluecompute/
```

You will see a `tar` generated here. We placed it in the [bluecompute-mp](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile/bluecompute-mp) chart repository.

We also generated an index file here in the same repository.

```
cd ../..
cd bluecompute-mp/
helm repo index ./
```

















