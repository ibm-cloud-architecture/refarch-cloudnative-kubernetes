# Microservice to Microservice Communication across clusters using Private Network
**Author:** Fabio Gomez (fabiogomez@us.ibm.com)

Deploying microservices works great inside a single Kubernetes cluster. But what if your microservices need to communicate with other microservices that are deployed in a separate cluster? Better yet, how can you talk with those microservices using an encrypted connection through a private network for added security? Let's see how you can do that with IBM Cloud Container Service (ICCS).

## Table of Contents
* [Pre-requisites](#pre-requisites)
* [Architecture Overview](#architecture-overview)
* [Setup](#setup)
    + [1. Enable VLAN Spanning](#1-enable-vlan-spanning)
    + [2. Deploy 2 standard clusters](#2-deploy-2-standard-clusters)
    + [3. Enable Private Application Load Balancer (ALB)](#3-enable-private-application-load-balancer-alb)
* [Deploy Bluecompute across different clusters](#deploy-bluecompute-across-different-clusters)
    + [1. Deploy the `orders` chart in the `orders-cluster`](#1-deploy-the-orders-chart-in-the-orders-cluster)
    + [2. Deploy the `bluecompute-ce` chart in the `web-cluster`](#2-deploy-the-bluecompute-ce-chart-in-the-web-cluster)
        - [a. Custom Endpoints Overview](#a-custom-endpoints-overview)
        - [b. Deploy the `bluecompute-ce` chart](#b-deploy-the-bluecompute-ce-chart)
    + [3. Validate the Application](#3-validate-the-application)
    + [4. Delete the Application](#4-delete-the-application)
* [Enable TLS](#enable-tls)
    + [1. Create a TLS certificate](#1-create-a-tls-certificate)
    + [2. Put the TLS certificate and key into `orders/values.yaml`](#2-put-the-tls-certificate-and-key-into-ordersvaluesyaml)
    + [3. Enable TLS in `orders` chart](#3-enable-tls-in-orders-chart)
    + [4. Enable TLS for `orders` service in the `bluecompute-ce` chart](#4-enable-tls-for-orders-service-in-the-bluecompute-ce-chart)
    + [5. Validate TLS in the Application](#5-validate-tls-in-the-application)
* [Conclusion](#conclusion)

## Pre-requisites
- Install the following CLIs:
    * [IBM Cloud account](https://console.bluemix.net/registration/?target=/containers-kubernetes/launch)
    * [IBM Cloud CLI](https://console.bluemix.net/docs/containers/container_index.html)
    * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    * [helm](https://github.com/kubernetes/helm/blob/master/docs/install.md)
- Clone the repo and cd to `cluster-to-cluster`:

```
$ git clone https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes
$ cd refarch-cloudnative-kubernetes/cluster-to-cluster
```

## Architecture Overview
![Architecture](imgs/cluster_to_cluster.png?raw=true)

The diagram above shows a modified version of our Microservices Reference Architecture Application, better known as `bluecompute`, which you can learn more about [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#introduction). This application is deployed using a single [Helm Chart](https://docs.helm.sh/developing_charts/#charts), the `bluecompute-ce` chart, which contains multiple dependency charts representing all the different microservices. In this How-To blog, we are going to deploy the `bluecompute-ce` chart as follows:
- Deploy the `orders` chart, which contains `ibmcase-orders-mysql` as a dependency chart, into one cluster, which we are going to call `orders-cluster`
- Deploy the `bluecompute-ce`, which does not contain neither `orders` nor its dependent `ibmcase-mysql` chart, into a separate cluster, which we are going to call `web-cluster`.
- The `orders` service in the `orders-cluster` will be exposed privately to the `web` service in the `web-cluster` via a `Private Application Load Balancer` (ALB) 
- We will be enabling TLS on the `orders-cluster` Private ALB to add an extra layer of security.


## Setup
### 1. Enable VLAN Spanning
In order for the clusters to talk to each other via Private Network, we need to turn on `VLAN Spanning` in your Infrastructure account. Open a browser window and use the following instructions to Turn on VLAN Spanning.
![Architecture](imgs/enable_vlan_spanning.png?raw=true)

### 2. Deploy 2 standard clusters
For this demo, we are going to create `2 Standard Clusters` in separate locations:
- Let's call the 1st cluster `orders-cluster` and deploy it in `us-south-dal12` location.
    * In here, we are going to deploy the `orders` chart, which includes the `orders` and `ibmcase-orders-mysql` charts
- Let's call the 2nd cluster `web-cluster` and deploy it in `us-south-dal10` location.
    * In here, we are going to deploy the `bluecompute-ce` chart, which includes the charts for the rest of the microservices, minus the `orders` chart

To provision the 2 Standard Clusters, follow [these](https://console.bluemix.net/docs/containers/cs_clusters.html#clusters_ui) instructions.

Once the 2 clusters are provisioned, do the following:
- Open 2 terminal windows.
- On the 1st terminal window:
    * Download the kubernetes cluster context for the `orders-cluster`.
    * Then do a `helm init`.
- On the 2nd terminal window:
    * Download the kubernetes cluster context for the `web-cluster`.
    * Then do a `helm init`.

Since we are going to use `kubectl` and `helm` on 2 clusters, the above instructions keep the context for each cluster on separate terminal windows, which prevents a constant back and forth between them. 


### 3. Enable Private Application Load Balancer (ALB)
The [Private Application Load Balancer](https://console.bluemix.net/docs/containers/cs_ingress.html#ingress_expose_private) (ALB) that comes with ICCS Standard clusters can be used as a custom [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress/) that exposes Kubernetes services over the private network only. 

For this example, we only need to enable the Private ALB for the `orders-cluster`. This is so that the web application in the `web-cluster` can access the `orders` microservice in the `orders-cluster` over the private network. Follow the instructions below to enable the Private ALB:

- Open the `orders-cluster` terminal window.
- Use the instructions on this [link](https://console.bluemix.net/docs/containers/cs_ingress.html#private_ingress) to enable private load balancers.

## Deploy Bluecompute across different clusters
### 1. Deploy the `orders` chart in the `orders-cluster`
Let's deploy the `orders` chart in the `orders-cluster` and expose it to the `web-cluster` through the Private ALB. To do so, follow the instructions below
- Go to the `orders-cluster` terminal window.
- Get the `ALB ID` for the Private ALB:

```bash
$ bx cs albs --cluster <orders-cluster-name>

OK
ALB ID                                                Enabled   Status     Type      ALB IP
private-cr708a92bffbde4569a04273eb64b3ff04-alb1       true      enabled    private   10.184.13.192
```

- Paste it in the [`loadBalancerID`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L35) field inside the [orders/values.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L35) file and save it.
- Deploy the orders chart:

```bash
$ helm install --name bluecompute orders
```

NOTE: For details on the contents of the orders chart, see the files in the `orders` folder. Particularly, check out [orders/templates/ingress.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/templates/ingress.yaml) to check out the ingress resource.

### 2. Deploy the `bluecompute-ce` chart in the `web-cluster`
Now that we deployed `orders` chart in `orders-cluster`, we can deploy the `bluecompute-ce` chart in the `web-cluster` and have it communicate to `orders` service over the private network. But first, let's cover `Custom Endpoints` a little bit, since it is the main Kubernetes feature we are leveraging. Then we will proceed to deploying the `bluecompute-ce` chart.

#### a. Custom Endpoints Overview
We want the `web` application to communicate with the `orders` service in the `orders-cluster` the same way it does it when the `orders` service is in the same cluster as the `web` application. In other words, we wanted the `web` application to reference the `orders` service using its [kube-dns](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) name of `http://orders-service:8080` even if the `orders` service is in another cluster.

In order to accomplish cluster to cluster communication without changing any application code or edit the existing YAML files in the `web` chart, we created the following in the `bluecompute-ce` chart's templates folder:
- A custom `Service` for `orders` service:
    * This service will point to a custom `Endpoint` for `orders` service in `orders-cluster`, explained below.
    * For details on the custom endpoint, checkout the [`bluecompute-ce/templates/ordersService.yaml`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/templates/ordersService.yaml) file.
- A custom `Endpoint` for `orders` service:
    * This endpoint contains the IP address of the Private ALB in the `orders-cluster` and port 80 for the Ingress.
        + We are leveraging a Kubernetes feature called `Headless services Without selectors`, which you can learn about [here](https://kubernetes.io/docs/concepts/services-networking/service/#without-selectors)
    * Since we are not enabling `Transport Layer Security` (TLS) in the `orders-cluster` ingress yet (which will do in a later section) the endpoint will contain port 80 for the Ingress.
    * For details on the custom endpoint, checkout the [`bluecompute-ce/templates/ordersEndpoint.yaml`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/templates/ordersEndpoint.yaml) file.


#### b. Deploy the `bluecompute-ce` chart
To deploy the `bluecompute-ce` chart, follow the instructions below:
- Now go to the `web-cluster` terminal window.
- Get the `ALB IP` address for the `orders-cluster` Private ALB:

```bash
$ bx cs albs --cluster <orders-cluster-name>

OK
ALB ID                                                Enabled   Status     Type      ALB IP
private-cr708a92bffbde4569a04273eb64b3ff04-alb1       true      enabled    private   10.184.13.192
```

- Paste it in the [`loadBalancerIp`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml#L74) in the `orders` section inside the [`bluecompute-ce/values.yaml`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml#L74) file and save it.

- Deploy the `bluecompute-ce` chart:

```bash
$ helm install --name bluecompute bluecompute-ce
```


### 3. Validate the Application
You can reference [this link](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/kube-int#validate-the-deployment) to validate the sample web application.

![BlueCompute Detail](https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/master/static/imgs/bluecompute_web_home.png)

The main thing we want to validate is that, once you are logged in, you are able to `Buy` items and see the orders listed in the `Profile` section. This means that the web app in the `web-cluster` is able to communicate with the `orders` service in the `orders-cluster`.

If you are able to do the above, then `CONGRATULATIONS`, you have successfully deployed a microservice application across 2 clusters!!!

### 4. Delete the Application
To delete the bluecompute application, follow these instructions:
- Go to the `web-cluster` terminal window and run the following command:

```bash
$ helm delete bluecompute --purge
```

- Go to the `orders-cluster` terminal window and run the following command:

```bash
$ helm delete bluecompute --purge
```

NOTE: the helm releases in both clusters are called `bluecompute`.

## Enable TLS
In some scenarios, just having private microservice communication between services across clusters is enough security-wise. But in some scenarios, private and `encrypted` communication is required to add that extra layer of security. For that we can use `Transport Layer Security` (TLS) encryption.

To enable TLS, you need to do a few things, then you can proceed to deploy the applications as outlined in the sections above. In later sections you will see all the details to enable TLS, but here is an overview of the steps you will have to go through:
- Create a TLS certificate
- Put the TLS certificate and TLS key in the `orders/values.yaml` file, which will create a secret
- Enable TLS in the orders ingress resource via `orders/values.yaml`
- In the `bluecompute-ce/values.yaml` file, you need to update the `orders` protocol to `https` and the orders ports to `443` to fully enable TLS

![Architecture](imgs/cluster_to_cluster_with_tls.png?raw=true)

To enable TLS, the only additional Kubernetes resource that we are creating is a secret to hold the TLS certificate, which is used by the Ingress resource to enforce TLS.

### 1. Create a TLS certificate
The first thing to do to enable TLS is to create a certificate using OpenSSL, which you might need to [install](https://github.com/openssl/openssl/blob/master/INSTALL) on your workstation. Here is the command to create a TLS certificate:

```bash
$ openssl req -newkey rsa:4096 -nodes -sha512 -x509 -days 3650 -nodes -out tls.crt -keyout tls.key
```

The above command will generate a key and ask you a series of questions, as shown below:

```bash
Generating a 4096 bit RSA private key
..................++
.........................................................................................................................................................................++
writing new private key to 'tls.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:US
State or Province Name (full name) []:Texas
Locality Name (eg, city) []:Austin
Organization Name (eg, company) []:IBM
Organizational Unit Name (eg, section) []:CASE
Common Name (eg, fully qualified host name) []:bluecompute-orders
Email Address []:you@email.com
```

Feel free to enter the values shown above, but the most important thing to enter is a value of `bluecompute-orders` for the `Common Name` field. This will allow the Private Ingress/ALB in `orders-cluster` to route requests for `bluecompute-orders` domain name to the `orders` service in the `orders-cluster`.

You may ask yourself whether you need to go to a domain registrar first and register this domain name, but since we are leveraging [kube-dns](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) and the Private Ingress/ALB domain routing features, we can avoid this step.

### 2. Put the TLS certificate and key into `orders/values.yaml`
Now that we have your TLS certificate, we need to put it in the `orders/values.yaml` as follows:

1. Get the contents of the `tls.crt` file and then encode it in base64 format:

```bash
$ cat tls.crt | base64
```

2. Copy the output of the above command into the [`crt`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L39) field in the `tls` section of [orders/values.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L39) file and save it.

3. Get the contents of the `tls.key` file and then encode it in base64 format:

```bash
$ cat tls.key | base64
```

4. Copy the output of the above command into the [`key`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L40) field in the `tls` section of [orders/values.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L40) file and save it.

The steps above are needed to create a Kubernetes Secret for the TLS Certificate and Key in [orders/templates/secret.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/templates/secret.yaml), which the Ingress resource requires in [orders/templates/ingress.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/templates/ingress.yaml#L16) to enforce TLS and traffic rules for the `bluecompute-orders` domain name.

### 3. Enable TLS in `orders` chart
To enable TLS in the `orders` chart's ingress controller, change the value of [`enabled`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L38) field in the `tls` section to `true` in [orders/values.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml#L38) file and save it.

The above will enable TLS in the [orders/templates/ingress.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/templates/ingress.yaml#L12) resource, which will use the TLS secret created in the previous step to encorce TLS and traffic rules for the `bluecompute-orders` domain name.

Once the `orders` chart is deployed, TLS will be fully enabled.

### 4. Enable TLS for `orders` service in the `bluecompute-ce` chart
Now that TLS is enabled in the `orders` chart, we can tell the `bluecompute-ce` chart to start using `https` protocol when commnicating with the `bluecompute-orders` service. To do so, you need to do the following in the `bluecompute-ce/values.yaml`:
1. Change value both [`orders.port`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml#L75) and [`orders.targetPort`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml#L76) to `443`. This will update the `orders` port values in both [bluecompute-ce/templates/ordersService.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/templates/ordersService.yaml) and [bluecompute-ce/templates/ordersEndpoint.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/templates/ordersEndpoint.yaml)
2. Change value of [`web.services.orders.port`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml#L92) to `443`. This will update the port number that the `web` application uses to reference to the `orders` service, which you can checkout in the web application's [config map](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/chart/web/templates/configmap.yaml#L39).
3. Change value of [`web.services.orders.protocol`](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml#L93) to `https`. This will update the protocol that the `web` application uses to reference to the `orders` service, which you can checkout in the web application's [config map](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/blob/master/chart/web/templates/configmap.yaml#L38).

You have successfully enabled TLS between the `web` application in the `web-cluster` and the `orders` service in the `orders-cluster`. Now you can proceed to deploy both the `orders` and `bluecompute-ce` charts as instructed [`here`](#deploy-bluecompute-across-different-clusters).

If the `orders` and `bluecompute-ce` charts are still installed in their respective clusters, you can upgrade the chart releases as follows:

1. Go to the `orders-cluster` terminal window and run the following command:

```bash
$ helm upgrade bluecompute orders
```

2. Go to the `web-cluster` terminal window and run the following command:

```bash
$ helm upgrade bluecompute bluecompute-ce
```

The above commands will update the existing chart installations with the TLS options we just enabled.

### 5. Validate TLS in the Application
After waiting a few minutes after the install/upgrade you can validate the basic application functionality as explained [`here`](#3-validate-the-application). To validate that the web app is communicating with the orders microservice using TLS, do the following:

1. Login to the bluecompute app using `user` as username and `passw0rd` for password.
2. Click on any of the catalog items and place an order.
    + You should see a confirmation that the order was placed successfully.
3. Click on the `Profile` icon to retrieve the order you just placed.
    + You should be able to see the item you ordered, the amount, and the date.

The above steps should have triggered some logs in the `web` pod that shows the networking request to the `orders` microservice. To see the logs, use the following commands in the `web-cluster` terminal window:

First, grab the pod name for the web app:

```bash
$ kubectl get pods | grep web
bluecompute-web-84bc5f67d9-m5dbr                       1/1       Running             0          31s
```

Then copy the pod name above and get it's logs as follows:

```bash
$ kubectl logs -f <pod_name>
```

You should get a stream of logs similar to the following:
![POST logs](imgs/logs_post.png?raw=true)
![GET logs](imgs/logs_get.png?raw=true)

The above images show the POST request that was made when making a purchase followed by the GET request that was made when retrieving the orders in the Profile section. Notice that each requests uses `https://bluecompute-orders:443` as the URL for the orders microservice, showing that it's using TLS as indicated by the `https` protocol and the `443` port.

## Conclusion
While it's ideal to have microservices running together in the same infrastructure, sometimes isolated infrastructure is required for each workload. This prompts the need for secure and private connections between workloads, which can be tedious to setup. Luckily, we can easily achieve this with IBM Cloud Container Service by leveraging open standards from Kubernetes.

If you are interested in learning the ins and outs of IBM Cloud Container Service networking, I recommend you checkout a series of blogs published by the Cloud Architecture and Solution Engineering (CASE) team 
[here](https://www.ibm.com/blogs/bluemix/2017/05/kubernetes-and-bluemix-container-based-workloads-part1/).