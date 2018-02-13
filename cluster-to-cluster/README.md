# Microservice to Microservice Communication across clusters using Private Network
Deploying microservices works great inside a single Kubernetes cluster. But what if your microservices need to communicate with other microservices that are deployed in a separate cluster? Better yet, how can you talk with those microservices using an encrypted connection through a private network for added security? Let's see how you can do that with IBM Cloud Container Service (ICCS).

## Pre-requisites
- Install the following CLIs:
    * [IBM Cloud account](https://www.ibm.com/cloud-computing/bluemix/containers)
    * [IBM Cloud CLI](https://console.bluemix.net/docs/containers/container_index.html)
    * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    * [helm](https://github.com/kubernetes/helm/blob/master/docs/install.md)
- Clone the repo and cd to `cluster-to-cluster`:

```
$ git clone https://github.com/fabiogomezdiaz/refarch-cloudnative-kubernetes
$ refarch-cloudnative-kubernetes/cluster-to-cluster
```

## Architecture Overview
COMING SOON

We are going to deploy the `bluecompute-ce` chart as follows:
- Deploy the `orders` chart, which contains `ibmcase-orders-mysql` as a dependency chart, into one cluster, which we are going to call `orders-cluster`
- Deploy the `bluecompute-ce`, which does not contain neither `orders` nor its dependent `ibmcase-mysql` chart, into a separate cluster, which we are going to call `web-cluster`.
- The `orders` service in the `orders-cluster` will be exposed privately to the `web` service in the `web-cluster` via a `Private Application Load Balancer` (ALB) 
- We will be enabling TLS on the `orders-cluster` Private ALB to add an extra layer of security.


## Setup
### 1. Enable VLAN Spanning
In order for the clusters to talk to each other via Private Network, we need to turn on `VLAN Spanning`.
- Use [these](https://knowledgelayer.softlayer.com/procedure/enable-or-disable-vlan-spanning) instructions to turn on VLAN Spanning.


### 2. Deploy 2 standard clusters
For this demo, we are going to create `2 Standard Clusters`:
- Let's call the 1st cluster `orders-cluster`.
    * In here, we are going to deploy the `orders` chart, which includes the `orders` and `ibmcase-orders-mysql` charts
- Let's call the 2nd cluster `web-cluster`.
    * In here, we are going to deploy the `bluecompute-ce` chart, which includes the charts for the rest of the microservices, minus the `orders` chart

To provision the 2 Standard Cluster, follow [these](https://console.bluemix.net/docs/containers/cs_clusters.html#clusters_ui) instructions.

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
    - Get kubectl context for the `orders-cluster` if you have not done so already.
- Get the `ALB ID` for the Private ALB:

```bash
$ bx cs albs --cluster <orders-cluster-name>

OK
ALB ID                                                Enabled   Status     Type      ALB IP
private-cr708a92bffbde4569a04273eb64b3ff04-alb1       true      enabled    private   10.184.13.192
```

- Paste it in the `loadBalancerID` field inside the [orders/values.yaml](https://github.com/fabiogomezdiaz/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/orders/values.yaml) file and save it.
- Deploy the orders chart:

```bash
$ helm install --name bluecompute orders
```

NOTE: For details on the contents of the orders chart, see the files in the `orders` folder. Particularly, check out `orders/templates/ingress.yaml` to check out the ingress resource.

### 2. Deploy the `bluecompute-ce` chart in the `web-cluster`
Now that we deployed `orders` chart in `orders-cluster`, we can deploy the `bluecompute-ce` chart in the `web-cluster` and have it communicate to `orders` service over the private network. But first, let's cover `Custom Endpoints` a little bit, since it is the main Kubernetes feature we are leveraging. Then we will proceed to deploying the `bluecompute-ce` chart.

#### a. Custom Endpoints Overview
We want the `web` application to communicate with the `orders` service in the `orders-cluster` the same way it does it when the `orders` service is in the same cluster as the `web` application. In other words, we wanted the `web` application to reference the `orders` service using its [kube-dns](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) name of `http://orders-service:8080` even if the `orders` service is in another cluster.

In order to accomplish cluster to cluster communication without changing any application code or edit the existing YAML files in the `web` chart, we created the following in the `bluecompute-ce` chart's templates folder:
- A custom `Service` for `orders` service:
    * This service will point to a custom `Endpoint` for `orders` service in `orders-cluster`, explained below.
    * For details on the custom endpoint, checkout the [`bluecompute-ce/templates/ordersEndpoint.yaml`](https://github.com/fabiogomezdiaz/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/templates/ordersService.yaml) file.
- A custom `Endpoint` for `orders` service:
    * This endpoint contains the IP address of the Private ALB in the `orders-cluster` and port 80 for the Ingress.
        + We are leveraging a Kubernetes feature called `Headless services Without selectors`, which you can learn about [here](https://kubernetes.io/docs/concepts/services-networking/service/#without-selectors)
    * Since we are not enabling `Transport Layer Security` (TLS) in the `orders-cluster` ingress yet (which will do in a later section) the endpoint will contain port 80 for the Ingress.
    * For details on the custom endpoint, checkout the [`bluecompute-ce/templates/ordersEndpoint.yaml`](https://github.com/fabiogomezdiaz/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/templates/ordersEndpoint.yaml) file.


#### b. Deploy the `bluecompute-ce` chart
To deploy the `bluecompute-ce` chart, follow the instructions below:
- Go to the `orders-cluster` terminal window.
- Get the `ALB IP` address for the Private ALB:

```bash
$ bx cs albs --cluster <orders-cluster-name>

OK
ALB ID                                                Enabled   Status     Type      ALB IP
private-cr708a92bffbde4569a04273eb64b3ff04-alb1       true      enabled    private   10.184.13.192
```

- Paste it in the `loadBalancerIp` in the `orders` section inside the [`bluecompute-ce/values.yaml`](https://github.com/fabiogomezdiaz/refarch-cloudnative-kubernetes/blob/master/cluster-to-cluster/bluecompute-ce/values.yaml) file and save it.

- Now go to the `web-cluster` terminal window.
    - Get kubectl context for the `web-cluster` if you have not done so already.
- Deploy the `bluecompute-ce` chart:

```bash
$ helm install --name bluecompute bluecompute-ce
```

NOTE: For details on the contents of the orders chart, see the files in the `orders` folder. Particularly, check out `orders/templates/ingress.yaml` to check out the ingress resource.

### 3. Validate the Application
You can reference [this link](https://github.com/fabiogomezdiaz/refarch-cloudnative-bluecompute-web/tree/kube-int#validate-the-deployment) to validate the sample web application.

![BlueCompute Detail](https://raw.githubusercontent.com/fabiogomezdiaz/refarch-cloudnative-kubernetes/master/static/imgs/bluecompute_web_home.png)

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


### Enable TLS
COMING SOON