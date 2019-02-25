# Run the Application on IBM Cloud Private

## Table of Contents

* [Introduction](#introduction)
* [Pre-requisites](#pre-requisites)
* [Set up your environment](#set-up-your-environment)
* [Run the App](#run-the-app)
* [Validate the App](#validate-the-app)
* [Test Login Credentials](#test-login-credentials)
* [Delete the App](#delete-the-app)
* [References](#references)

## Introduction

[IBM Cloud Private](https://www.ibm.com/cloud/private)

IBM Private Cloud has all the advantages of public cloud but is dedicated to single organization. You can have your own security requirements and customize the environment as well. It has tight security and gives you more control along with scalability and easy to deploy options, whether you require it on public cloud infrastructure or in an on-premises environment behind your firewall.

You can find the detailed installation instructions for IBM Cloud Private [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html).

## Pre-requisites

[IBM Cloud Private Cluster](https://www.ibm.com/cloud/private)

Create a Kubernetes cluster in an on-premise datacenter. The community edition (IBM Cloud Private-ce) is free of charge.
Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html) to install IBM Cloud Private-ce.

[Helm](https://github.com/kubernetes/helm) (Kubernetes package manager)

Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
If using IBM Cloud Private version 2.1.0.2 or newer, we recommend you to follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.2/app_center/create_helm_cli.html) to install helm.

## Set up your environment

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

You will see something similar to the below message.

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

## Run the App 

**Note**: If you are running the application on IBM Cloud Private 3.1 or newer, create an ImagePolicy to allow images from the other docker Registries:

`$ kubectl apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/static/image_policy.yaml`

If you are deploying it in a particular namespace, run the below command.

`$ kubectl apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/static/image_policy.yaml  --namespace <Your_Namespace>`

1. Add the `helm` package repository containing the reference application.

`helm repo add ibmcase-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

If you want to know how the helm packaging is done for this application, [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/bluecompute-mp/README.md) are the details.

2. Install the reference application.

```
helm install --name bluecompute ibmcase-mp/bluecompute --tls
```

By default, the application runs on [WebSphere Liberty](https://developer.ibm.com/wasdev/websphere-liberty/). You can also run it on [Open Liberty](https://openliberty.io/) as follows.

```
$ cd refarch-cloudnative-kubernetes

$ helm install -f utility_scripts/openliberty.yml --name bluecompute ibmcase-mp/bluecompute --tls
```

Note: If using IBM Cloud Private version older than 2.1.0.2, use `helm install --name bluecompute ibmcase-mp/bluecompute`.
If running it on Open Liberty, run `helm install -f utility_scripts/openliberty.yml --name bluecompute ibmcase-mp/bluecompute`.

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

If you want to deploy the application in a particular namespace, run the below command.

`helm install --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace> --tls`

By default, the application runs on [WebSphere Liberty](https://developer.ibm.com/wasdev/websphere-liberty/). You can also run it on [Open Liberty](https://openliberty.io/) as follows.

```
$ cd refarch-cloudnative-kubernetes

$ helm install -f utility_scripts/openliberty.yml --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace> --tls
```

Note: If using IBM Cloud Private version older than 2.1.0.2, use `helm install --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace>`. If running it on Open Liberty, run `helm install --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace>`.

## Validate the App 

Before accessing the application, make sure that all the pods are up and running. Also, verify if the jobs are all completed.

```
$ kubectl get pods | grep bluecompute
bluecompute-auth-7b5c48dc45-j6tjj                            1/1       Running     0          4m53s
bluecompute-catalog-64b7f9b868-ljv5t                         1/1       Running     0          4m53s
bluecompute-cloudant-5db8f75ff-vnltq                         1/1       Running     0          4m53s
bluecompute-customer-6bd6649bf-prtw5                         1/1       Running     0          4m53s
bluecompute-default-cluster-elasticsearch-7db6db99cf-xkwd5   1/1       Running     0          4m53s
bluecompute-grafana-698858b767-kdprj                         1/1       Running     0          4m53s
bluecompute-grafana-ds-fdl6x                                 0/1       Completed   0          4m53s
bluecompute-inventory-6fc5d75fb8-k2z6h                       1/1       Running     0          4m52s
bluecompute-inventory-job-njjnp                              0/1       Completed   0          4m53s
bluecompute-inventorydb-6f764b7d6d-rbztw                     1/1       Running     0          4m52s
bluecompute-keystore-job-wdvmz                               0/1       Completed   0          4m52s
bluecompute-mariadb-0                                        1/1       Running     0          4m53s
bluecompute-mysql-69bbd4bcb6-9jhlv                           1/1       Running     0          4m52s
bluecompute-orders-7548cb5b95-9ck9f                          1/1       Running     0          4m51s
bluecompute-orders-job-4fqwx                                 0/1       Completed   0          4m52s
bluecompute-ordersdb-6dd8f74c6f-5nxld                        1/1       Running     0          4m51s
bluecompute-populate-97v55                                   0/1       Completed   0          67s
bluecompute-populate-b57zv                                   0/1       Error       0          4m53s
bluecompute-populate-d2lx2                                   0/1       Error       0          3m18s
bluecompute-populate-qql4q                                   0/1       Error       0          2m27s
bluecompute-populate-w9d9b                                   0/1       Error       0          3m8s
bluecompute-prometheus-858b5687dc-gc562                      2/2       Running     0          4m53s
bluecompute-prometheus-alertmanager-7986ffc4f9-cnc9k         2/2       Running     0          4m53s
bluecompute-rabbitmq-67c6974867-s6fps                        1/1       Running     0          4m52s
bluecompute-web-69bbc79598-blb5w                             1/1       Running     0          4m51s
bluecompute-zipkin-65b55c4bfd-pd7jn                          1/1       Running     0          4m51s
```

```
$ kubectl get jobs | grep bluecompute
bluecompute-grafana-ds      1/1           118s       6m41s
bluecompute-inventory-job   1/1           2m7s       6m41s
bluecompute-keystore-job    1/1           79s        6m40s
bluecompute-orders-job      1/1           98s        6m40s
bluecompute-populate        1/1           3m49s      6m41s
```

On `ICP` you can find the IP by issuing:

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

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/bc_mp_ui.png">
</p>

## Test Login Credentials

Use the following test credentials to login:
- **Username:** foo
- **Password:** bar

To login as an `admin` user, use the below. Admin has some extra privilages like having access to the monitoring data etc.
- **Username:** user
- **Password:** password

## Delete the App

To delete the application from your cluster, run the below command.

```
$ helm delete --purge bluecompute --tls
```
Note: If using IBM Cloud Private version older than 2.1.0.2, use `helm delete --purge bluecompute`

## References

* [Developer Tools CLI](https://console.bluemix.net/docs/cloudnative/dev_cli.html#developercli)
* [IBM Cloud Private](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/kc_welcome_containers.html)
* [IBM Cloud Private Installation](https://github.com/ibm-cloud-architecture/refarch-privatecloud)
* [IBM Cloud Private version 2.1.0.2 Helm instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.2/app_center/create_helm_cli.html)
* [Kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/)
* [Helm](https://github.com/kubernetes/helm)
