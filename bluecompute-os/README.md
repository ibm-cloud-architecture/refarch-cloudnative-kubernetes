# Deploy on Red Hat Openshift

## Table of Contents
  * [Introduction](#introduction)
  * [Deploy BlueCompute to OpenShift](#deploy-bluecompute-to-openshift)
    + [1. Create `bluecompute` Project in OpenShift](#1-create-bluecompute-project-in-openshift)
    + [2. Add Security Context Constraints (SCC) to the default Service Account](#2-add-security-context-constraints-scc-to-the-default-service-account)
    + [3. Deploy BlueCompute to OpenShift Project](#3-deploy-bluecompute-to-openshift-project)
    + [4. Expose the Web Application](#4-expose-the-web-application)
    + [5. Validate the Web Application](#5-validate-the-web-application)
  * [Cleanup](#cleanup)

## Introduction
[OpenShift](https://learn.openshift.com/) is a Kubernetes distribution from Red Hat, similar to [IBM Cloud Private](https://www.ibm.com/cloud/private), that is loaded with features to make developers' lives easier. Features such as strict security policies, logging and monitoring, and many more make OpenShift a well-rounded platform that's ready for production, saving you the trouble of cobbling them together yourself from vanilla Kubernetes.

However, there is one key feature that Kubernetes supports and OpenShift doesn't, at least officially--the ability to deploy Helm charts.

Helm is the official package manager for Kubernetes. It uses a sophisticated template engine and package versioning that is much more flexible than OpenShift templates. In addition, the Helm community has contributed numerous Helm charts for common applications like Jenkins, Redis, and MySQL that have been production-tested. [IBM Cloud Private](https://www.ibm.com/cloud/private), a Kubernetes-based enterprise platform for containers, has full support for Helm and its community charts. It leverages Helm to create a UI-based catalog system that makes it easier to reuse the community charts. The catalog also lets you install/uninstall Helm charts with just a couple clicks, making it much easier to install an entire software stack.

## Deploy BlueCompute to OpenShift
Now that we covered the changes for `bluecompute-ce` to adopt not just OpenShift but containers best practices, it's time to deploy `bluecompute-ce` into OpenShift.

**NOTE:** This section assumes that you have a working OpenShift cluster.

### 1. Create `bluecompute` Project in OpenShift
First, log into the OpenShift cluster:

```bash
oc login
```

Next, create a new project (OpenShift parlance for Kubernetes `namespace`) to deploy the `bluecompute-ce` YAML files:

```bash
oc new-project bluecompute
```

### 2. Add Security Context Constraints (SCC) to the default Service Account
Since both the bluecompute charts and the community helm charts (MySQL, Elasticsearch, MariaDB, and CouchDB) specify the UID that they will be running as, they are not compatible with OpenShift's default `restricted` [Security Context Constraint](https://docs.openshift.com/container-platform/3.11/architecture/additional_concepts/authorization.html#security-context-constraints), which doesn't allow this. Instead, the `restricted` SCC requires that your workloads be able to work with any random UID that OpenShift will assign. To avoid having to change the charts to support this, we can assign the `anyuid` SCC to the `default` Service Account in the `bluecompute` namespace with the following command:
```bash
oc adm policy add-scc-to-user anyuid system:serviceaccount:bluecompute:default
```

The reason for using `anyuid` vs `nonroot` SCC is that the Elasticsearch chart has a couple of init containers that require `root` access to the node to increase the virtual memory `max_map_count` and disable memory swapping before starting the `Elasticsearch` service. However, these containers also require `privileged` access to the host in order to perform this operation. To enable privileged mode for these containers, we can assign the `privileged` SCC to the `default` Service Account in the `bluecompute` namespace with the following command:

```bash
oc adm policy add-scc-to-user privileged system:serviceaccount:bluecompute:default
```

Now you should be ready to deploy all of `bluecompute-ce` into the `bluecompute` OpenShift Project!

**NOTE:** Assigning the `privileged` SCC to the `default` service account in the `bluecompute` namespace completely relaxes the security around the pods that get deployed to this namespace. This means that any hackers that manage to compromise pods deployed to this namespace have root-level access to the cluster! So assigning the `privileged` SCC should be done with caution and it is NOT recommended for production use. Perhaps a more granular SCC can be used to assign the required capabilities without opening security holes, but that's beyond the scope of this document.

### 3. Deploy BlueCompute to OpenShift Project
To deploy the `bluecompute-ce` YAML files, use the command below:

```bash
oc apply --recursive --filename bluecompute-os
```

Voilà, you have deployed all of `bluecompute-ce` into an OpenShift cluster! To check on its status to confirm they are up and running, run the following command:

```bash
oc get pods | grep -v test
```

You may need to run the above command multiple times to get an updated status for all pods. Once you have an output similar to the following, then all the pods are up and running!

```bash
NAME                                               READY     STATUS      RESTARTS   AGE
auth-5dfdcb6f69-fqdct                              1/1       Running     0          3m
bluecompute-customer-create-user-jxkhp-csnqb       1/1       Running     0          2m
bluecompute-inventory-populate-mysql-rxkgz-gn4cm   0/1       Completed   0          2m
bluecompute-mariadb-0                              1/1       Running     0          2m
catalog-ccc5d84cc-2wswh                            1/1       Running     0          2m
catalog-elasticsearch-client-6d4ff69f66-dfhdt      1/1       Running     0          2m
catalog-elasticsearch-data-0                       1/1       Running     0          2m
catalog-elasticsearch-master-0                     1/1       Running     0          2m
catalog-elasticsearch-master-1                     1/1       Running     0          2m
customer-78466cf844-cj9t6                          1/1       Running     0          2m
customer-couchdb-couchdb-0                         2/2       Running     2          2m
inventory-b4d69bddc-sj6dw                          1/1       Running     0          2m
inventory-mysql-7d84694976-7msjt                   1/1       Running     0          2m
orders-847c77d5ff-zdk9s                            1/1       Running     0          2m
web-65d9fbc79-5lwdd                                1/1       Running     0          2m
```

Now that all of the pods are available, it's time to expose the web service outside the OpenShift cluster in order to access the web application through a web browser.

### 4. Expose the Web Application
OpenShift makes exposing the web service outside the cluster very easy by using the following command to create an OpenShift `route`. It's essentially OpenShift's version of Kubernetes `Ingress`:

```bash
oc expose svc web
```

Now that the service is exposed with a route, retrieve the web route URL using the following command:

```bash
oc get route
```

You should see an output with the route URL similar to the following:

```bash
NAME      HOST/PORT                                    PATH      SERVICES   PORT      TERMINATION   WILDCARD
web       web-bluecompute.YOUR_CLUSTER_DOMAIN.com      web       http                 None
```

Where `YOUR_CLUSTER_DOMAIN.com` is the OpenShift Cluster's domain name and `web-bluecompute` is the CNAME created for the web route.

### 5. Validate the Web Application
To validate the application, open a browser window and enter the route URL from above and press enter. You should be able to see the web application's home page, as shown below.

![BlueCompute Detail](../../static/imgs/bluecompute_web_home.png?raw=true)

You can reference [this link](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/spring#validate-the-web-application) to validate the web application functionality. You should be able to see a catalog, login, make orders, and see your orders listed in your profile (once you are logged in).

## Cleanup
To cleanup everything, run the following commands:

```bash
# Delete route
oc delete route web

# Delete all resources using YAML files
oc delete --recursive --filename bluecompute-os
```
