# Exploring Istio Service Mesh Features with the Microservices Reference Architecture Application


## Table of Contents
  * [Introduction](#introduction)
  * [Requirements](#requirements)
  * [Blue-Compute Istiofied](#blue-compute-istiofied)
  * [Deploying Istio Helm Chart](#deploying-istio-helm-chart)
  * [Deploy Istiofied Bluecompute Helm Chart](#deploy-istiofied-bluecompute-helm-chart)
    + [Setup Helm Repository](#setup-helm-repository)
    + [Deploy the Chart](#deploy-the-chart)
    + [Validate the Application](#validate-the-application)
    + [Access Kiali Dashboard](#access-kiali-dashboard)
  * [Cleanup](#cleanup)
  * [Conclusion](#conclusion)

## Introduction

The journey to cloud-native microservices comes with great technical benefits. As we saw in the microservices reference architecture (Bluecompute) we were able to individually deploy, update, test, and manage individual microservices that comprise the overall application. By leveraging `Helm`, we are able to individually package these services into charts and package those into an umbrella chart that deploys the entire application stack conveniently and quickly.

Having such flexibility comes at a price though. For example, the more microservices you have, the more complicated it becomes to manage, deploy, update, monitor, and debug. Additionally, having more microservices makes it more difficult to start introducing new things like canary releases, routing policies, and Mutual TLS encryption. Since implementing those things will vary depending on the nature of each microservice (i.e. Java vs Node.js services), this means your team will have to spend more time learning how to implement those on each technology stack.

Thankfully, the Kubernetes community acknowledge these limitations and has provided us with the concept of a `Service Mesh`. As explained [here](https://istio.io/docs/concepts/what-is-istio/#what-is-a-service-mesh), the term "service mesh" describes the network of microservices that make up applications and the interactions between them. Examples of service mesh projects include [OpenShift](https://www.openshift.com/), developed by RedHat, and [`Istio`](https://istio.io/), co-developed by IBM and Google. Featured in Bluecompute, Istio aims to help you connect, secure, control, and observe your services in a standardized and language-agnostic way that doesn't require any code changes to the services.

## Requirements

* [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it onto your platform.
* [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
	+ If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html) to install `helm`.
	+ If using IBM Cloud Kubernetes Service (IKS), please use the most up-to-date version of helm

## Blue-Compute Istiofied

As with any complex application architecture, we had to make some changes to fully support the `bluecompute-ce` application in the Istio service mesh. Luckily, those changes were minimal but were necessary to leverage most of Istio's features and follow best practices.

## Setting up your Istio environment

We will be using IBM's official [Istio Helm Chart](https://github.com/IBM/charts/tree/master/stable/ibm-istio). This chart comes with an easy way to toggle on/off different Istio components, such as Ingress and Egress gateways, with a simple boolean. Also bundled in, the chart comes with non-Istio components such as Grafana, Service Graph, and Kiali, which we can also easily toggle on/off.

1) First, we must add the `IBM Cloud Charts` Helm repository with the command below:

```bash
helm repo add ibm-charts https://registry.bluemix.net/helm/ibm-charts
```

**NOTE: Before installing Istio!**  
If using Helm version prior to **2.10.0**, either upgrade your Helm version or install IBM Istio's Custom Resource Definitions (CRDs) with the command below. You will have to wait a few seconds for the changes to be committed to the kube-apiserver:

```bash
kubectl apply -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml
```

>It should be that noted above that if these CRDs were applied to a version greater than 2.10.0, an error similar to `Error: customresourcedefinitions.apiextensions.k8s.io "gateways.networking.istio.io" already exists` will appear. To resolve this conflict, delete the conflicting CRDs
>```
>kubectl delete crd gateways.networking.istio.io
>```
>
>If confident, you can delete all CRDs with a
>```
>kubectl delete crd --all
>```

2) To enable Kiali, an open source project that seeks to visualize your service mesh topology, we will need to create a secret containing a username and passphrase to access the Kiali dashboard.

```bash
# Username and Passphrase in base64 format
DASHBOARD_USERNAME=$(echo -n 'admin' | base64);
DASHBOARD_PASSPHRASE=$(echo -n 'secret' | base64);

# Namespace
NAMESPACE="istio-system";

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $DASHBOARD_USERNAME
  passphrase: $DASHBOARD_PASSPHRASE
EOF
```

3) Now we can deploy the Istio chart in the `istio-system` namespace as follows:

```bash
# Install Istio Chart and enable Grafana, Service Graph, and Jaeger (tracing)

helm upgrade --install istio --version 1.0.4 \
	--set grafana.enabled=true \
	--set servicegraph.enabled=true \
	--set tracing.enabled=true \
	--set kiali.enabled=true \
	ibm-charts/ibm-istio --namespace istio-system
```

If you want to disable select features, simply set the desired feature to `false`

You can check the availability of your Istio pods with the following waiting command:

```bash
kubectl get pods -n istio-system -w
```

4) Istio works best when you leverage its automatic sidecar injection feature, which automatically puts all of the YAML pertaining to the Istio sidecar into your deployments/pods upon deployment. 

To leverage Istio's automatic sidecar injection feature, we need to enable it by labeling the namespace in which you will leverage this feature. We will use the `default` namespace, which you can label with:

```bash
kubectl label namespace default istio-injection=enabled
```

## Deploying the Istio Bluecompute Helm Chart

Now let's proceed with installing the `bluecompute` chart itself as follows:

1) Add the remote Helm chart repository:

```bash
# Add Helm repository
helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce

# KEVIN/JJ Test this link
helm repo add bluecompute-mp https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/microprofile/bluecompute-mp

# Refresh Helm repositories
helm repo update
```

Now, using the edited values file, install the chart with the command below:

```bash
# Install helm chart
helm upgrade --install bluecompute --namespace default \
	-f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/bluecompute-ce/values-istio-gateway.yaml
```

It should take a few minutes for all of the pods to be up and running. Run the following command multiple times until all of the pods show a status of `RUNNING`.
```bash
kubectl get pods
```

### Validate the Application
In order to validate the application, you will need to access the IP address and port number of the Ingress Gateway, which will depend on the environment you are using. To access the IP address and port number, run the commands below based on your environment:

```bash
# IKS Standard Clusters
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

# IKS Free Clusters
export INGRESS_HOST=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
export INGRESS_PORT=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')

# IBM Cloud Private Cluster
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
export INGRESS_PORT=$(kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')

# Print the Gateway URL
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo $GATEWAY_URL
```

To validate the application, open a browser window and enter the gateway URL from above and press enter. You should be able to see the web application's home page, as shown below.

![BlueCompute Detail](../../static/imgs/bluecompute_web_home.png?raw=true)

You can reference [this link](https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/tree/spring#validate-the-web-application) to validate the web application functionality. You should be able to see a catalog, be able to login, make orders, and see your orders listed in your profile (once you are logged in).

### Access the Kiali Dashboard
Using Grafana, Service Graph, and Jaeger tracing should give you more than enough information to learn your application's networking architecture, identify bottlenecks, and debug networking calls. This information alone is plenty to out carry day-to-day operations. However, there are instances when the tracing shows that a service is working as expected, but somehow, networking calls to other services still fail. Sometimes the issue comes from a bug in the individual service's Istio configuration, which you cannot access with the above mention dashboards.

Luckily, Kiali can help you with that. Kiali is an open source project that works with Istio to visualize the service mesh topology, including features like circuit breakers or request rates. Kiali even includes Jaeger Tracing out of the box.

To access the Kiali dashboard, you will need to run the following port-forwarding command:
```bash
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001 &;
```

Now, open a new browser tab and go to http://localhost:20001/kiali to open Kiali dashboard, as shown below:
![Architecture](../../static/imgs/istio/kiali_1_login.png)

Login using `admin` and `secret` as the username and password, respectively, which come from the secret that you setup earlier when deploying Istio. If successful, you will be presented with the home page, which shows a graph of the services from all of the namespaces in your cluster.
![Architecture](../../static/imgs/istio/kiali_2_home.png)

The above can be overwhelming to look at. Instead of looking at the entire cluster, let's just focus on the services in the `default` namespace, which is where `bluecompute-ce` is deployed. To view the services in the `default` namespace, click on the `Namespace` drop-down and select `default`, which should present you with the following view:
![Architecture](../../static/imgs/istio/kiali_3_default_graph.png)

You should now see a much cleaner chart showing the services pertaining to `bluecompute-ce`. I personally like this graph better compared to `Service Graph`. From this graph you can click on the individual links between microservices and explore the request volume per second. Let's see what that looks like by clicking on the link between the `istio-ingressgateway` and `web` service, which should present you with the following view:
![Architecture](../../static/imgs/istio/kiali_4_gateway_web.png)

Notice above that you can see the requests per second and graphs for different status codes. Also notice in the `Source app` and `Destination app` that you can see namespace and version of the microservices in question. Feel free to explore the other application links.

If you click on the `Applications` menu on the left, followed by clicking on the `web` application, you will be able to see high level metrics for the application. Mostly the status of the health status of the deployment and the envoy side car and Inbound and Outboud metrics, as shown below:
![Architecture](../../static/imgs/istio/kiali_5_web_status.png)

If you click on the `Workloads` menu on the left, followed by clicking on the `web` workload, you will be able to see pod specific information and metrics, including labels, container name and init container names, as shown below:
![Architecture](../../static/imgs/istio/kiali_6_workloads_web_info.png)

If you click on the `Services` menu on the left, followed by clicking on the `catalog` service, you will be able to see service specific information and metrics, but also workloads that the service is associated with and source workloads from which it gets networking calls, as shown below. More importantly, you can also see the `Virtual Services` and `Destination Rules` associated with the service and their configuration. You can even click on `View YAML` to explore the actual YAML file that was used to deploy the Istio resources, which is great for debugging Istio configuration.
![Architecture](../../static/imgs/istio/kiali_7_services_catalog_destination.png)

Lastly, if you want to only see a list of Istio resources, you can click on the `Istio Config` menu on the left. You will see things like `Virtual Services`, `Destination Rules`, and even `Gateways`.
![Architecture](../../static/imgs/istio/kiali_8_istio_config.png)

The above should have provided you a high level view of Kiali's features and visibility into the Istio Service Mesh. Combined with Jaeger Tracing and even Grafana dashboard, if enabled, you should be able to use Kiali as the main entrypoint for all things service mesh.

## Cleanup
To kill all port-forwarding connections, run the following command:
```bash
killall kubectl
```

To delete Kiali secret, run the following command:
```bash
kubectl delete secret kiali -n istio-system
```

To disable automatic sidecar injection, run the following command:
```bash
kubectl label namespace default istio-injection-
```

To uninstall `bluecompute-ce` chart, run the following command:
```bash
helm delete bluecompute --purge # --tls if using IBM Cloud Private
```

Lastly, to uninstall `istio` chart, run the following command:
```bash
helm delete istio --purge # --tls if using IBM Cloud Private
```

## Conclusion
Congratulations for finishing reading this document. That was a lot of information. Let's recap the stuff we learned today:
* Minimum requirements to allow pods to benefit from the service mesh features.
* How to properly create liveness and readiness probes that will work in a service mesh, even when Mutual TLS is enabled.
* Istio's current limitations with StatefulSet-based services and how to to get Deployment-based Istiofied services to communicate with StatefulSet services outside of the service mesh.
* How to create custom Istio YAML files for more granular control of Istio configuration for each microservice.
* Deployed Istio and enabled Grafana, Service Graph, Jaeger Tracing, and Kiali dashboards.
* Deployed the Bluecompute into Istio-enabled cluster and enabled Istio Gateway.
* Generated networking load against Istio Gateway to generate telemetry and tracing metrics for the web and catalog services.
* Used Grafana to visualize the networking request volume on both services.
* Used Service Graph to visualize Bluecompute's entire network architecture and view inbound and outbound request volume on each service.
* Used Jaeger to search and analyze network traces for calls between the web and catalog services.
* Used Kiali to do all the above plus exploring Istio configuration for each service.

By doing all the above, you now have the ability to modify existing services/applications to leverage most of the Istio service mesh features and debug running applications using Istio's telemetry and tracing information.