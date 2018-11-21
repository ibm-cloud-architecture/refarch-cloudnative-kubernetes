# Adding Microservices to the Istio Service Mesh

## TLDR
### Installation
Here are all the commands to install Istio and an Istiofied version of Bluecompute.
```bash
# If using a Helm version prior to 2.10.0, install Istio’s Custom Resource Definitions via kubectl apply, and wait a few seconds for the CRDs to be committed in the kube-apiserver:
kubectl apply -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml

# Install Istio Chart and enable Grafana, Service Graph, and Jaeger (tracing)
helm upgrade --install istio --version 1.0.4 \
	--set grafana.enabled=true \
	--set servicegraph.enabled=true \
	--set tracing.enabled=true \
	ibm-charts/ibm-istio --namespace istio-system --tls

# Make sure all Istio-related pods are running before continuing
kubectl get pods -n istio-system -w

# Enable automatic sidecar injection on default namespace
kubectl label namespace default istio-injection=enabled

# If using ICP 3.1 and later, create an image policy that will allow Docker images from Docker Hub
kubectl apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/static/image_policy.yaml

# Install Istio-enabled Bluecompute Chart
# NOTE: The installation NOTES.txt will contain instructions on how to access Web app through Istio G
helm upgrade --install bluecompute --namespace default \
	--set global.istio.enabled=true \
	ibmcase/bluecompute-ce --tls
```

**NOTE:** The installation output will give you instructions on how to create a user in the customer database. Wait a few minutes and run the script mentioned in the installation output.

### Accessing Dashboards
Generate some load by opening the web application, logging in using `user/passw0rd`, then attempt to purchase a few items, followed by accessing the Profile tab to see all the orders. To access all of the Telemetry dashboards, run the following commands:
```bash
# Port-forward: Grafana, Service Graph, Jaeger (Tracing)
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &;
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &;
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 &;

# Open All Dashboards in your browser using the links below
http://localhost:3000/dashboard/db/istio-mesh-dashboard
http://localhost:8088/force/forcegraph.html
http://localhost:16686

# Kill Port-Forwarding
killall kubectl
```

### Cleanup
```bash
# Disable automatic sidecar injection on default namespace
kubectl label namespace default istio-injection-

# Delete Bluecompute chart
helm delete bluecompute --purge --tls

# Delete Istio chart
helm delete istio --purge --tls
```


## Introduction
The journey to cloud-native microservices comes with great tecnical benefits. As we saw in the microservices reference architecture (Bluecompute) we were able to individually deploy, update, test, and manage individual microservices that comprise the overall application. Also, by leveraging `Helm`, we are able to individually package these services into charts and package those into an umbrella chart that deploys the entire application stack in under 1 minute.

Having such flexibility comes at a price though. For example, the more microservices you have, the more complicated it becomes to manage, deploy, update, monitor, and debug them. Also, having more microservices makes it more difficult to start introducing things like Mutual TLS encryption, canary releases, and routing policies since implementing those things will vary dependending on the nature of each microservice (i.e. Java vs Node.js services), which means your team has to spend more time learning these things on each technology stack.

Luckily, the Kubernetes community is aware of these limitations and have provided us with the concept of a `Service Mesh`. The best known service mesh project is [`Istio`](https://istio.io/), which was co-developed by IBM and Google. Istio's aim is to helpo you connect, secure, control, and observe your services in a standardized and language-agnostic matter that doesn't require any code changes to the services.

In this document, we will deploy Istio into a Kubernetes envinronment (IBM Cloud Kubernetes Service or IBM Cloud Private) and explore some of its out the box features (Routing, Mutual TLS, Ingress Gateway, and Telemetry) after deploying the Bluecompute chart into the Istio-enabled environment.


## Requirements
* Kubernetes Cluster
	+ [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
	+ [IBM Cloud Private](https://www.ibm.com/cloud/private) - Create a Kubernetes cluster in an on-premise datacenter.  The community edition (IBM Cloud Private CE) is free of charge.  Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/installing.html) to install IBM Cloud Private CE.
* [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
* [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
	+ If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html) to install `helm`.
	+ If using IBM Cloud Kubernetes Service (IKS), please use the most up-to-date version of helm

## Deploy Istio
https://istio.io/docs/setup/kubernetes/spec-requirements/

## Blue-Compute Istiofied


### Architecture
ARCHITECTURE DIAGRAM GOES HERE

### Deployment-Based Services

### StatefulSet-Based Services

### Gateway



## Telemetry Example

### Generating Load

### Graphana

### Service Graph

### Jaeger - Tracing

### Kiali