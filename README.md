# Run a Cloud Native Microservices Application on a Kubernetes Cluster

## Table of Contents
  * [Introduction](#introduction)
  * [Application Overview](#application-overview)
  * [Project Repositories](#project-repositories)
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
    + [Deploy BlueCompute to IBM Cloud Kubernetes Service](#deploy-bluecompute-to-ibm-cloud-kubernetes-service)
      - [Access and Validate the Application](#access-and-validate-the-application)
    + [Deploy BlueCompute to IBM Cloud Private](#deploy-bluecompute-to-ibm-cloud-private)
      - [OPTIONAL: Deploying BlueCompute to non-default Namespaces](#optional-deploying-bluecompute-to-non-default-namespaces)
      - [Access and Validate the Application](#access-and-validate-the-application-1)
      - [Delete the Application](#delete-the-application-1)
      - [Helm Version](#helm-version)
    + [Deploy BlueCompute Services on OpenLiberty](#deploy-bluecompute-services-on-openliberty)
    + [Deploy BlueCompute to IBM Cloud Private Cluster with No Internet Access](#deploy-bluecompute-to-ibm-cloud-private-cluster-with-no-internet-access)
    + [Deploy BlueCompute Across Multiple Kubernetes Cluster](#deploy-bluecompute-across-multiple-kubernetes-cluster)
    + [Istio-enabled Version](#istio-enabled-version)
    + [Deploy BlueCompute to an OpenShift Cluster](#deploy-bluecompute-to-an-openshift-cluster)
  * [Conclusion](#conclusion)
  * [Further Reading: DevOps automation, Resiliency and Cloud Management and Monitoring](#further-reading-devops-automation-resiliency-and-cloud-management-and-monitoring)
    + [DevOps](#devops)
    + [Cloud Management and monitoring](#cloud-management-and-monitoring)
    + [Making Microservices Resilient](#making-microservices-resilient)
    + [Secure The Application](#secure-the-application)
  * [Contributing](#contributing)
    + [Contributing a New Chart to the Helm Repositories](#contributing-a-new-chart-to-the-helm-repositories)
      - [Contributing a Chart to `ibmcase` Helm Chart Repository](#contributing-a-chart-to-ibmcase-helm-chart-repository)
      - [Contributing a Chart to `ibmcase-charts` Helm Chart Repository](#contributing-a-chart-to-ibmcase-charts-helm-chart-repository)

## Introduction
This project provides a reference implementation for running a Cloud Native Web Application using a Microservices architecture on a Kubernetes cluster.  The logical architecture for this reference implementation is shown in the picture below.

![Application Architecture](static/imgs/app_architecture.png?raw=true)

## Application Overview
The application is a simple store front shopping application that displays a catalog of antique computing devices, where users can search and buy products. It has a web interface that relies on separate BFF (Backend for Frontend) services to interact with the backend data.

There are several components of this architecture.

* This OmniChannel application contains an [AngularJS](https://angularjs.org/) based web application. The diagram depicts it as Browser.
* The Web app invokes its own backend Microservices to fetch data, we call this component BFFs following the [Backend for Frontends](http://samnewman.io/patterns/architectural/bff/) pattern.  In this Layer, front end developers usually write backend logic for their front end.  The Web BFF is implemented using the Node.js Express Framework. These Microservices are packaged as Docker containers and managed by Kubernetes cluster.
* The BFFs invokes another layer of reusable Java Microservices. In a real world project, this is sometimes written by different teams.  The reusable microservices are written in Java. They run inside a Kubernetes cluster, for example the [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service) or [IBM Cloud Private](https://www.ibm.com/cloud/private), using [Docker](https://www.docker.com/).
* The Java Microservices retrieve their data from the following databases:
  + The Catalog service retrieves items from a searchable JSON datasource using [ElasticSearch](https://www.elastic.co/).
  + The Customer service stores and retrieves Customer data from a searchable JSON datasource using [CouchDB](http://couchdb.apache.org/).
  + The Inventory Service uses an instance of [MySQL](https://www.mysql.com/).
  + The Orders Service uses an instance of [MariaDB](https://mariadb.org/).

## Project Repositories
This project organized itself like a microservice project, as such each component in the architecture has its own Git Repository and tutorial listed below.
- [refarch-cloudnative-kubernetes](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring)                    - The root repository (Current repository).
- [refarch-cloudnative-bluecompute-web](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/spring)    - The BlueCompute Web application with BFF services.
- [refarch-cloudnative-auth](https://github.com/ibm-cloud-architecture/refarch-cloudnative-auth/tree/spring)               - The security authentication artifact.
- [refarch-cloudnative-micro-customer](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-customer/tree/spring)    - The microservices (Java) app to fetch customer profile from identity store.
- [refarch-cloudnative-micro-inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/spring)    - The microservices (Java) app for Inventory data service (MySQL).
- [refarch-cloudnative-micro-catalog](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-catalog/tree/spring)    - The microservices (Java) app for Catalog (ElasticSearch).
- [refarch-cloudnative-micro-orders](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-orders/tree/spring)    - The microservices (Java) app for Order data service (MariaDB).

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
- [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://helm.sh/docs/intro/install/) to install it on your platform.
  + If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html) to install `helm`.

### Get application source code (optional)
- Clone the base repository:
  ```bash
  git clone -b spring --single-branch https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes
  ```

### Create a Kubernetes Cluster
The following clusters have been tested with this sample application:

- [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) - Create a single node virtual cluster on your workstation.

  By default minikube defaults to 2048M RAM which is not enough to start the application.  To provision 8G:
  ```bash
  minikube start --memory 8192
  ```

  Enable the ingress controller with:
  ```bash
  minikube addons enable ingress
  ```

- [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
- [IBM Cloud Private](https://www.ibm.com/cloud/private) - Create a Kubernetes cluster in an on-premise datacenter.  The community edition (IBM Cloud Private CE) is free of charge.  Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/installing.html) to install IBM Cloud Private CE.

### Deploy to Kubernetes Cluster
We have packaged all the application components as Kubernetes [Charts](https://github.com/kubernetes/charts). To deploy the application, follow the instructions to configure `kubectl` for access to the Kubernetes cluster.

1. Initialize `helm` in your cluster.
 ```bash
 helm init
 ```

This initializes the `helm` client as well as the server side component called `tiller`.

2. Add the `helm` package repository containing the reference application:
```bash
helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce
```

3. Install the reference application:
```bash
helm upgrade --install bluecompute ibmcase/bluecompute-ce
```

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).

## Validate the Application
You can reference [this link](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/spring#validate-the-web-application) to validate the sample web application.

![BlueCompute Detail](static/imgs/bluecompute_web_home.png?raw=true)

### Minikube
If you've installed on `minikube` you can find the IP by issuing:
```bash
minikube ip
```

In your browser navigate to **`http://<IP>:31337`**.

### Login
Use the following test credentials to login:
- **Username:** user
- **Password:** passw0rd

## Delete the Application
To delete the application from your cluster, run the following:
```bash
helm delete bluecompute --purge
```

## Optional Deployments

### Deploy BlueCompute to IBM Cloud Kubernetes Service
Deploying the Helm chart will also work on a Kubernetes cluster from IBM Cloud Kubernetes Service. Use the following commands to install the chart:
```bash
helm init

helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce

helm upgrade --install bluecompute ibmcase/bluecompute-ce
```

#### Access and Validate the Application
To access the application, you need to access the IP address of one of your worker nodes. To get the IP, use the following command:
```bash
ibmcloud cs workers <CLUSTER_NAME>
OK
ID                                                 Public IP        Private IP    Machine Type        State    Status   Zone    Version
kube-dal13-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-w1   163.77.77.72     10.77.77.71   u2c.2x4.encrypted   normal   Ready    dal13   1.10.1_1508
kube-dal13-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-w2   163.77.77.71     10.77.77.72   u2c.2x4.encrypted   normal   Ready    dal13   1.10.1_1508
kube-dal13-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-w3   163.77.77.73     10.77.77.73   u2c.2x4.encrypted   normal   Ready    dal13   1.10.1_1508
```

The command will give you an output similar to the above. Pick the Public IP of any of your worker nodes.

In your browser navigate to **`http://<IP>:31337`**.

To validate the application itself, feel free to use the instructions [here](#validate-the-application).

### Deploy BlueCompute to IBM Cloud Private
IBM Cloud Private (ICP) contains integration with Helm that allows you to install the application and all of its components in a few steps. This can be done as an administrator using the following steps:
1. Click on the user icon on the top right corner and then click on `Configure client`.
2. Copy the displayed `kubectl` configuration, paste it in your terminal, and press Enter on your keyboard.
3. Download and initialize helm in your cluster using [these instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html).
4. **NOTE**: If using IBM Cloud Private 3.1 or newer, you are required to create an [ImagePolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_images/image_security.html) that allows you to deploy images from the `docker.io` and `docker.elastic.co` Docker Registries:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/static/image_policy.yaml
  ```

5. Add the `helm` package repository containing the reference application:
  ```bash
  helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce
  ```

6. Install the reference application:
  ```bash
  helm upgrade --install bluecompute ibmcase/bluecompute-ce --tls
  ```

7. **NOTE**: If you want to deploy `bluecompute-ce` to a `non-default` namespace, follow the instructions in [Deploying BlueCompute to non-default Namespaces](#optional-deploying-bluecompute-to-non-default-namespaces) as there are a few extra steps required that involve **PodSecurityPolicies**.

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).

#### OPTIONAL: Deploying BlueCompute to non-default Namespaces
The `default` namespace in IBM Cloud Private is a special namespace that lets you deploy any type of container (including privileged containers) as long as you create an [ImagePolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_images/image_security.html) for it. That's because the default namespace's service account is authorized to use the [`ibm-privileged-psp` PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), which provides admin-level access to that service account. This is great for deploying workloads that require admin-level access, such as monitoring or networking agents.

However, most Kubernetes users don't require admin-level access to the cluster so they are usually assigned to work with non-default namespaces that have the [`ibm-restricted-psp` PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), which doesn't have admin-level access and only allows you to deploy non-root unprivileged containers. Shall those users (or service accounts) require admin-level access to the cluster, they would have to request it before it is granted.

In order to deploy `bluecompute-ce` to a `non-default` namespace, you will need to bind that namespace's default service account to the `ibm-privileged-psp` [PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html). That's because the `mysql`, `elasticsearch`, `couchdb`, and `mariadb` community Helm Charts are running their processes as root because they don't specify a `numeric id` for their container users in their [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) (i.e. checkout SecurityContext in [Elasticsearch Helm Chart](https://github.com/helm/charts/blob/master/stable/elasticsearch/templates/master-statefulset.yaml#L30)) if they have any. That's unfortunate because the Dockerfiles used in the Helm charts **DO** specify a non-root username (as shown in the [MySQL Dockerfile](https://github.com/docker-library/mysql/blob/bb7ea52db4e12d3fb526450d22382d5cd8cd41ca/5.7/Dockerfile#L4)) but Kubernetes requires a **NUMERIC** instead.

The Elasticsearch Helm Chart also requires the use of a root [Init Container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) (as shown [here](https://github.com/helm/charts/blob/master/stable/elasticsearch/templates/master-state-fulset.yaml#L101)) and a privileged Init Container (as shown [here](https://github.com/helm/charts/blob/master/stable/elasticsearch/templates/master-statefulset.yaml#L79)) to manually increase lockable memory limits and disable swapping in the worker nodes for Elasticsearch to work properly, even though Elasticsearch itself does not run as root.

Now that you understand why we need to authorize a non-default namespace to use the `ibm-privileged-psp` [PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), let's go ahead and do that with the following commands:

```bash
# Create non-default bluecompute namespace
kubectl create namespace bluecompute

# Create Role that allows the use of ibm-privileged-psp PodSecurityPolicy
kubectl create role psp:privileged -n bluecompute \
    --verb=use \
    --resource=podsecuritypolicy \
    --resource-name=ibm-privileged-psp

# Bind the above role to the default service account in bluecompute namespace
kubectl create rolebinding bluecompute:psp:privileged -n bluecompute \
    --role=psp:privileged \
    --serviceaccount=bluecompute:default
```

Now that the `default` service account for the `bluecompute` namespace is authorized to use the `ibm-privileged-psp` [PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), let's deploy `bluecompute-ce` chart with the following command:

```bash
helm upgrade --install bluecompute --namespace bluecompute ibmcase/bluecompute-ce --tls
```

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).

#### Access and Validate the Application
To access the application, you need to access the IP address of one of your proxy nodes. Pick the IP of any of your proxy nodes.

In your browser navigate to **`http://<IP>:31337`**.

To validate the application itself, feel free to use the instructions [here](#validate-the-application).

#### Delete the Application
To delete the application from your cluster, run the following commands:
```bash
# Delete the bluecompute-ce chart
helm delete bluecompute --purge --tls

# If you deployed the chart to a non-default namespace,
# you also have to delete both the Role and the RoleBinding
# NOTE: The following assumes that you deployed the chart to bluecompute namespace
kubectl --namespace bluecompute delete rolebinding bluecompute:psp:privileged;
kubectl --namespace bluecompute delete role psp:privileged;
```

#### Helm Version
If Chart installation fails, it usually has to do with the version of helm in your workstation being incompatible with the one installed in the IBM Cloud Private Cluster. To verify installed versions of helm, use the following command:
```bash
helm version --tls
```

If the versions are different, you might want to delete the current helm client and install a version of helm client that matches the server one. To do so, please refer to Helm's guide [here](https://github.com/kubernetes/helm/blob/master/docs/install.md).

### Deploy BlueCompute Services on OpenLiberty

The Spring Boot applications can be deployed on WebSphere Liberty as well. In this case, the embedded server i.e. the application server packaged up in the JAR file will be Liberty. To deploy the BlueCompute services on Open Liberty, follow the instructions below.

1. Initialize `helm` in your cluster.
 ```bash
 helm init
 ```

This initializes the `helm` client as well as the server side component called `tiller`.

2. Add the `helm` package repository containing the reference application:
```bash
helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce
```

3. Install the reference application:
```bash
cd OpenLiberty
helm upgrade --install bluecompute -f openliberty.yaml ibmcase/bluecompute-ce
```

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md). To validate the application, have a look at [Validate the Application](#validate-the-application) for instructions.

### Deploy BlueCompute to IBM Cloud Private Cluster with No Internet Access
Sometimes you are required to deploy services to an ICP cluster that has no internet access, which means that it can only pull docker images from ICP's Private Docker Registry. To learn how you can package the BlueCompute Chart (and all its Docker images), upload it directly to ICP, and install it without an Internet connection, checkout [Running Microservices Reference Architecture in Airgapped ICP Environments](docs/icp-uploading-chart).

### Deploy BlueCompute Across Multiple Kubernetes Cluster
Sometimes it is required for microservices in one Kubernetes cluster to communicate with services in separate Kubernetes cluster. To learn how you can deploy BlueCompute services across clusters and have them communicate with one another, checkout [Microservice to Microservice Communication across clusters using Private Network](docs/cluster-to-cluster).

### Istio-enabled Version
To learn about adding BlueCompute to an Istio-Enabled cluster, please checkout the document located at [docs/istio/README.md](docs/istio/README.md);

### Deploy BlueCompute to an OpenShift Cluster
To learn about deploying BlueCompute into an OpenShift cluster, please checkout the document located at [docs/openshift/README.md](docs/openshift/README.md);

## Conclusion
You have successfully deployed a 10-Microservices application on a Kubernetes Cluster in less than 1 minute by using the power of Helm charts. With such tools you can be assured that, in the case of Disaster Recovery, you can get your entire application up an running in no time. Also, by using Helm and Kubernetes, you can deploy your app in new environments to do things such as Q/A Testing, Performance Testing, UAT Testing, and tear it down afterwards as part of an automated testing pipeline.

To learn how you can put together an automated DevOps pipeline for Kubernetes, checkout the following section.

## Further Reading: DevOps automation, Resiliency and Cloud Management and Monitoring

### DevOps
You can setup and enable automated CI/CD for most of the BlueCompute components via the IBM Cloud DevOps Open Toolchain. For detail, please check the [DevOps project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops-kubernetes).

### Cloud Management and monitoring
For guidance on how to manage and monitor the BlueCompute solution, please check the [Management and Monitoring project](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes-csmo).

### Making Microservices Resilient
Please check [this repository](https://github.com/ibm-cloud-architecture/refarch-cloudnative-resiliency) on instructions and tools to improve availability and performances of the BlueCompute application.

### Secure The Application
Please review [this page](https://github.com/ibm-cloud-architecture/refarch-cloudnative/blob/master/static/security.md) on how we secure the solution end-to-end.

## Contributing
If you would like to contribute to this repository, please fork it, submit a PR, and assign as reviewers any of the GitHub users listed here:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/graphs/contributors

### Contributing a New Chart to the Helm Repositories
We use this GitHub project to host the following 2 [Helm Chart Repositories](https://github.com/helm/helm/blob/master/docs/chart_repository.md):
* **ibmcase**
  + This helm chart repository (which is located at [docs/charts/bluecompute-ce](docs/charts/bluecompute-ce)) is used to serve only the `bluecompute-ce` chart, which contains all its dependencies already included.
  + The reason it only serves the `bluecompute-ce` chart is purely cosmetic, which is to avoid overcrowding the ICP Catalog with additional charts.
* **ibmcase-charts**
  + This helm chart repository (which is located at [docs/charts](docs/charts)) is used to serve the dependency charts that are used to build a new `bluecompute-ce` chart.

To learn how to contribute updates to above helm chart repositories, checkout the sections below.

#### Contributing a Chart to `ibmcase` Helm Chart Repository
Remember that the `ibmcase` helm chart repository is only supposed to serve versions of the `bluecompute-ce` chart. Here is the typical workflow of updating the `bluecompute-ce` chart and adding the new chart version to the `ibmcase` helm chart repo:
1. Making chart changes in the [bluecompute-ce](bluecompute-ce) folder.
  + Changes are typically done in the [bluecompute-ce/templates](bluecompute-ce/templates) folder.
  + Changes also typically involve updating dependency chart versions in [bluecompute-ce/requirements.yaml](bluecompute-ce/requirements.yaml).
2. Bumping up the chart version in [bluecompute-ce/Chart.yaml](bluecompute-ce/Chart.yaml#L4).
  + This is to prevent overriding existing charts in the helm chart repo.
  + Bumping up the Chart version also guarantees the new chart becoming the new default version.
3. Downloading chart dependencies.
  ```bash
  # Add ibmcase-charts and inbubator helm repos
  helm repo add ibmcase-charts https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts
  helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator

  # Go to bluecompute-ce chart folder
  cd bluecompute-ce

  # Download dependency charts
  helm dependency update

  # Go back to root folder
  cd ..
  ```

4. Packaging the chart and its dependencies.
  ```bash
  # Package bluecompute-ce chart
  helm package bluecompute-ce
  ```

5. Putting the new packaged chart in the helm chart repo folder [docs/charts/bluecompute-ce](docs/charts/bluecompute-ce).
  ```bash
  # Move packaged chart to repo folder
  # Where ${CHART_VERSION} represents the new chart version you updated in bluecompute-ce/Chart.yaml
  mv bluecompute-ce-${CHART_VERSION}.tgz docs/charts/bluecompute-ce
  ```

6. Re-indexing the helm chart repo's index file so it can detect and serve the new chart.
  ```bash
  # Re-index helm repo's index file so it includes the new chart version
  helm repo index docs/charts/bluecompute-ce --url=https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce
  ```

7. Committing both new chart changes along with updated repo information and pushing them to your fork.
  ```bash
  # Add docs/charts/bluecompute-ce to a new commit
  git add docs/charts/bluecompute-ce
  git commit -m "New bluecompute-ce chart"

  # Push to your fork
  git push
  ```

8. Opening a Pull Request (PR) for the new changes.
9. Once the PR has been approved and merged by one of the project's contributors, the new chart version becomes publicly available. You can then refresh your helm chart repos to get the latest changes.
  ```bash
  # If you haven't already, add the ibmcase helm repo
  helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce

  # Refresh repo with new changes
  helm repo update
  ```

10. Searching for the `bluecompute-ce` chart should return the new chart and it's latest version
  ```bash
  helm search bluecompute-ce
  ```

If you are able to see the chart's latest version, then congratulations!!! You have officially contributed an update to the `ibmcase` Helm Repository.

#### Contributing a Chart to `ibmcase-charts` Helm Chart Repository
Remember that the `ibmcase-charts` helm chart repository is only supposed to serve versions of charts that will be used by the `bluecompute-ce` chart. Here is the typical workflow of adding the new chart version to the `ibmcase-charts` helm chart repo:
1. Making changes in the `chart` folder of any of the repos listed in [Project Repositories](#project-repositories).
2. Bumping up the chart version in `Chart.yaml`.
  + This is to prevent overriding existing charts in the helm chart repo.
  + Bumping up the Chart version also guarantees the new chart becoming the new default version.
3. Downloading chart dependencies.
  ```bash
  # Add ibmcase-charts and inbubator helm repos
  helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator

  # Go to chart folder
  cd PATH/TO/CHART/FOLDER

  # Download dependency charts
  helm dependency update

  # Go back to root folder
  cd ../..
  ```

4. Packaging the chart and its dependencies.
  ```bash
  # Package chart
  helm package PATH/TO/CHART/FOLDER
  ```

5. Putting the new packaged chart in the helm chart repo folder [docs/charts](docs/charts).
  ```bash
  # Move packaged chart to repo folder
  # Where ${CHART_NAME} and ${CHART_VERSION} represent the new chart name and version, respectively
  mv ${CHART_NAME}-${CHART_VERSION}.tgz PATH/TO/refarch-cloudnative-kubernetes/docs/charts
  ```

6. Re-indexing the helm chart repo's index file so it can detect and serve the new chart.
  ```bash
  # Re-index helm repo's index file so it includes the new chart version
  helm repo index docs/charts --url=https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts
  ```

7. Committing both new chart changes along with updated repo information and pushing them to your fork.
  ```bash
  # Add docs/charts to a new commit
  git add docs/charts
  git commit -m "New chart"

  # Push to your fork
  git push
  ```

8. Opening a Pull Request (PR) for the new changes.
9. Once the PR has been approved and merged by one of the project's contributors, the new chart version becomes publicly available. You can then refresh your helm chart repos to get the latest changes.
  ```bash
  # If you haven't already, add the ibmcase helm repo
  helm repo add ibmcase-charts https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts

  # Refresh repo with new changes
  helm repo update
  ```

10. Searching for the chart should return the new chart and it's latest version
  ```bash
  # Where ${CHART_NAME} represents the chart bame
  helm search ${CHART_NAME}
  ```

If you are able to see the chart's latest version, then congratulations!!! You have officially contributed an update to the `ibmcase-case` Helm Repository.
