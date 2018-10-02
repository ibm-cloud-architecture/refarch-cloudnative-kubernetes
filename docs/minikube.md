# Run the Application on Minikube (Local kubernetes cluster)

## Table of Contents

* [Pre-requisites](#pre-requisites)
* [Set up your environment](#set-up-your-environment)
* [Run the App](#run-the-app)
* [Validate the App](#validate-the-app)
* [Test Login Credentials](#test-login-credentials)
* [Delete the App](#delete-the-app)
* [References](#references)

## Pre-requisites

To run the BlueCompute application locally on your laptop on a Kubernetes-based environment such as Minikube (which is meant to be a small development environment) we first need to get few tools installed:

- [Kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
- [Helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.

Finally, we must create a Kubernetes Cluster. As already said before, we are going to use Minikube:

- [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) - Create a single node virtual cluster on your workstation. Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-minikube/) to get Minikube installed on your workstation.

We not only recommend to complete the three Minikube installation steps on the link above but also read the [Running Kubernetes Locally via Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) page to get more familiar with Minikube.

Alternatively, you can also use the Kubernetes support provided in [Docker Edge](https://www.docker.com/kubernetes).

## Set up your environment

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

## Run the App

1. Add the `helm` package repository containing the reference application.

`helm repo add ibmcase-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp`

If you want to know how the helm packaging is done for this application, [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/bluecompute-mp/README.md) are the details.

2. Install the reference application.

`helm install --name bluecompute ibmcase-mp/bluecompute`

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

If you want to deploy the application in a particular namespace, run the below command.

`helm install --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace>`

## Validate the App

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

On `minikube` you can find the IP by issuing:

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

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/bc_mp_ui.png">
</p>

## Test Login Credentials

Use the following test credentials to login:
- **Username:** foo
- **Password:** bar

To login as an admin user, use the below. Admin has some extra privilages like having accessing to the monitoring data etc.
- **Username:** user
- **Password:** password

## Delete the App

To delete the application from your cluster, run the below command.

```
$ helm delete --purge bluecompute
```

## References

* [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
* [Minikube SetUp](https://kubernetes.io/docs/setup/minikube/)
* [Kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/)
* [Helm](https://github.com/kubernetes/helm)

