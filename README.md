# Cloud-native development with MicroProfile, WebSphere Liberty, and IBM Cloud Private

* [Introduction](#introduction)
* [Application Overview](#application-overview)
* [Project repositories](#project-repositories)
* [Deploy the Application](#deploy-the-application)
  + [Pre-requisites](#pre-requisites)
  + [Get application source code (optional)](#get-application-source-code-optional)
  + [Locally in Minikube](#locally-in-minikube)
  + [Remotely in ICP](#remotely-in-icp)
  + [Login](#login)
* [Validate the Application](#validate-the-application)
  + [Minikube](#minikube)
  + [ICP](#icp)
  + [How the app works](#how-the-app-works)
* [Delete the Application](#delete-the-application)

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

This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository and tutorial listed below.

- [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile)                    - The root repository (Current repository)
 - [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/microprofile)    - The BlueCompute Web application with BFF services
 - [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/microprofile)               - The security authentication artifact
 - [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/microprofile)    - The microservices (Java) app for Catalog (ElasticSearch) and Inventory data service (MySQL, RabbitMQ)
 - [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/microprofile)    - The microservices (Java) app for Orders data service (MySQL, RabbitMQ)
 - [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/microprofile)    - The microservices (Java) app to fetch customer profile from identity store (IBM Cloudant)

## Deploy the Application

To run the sample applications you will need to configure your environment for the Kubernetes and Microservices
runtimes.

### Pre-requisites

#### Locally in Minikube

To run the BlueCompute application locally on your laptop on a Kubernetes-based environment such as Minikube (which is meant to be a small development environment) we first need to get few tools installed:

- [Kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
- [Helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.

Finally, we must create a Kubernetes Cluster. As already said before, we are going to use Minikube:

- [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) - Create a single node virtual cluster on your workstation. Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-minikube/) to get Minikube installed on your workstation.

We not only recommend to complete the three Minikube installation steps on the link above but also read the [Running Kubernetes Locally via Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) page to get more familiar with Minikube.

Alternatively, you can also use the Kubernetes support provided in [Docker Edge](https://www.docker.com/kubernetes).

#### Remotely in ICP

[IBM Cloud Private Cluster](https://www.ibm.com/cloud/private)

Create a Kubernetes cluster in an on-premise datacenter. The community edition (IBM Cloud Private-ce) is free of charge.
Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html) to install IBM Cloud Private-ce.

[Helm](https://github.com/kubernetes/helm) (Kubernetes package manager)

Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
If using IBM Cloud Private version 2.1.0.2 or newer, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.2/app_center/create_helm_cli.html) to install helm.

### Get application source code (optional)

- Clone the base repository:

  **`$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes`**

- Clone the peer repositories:

  **`$ cd refarch-cloudnative-kubernetes`**

  **`$ git checkout microprofile`**
  
  **`$ cd utility_scripts`**

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
2. To install Tiller, which is the server side component of Helm, initialize helm. Run the below command.

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

`helm repo add ibmcase-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

2. Install the reference application.

`helm install --name bluecompute ibmcase-mp/bluecompute`

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

### Remotely in ICP

[IBM Cloud Private](https://www.ibm.com/cloud/private)

IBM Private Cloud has all the advantages of public cloud but is dedicated to single organization. You can have your own security requirements and customize the environment as well. It has tight security and gives you more control along with scalability and easy to deploy options, whether you require it on public cloud infrastructure or in an on-premises environment behind your firewall.

You can find the detailed installation instructions for IBM Cloud Private [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html).

#### Setting up your environment

1. Your [IBM Cloud Private Cluster](https://www.ibm.com/cloud/private) should be up and running.

2. Log in to the IBM Cloud Private.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/icp_dashboard.png">
</p>

3. Go to `admin > Configure Client`.

<p align="center">
    <img width="300" height="300" src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/client_config.png">
</p>

4. Grab the kubectl configuration commands.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/kube_cmds.png">
</p>

5. Run those commands in your terminal.

6. If successful, you should see something like below.

```
Switched to context "xxx-cluster.icp-context".
```
7. Run the below command.

`helm init --client-only`

You will see the below

```
$HELM_HOME has been configured at /Users/user@ibm.com/.helm.
Not installing Tiller due to 'client-only' flag having been set
Happy Helming!
```

8. Verify the helm version

`helm version --tls`

You will see something like below.

```
Client: &version.Version{SemVer:"v2.7.2+icp", GitCommit:"d41a5c2da480efc555ddca57d3972bcad3351801", GitTreeState:"dirty"}
Server: &version.Version{SemVer:"v2.7.2+icp", GitCommit:"d41a5c2da480efc555ddca57d3972bcad3351801", GitTreeState:"dirty"}
```

#### Running the application on ICP

1. Add the `helm` package repository containing the reference application.

`helm repo add ibmcase-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

2. Install the reference application.

`helm install --name bluecompute ibmcase-mp/bluecompute --tls`

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

## Validate the Application

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/bc_mp_ui.png">
</p>

Before accessing the application, make sure that all the pods are up and running. Also, verify if the jobs are all completed.

```
$ kubectl get pods | grep bluecompute
bluecompute-auth-bbd9b8ccb-5rb7r                             1/1       Running       0          4m
bluecompute-catalog-58c9cf764c-9ng8n                         1/1       Running       0          4m
bluecompute-cloudant-544ff745fc-ctdnf                        1/1       Running       0          4m
bluecompute-customer-5f5684cd8d-bgpmr                        1/1       Running       0          4m
bluecompute-default-cluster-elasticsearch-6f4fb5c94d-lhkct   1/1       Running       0          4m
bluecompute-grafana-5fbf9b64c8-sjm4x                         1/1       Running       0          4m
bluecompute-inventory-5bd7b8f7cd-bs4sq                       1/1       Running       0          4m
bluecompute-inventorydb-6bcc5f4f8b-vljhx                     1/1       Running       0          4m
bluecompute-orders-6d94dc588b-zcvhh                          1/1       Running       0          4m
bluecompute-ordersdb-6fb4c876b5-q4p4k                        1/1       Running       0          4m
bluecompute-prometheus-86c4dc666f-6wfj8                      2/2       Running       0          4m
bluecompute-prometheus-alertmanager-8d9476f6-dvcr8           2/2       Running       0          4m
bluecompute-rabbitmq-686cd78fbc-rjwgm                        1/1       Running       0          4m
bluecompute-web-67c976678-b26gg                              1/1       Running       0          4m
bluecompute-zipkin-7d97f85d48-pk68s                          1/1       Running       0          4m
```

```
$ kubectl get jobs | grep bluecompute
bluecompute-grafana-ds     1         1            4m
bluecompute-keystore-job   1         1            4m
bluecompute-populate       1         1            4m
```

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

### ICP

If you've installed on `icp` you can find the IP by issuing:

**`$ kubectl cluster-info`**

You will see something like below.

```
Kubernetes master is running at https://172.16.40.4:8001
catalog-ui is running at https://172.16.40.4:8001/api/v1/namespaces/kube-system/services/catalog-ui/proxy
Heapster is running at https://172.16.40.4:8001/api/v1/namespaces/kube-system/services/heapster/proxy
icp-management-ingress is running at https://172.16.40.4:8001/api/v1/namespaces/kube-system/services/icp-management-ingress/proxy
image-manager is running at https://172.16.40.4:8001/api/v1/namespaces/kube-system/services/image-manager/proxy
KubeDNS is running at https://172.16.40.4:8001/api/v1/namespaces/kube-system/services/kube-dns/proxy
platform-ui is running at https://172.16.40.4:8001/api/v1/namespaces/kube-system/services/platform-ui/proxy
```

Grab the Kubernetes master ip and in this case, `<YourClusterIP>` will be `172.16.40.4`.

- To get the port, run this command.

**`$ kubectl get service bluecompute-web`**

You will see something like below.

```
NAME              TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
bluecompute-web   NodePort   10.0.0.46    <none>        80:31385/TCP   1m
```
In your browser navigate to **`http://<IP>:<Port>`**.

In the above case, the access url will be `http://172.16.40.4:31385`.

### Login

Use the following test credentials to login:
- **Username:** foo
- **Password:** bar

### How the app works

Below steps shows you how you can navigate across the app.

- Home Screen

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/bc_mp_ui.png">
</p>

- Catalog

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/catalog.png">
</p>

- Login

For our sample application, the default users are `foo` and `user`
Credentials for **foo** - `Username: foo` and `Password: bar`
Credentials for **user** - `Username: user` and `Password: password`

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/login.png">
</p>

- Orders

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/order.png">
</p>

- Customer Profile

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/customer.png">
</p>

## Delete the Application

To delete the application from your cluster, run the following:

Run the below command.

```
$ helm delete --purge bluecompute
```

