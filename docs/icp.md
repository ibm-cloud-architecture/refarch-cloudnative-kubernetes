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

1. Add the `helm` package repository containing the reference application.

`helm repo add ibmcase-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

2. Install the reference application.

`helm install --name bluecompute ibmcase-mp/bluecompute --tls`

Note: If using IBM Cloud Private version older than 2.1.0.2, use `helm install --name bluecompute ibmcase-mp/bluecompute`

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

## Validate the App 

Before accessing the application, make sure that all the pods are up and running. Also, verify if the jobs are all completed.

```
$ kubectl get pods | grep bluecompute
bluecompute-auth-bbd9b8ccb-5dmww                             1/1       Running       0          3m
bluecompute-catalog-58c9cf764c-84lqd                         1/1       Running       0          3m
bluecompute-cloudant-544ff745fc-nptld                        1/1       Running       0          3m
bluecompute-customer-777f669f79-6shw8                        1/1       Running       0          3m
bluecompute-default-cluster-elasticsearch-6f4fb5c94d-tcgjg   1/1       Running       0          3m
bluecompute-grafana-5fbf9b64c8-jcltl                         1/1       Running       0          3m
bluecompute-inventory-5bd7b8f7cd-7hg5c                       1/1       Running       0          3m
bluecompute-inventorydb-6bcc5f4f8b-bdhxn                     1/1       Running       0          3m
bluecompute-orders-7747958847-4qtmm                          1/1       Running       0          3m
bluecompute-ordersdb-6fb4c876b5-l78pz                        1/1       Running       0          3m
bluecompute-prometheus-86c4dc666f-dqw5d                      2/2       Running       0          3m
bluecompute-prometheus-alertmanager-8d9476f6-n29jz           2/2       Running       0          3m
bluecompute-rabbitmq-686cd78fbc-dsb4h                        1/1       Running       0          3m
bluecompute-web-67c976678-zkjxc                              1/1       Running       0          3m
bluecompute-zipkin-7d97f85d48-hldzq                          1/1       Running       0          3m
```

```
$ kubectl get jobs | grep bluecompute
bluecompute-grafana-ds     1         1            3m
bluecompute-keystore-job   1         1            3m
bluecompute-populate       1         1            3m
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
