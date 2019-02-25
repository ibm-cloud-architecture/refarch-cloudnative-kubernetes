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

By default, the application runs on [WebSphere Liberty with Web Profile](https://developer.ibm.com/wasdev/websphere-liberty/). You can also run it on [Open Liberty](https://openliberty.io/) as follows

2. Install the reference application.

```
helm install --name bluecompute ibmcase-mp/bluecompute
```

By default, the application runs on [WebSphere Liberty](https://developer.ibm.com/wasdev/websphere-liberty/). You can also run it on [Open Liberty](https://openliberty.io/) as follows.

```
$ cd refarch-cloudnative-kubernetes

$ helm install -f utility_scripts/openliberty.yml --name bluecompute ibmcase-mp/bluecompute
```

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.

If you want to deploy the application in a particular namespace, run the below command.

```
helm install --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace>
```

By default, the application runs on [WebSphere Liberty](https://developer.ibm.com/wasdev/websphere-liberty/). You can also run it on [Open Liberty](https://openliberty.io/) as follows.

```
$ cd refarch-cloudnative-kubernetes

$ helm install -f utility_scripts/openliberty.yml --name bluecompute ibmcase-mp/bluecompute --namespace <Your_Namespace>
```

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

