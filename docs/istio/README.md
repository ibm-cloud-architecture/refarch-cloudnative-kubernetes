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
	-f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/bluecompute-ce/values-istio-basic.yaml \
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

## Creating Wildcard Certificate
```bash
# Clone Repo
git clone https://github.com/nicholasjackson/mtls-go-example

# Go to repo directory
cd mtls-go-example

# Generate Wildcard certificate
./generate.sh "*.bluecompute.com" passw0rd

# Create bluecompute folder and move all certificates to it
mkdir bluecompute.com && mv 1_root 2_intermediate 3_application 4_client bluecompute.com

# Add this entry to your /etc/hosts
169.62.38.242 auth.bluecompute.com catalog.bluecompute.com inventory.bluecompute.com customer.bluecompute.com orders.bluecompute.com web.bluecompute.com
```

Create secret:
```bash
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key bluecompute.com/3_application/private/*.bluecompute.com.key.pem --cert bluecompute.com/3_application/certs/*.bluecompute.com.cert.pem
```



## Introduction
The journey to cloud-native microservices comes with great technical benefits. As we saw in the microservices reference architecture (Bluecompute) we were able to individually deploy, update, test, and manage individual microservices that comprise the overall application. By leveraging `Helm`, we are able to individually package these services into charts and package those into an umbrella chart that deploys the entire application stack in under 1 minute.

Having such flexibility comes at a price though. For example, the more microservices you have, the more complicated it becomes to manage, deploy, update, monitor, and debug them. Also, having more microservices makes it more difficult to start introducing things like canary releases, routing policies, and Mutual TLS encryption since implementing those things will vary depending on the nature of each microservice (i.e. Java vs Node.js services), which means your team has to spend more time learning how to implement those things on each technology stack.

Luckily, the Kubernetes community is aware of these limitations and has provided us with the concept of a `Service Mesh`. As explained [here](https://istio.io/docs/concepts/what-is-istio/#what-is-a-service-mesh), the term service mesh is used to describe the network of microservices that make up such applications and the interactions between them. The best known service mesh project is [`Istio`](https://istio.io/), which was co-developed by IBM and Google. Istio's aim is to help you connect, secure, control, and observe your services in a standardized and language-agnostic matter that doesn't require any code changes to the services.

In this document, we will deploy Istio into a Kubernetes envinronment (IBM Cloud Kubernetes Service or IBM Cloud Private) and explore some of its out the box features (Routing, Mutual TLS, Ingress Gateway, and Telemetry) after deploying the Bluecompute chart into the Istio-enabled environment.


## Requirements
* Kubernetes Cluster
	+ [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
	+ [IBM Cloud Private](https://www.ibm.com/cloud/private) - Create a Kubernetes cluster in an on-premise datacenter.  The community edition (IBM Cloud Private CE) is free of charge.  Follow the instructions [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/installing.html) to install IBM Cloud Private CE.
* [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it on your platform.
* [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
	+ If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html) to install `helm`.
	+ If using IBM Cloud Kubernetes Service (IKS), please use the most up-to-date version of helm

## Deploying Istio Chart
To deploy Istio into either an IBM Cloud Kubernetes Service (IKS) or IBM Cloud Private (ICP) cluster, we will be using IBM's official [Istio Helm Chart](https://github.com/IBM/charts/tree/master/stable/ibm-istio). The benefit of using the chart is that it's easier to toggle on/off different Istio components such as Ingress and Egress gateways. The chart also comes bundled with non-Istio components such as Grafana, Service Graph, and Kiali, which we can also toggle on/off. Today we are going to deploy the Istio chart with the following components enabled:
* Ingress Gateway
* Grafana
* Service Graph
* Jager (Tracing)
* Kiali


To deploy the chart we have to add the `IBM Cloud Charts` Helm repository as follows:
```bash
helm repo add ibm-charts https://registry.bluemix.net/helm/ibm-charts
```

If using a Helm version prior to 2.10.0, install Istio’s Custom Resource Definitions via kubectl apply, and wait a few seconds for the CRDs to be committed in the kube-apiserver:
```bash
kubectl apply -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml
```

Now we can deploy the Istio chart in the `istio-system` namespaces as follows:
```bash
# Install Istio Chart and enable Grafana, Service Graph, and Jaeger (tracing)
helm upgrade --install istio --version 1.0.4 \
	--set grafana.enabled=true \
	--set servicegraph.enabled=true \
	--set tracing.enabled=true \
	ibm-charts/ibm-istio --namespace istio-system --tls

```

**NOTE:** At the time of writing, Istio 1.0.4 is the latest Istio version that the Helm chart supports.

Before moving forward, Make sure all Istio-related pods are running as follows:
```bash
kubectl get pods -n istio-system -w
```

Istio works best when you leverage its automatic sidecar injection feature, which automatically puts all of the YAML pertaining to the Istio side car into your deployments/pods upon deployment. In order to leverage Istio's automatic sidecar injection feature, we need to enable it by labeling the namespace that will leverage this feature. In our case we will use the `default` namespace, which you can label as follows:
```bash
kubectl label namespace default istio-injection=enabled
```

You have successfully deployed the Istio chart and enabled automatic sidecar injection on the `default` namespace! Before installing the `bluecompute-ce` helm chart, let's first take a look at the changes & considerations we had to make to make the `bluecompute-ce` chart Istio compatible

## Blue-Compute Istiofied
As with any complex application architecture, we had to make some changes to fully support the `bluecompute-ce` application in the Istio service mesh. Luckily, those changes were minimal but were necessary to leverage most of Istio's features and follow best practices.

### Architecture
ARCHITECTURE DIAGRAM GOES HERE

### Requirements for Pods and Services
Istio needs basic information from each service in order to do things such routing traffic between multiple service versions and also add contextual information for its distributed tracing and telemetry features.

The first requirement, which luckily we had already implemented, was to name the service ports using the protocol name. For the bluecompute service, the service ports were named `http`.

The second requirement was to have explicit `app` and `version` labels for each service deployment. Having these labels provides Istio with the enough context for its routing, tracing, and telemetry features, which will explore in later sections.

Here is the YAML for the `inventory` service, which as you can see, includes the named `http` port and both the `app` and `version` labels:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: inventory
    chart: inventory-0.6.0
    heritage: Tiller
    release: bluecompute
    tier: backend
    version: v1
  name: inventory
  namespace: default
spec:
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: inventory
    chart: inventory-0.6.0
    heritage: Tiller
    release: bluecompute
    tier: backend
    version: v1
  type: ClusterIP
```

And here is a trimmed down version of the `inventory` deployment, which shows the `app` and `version` labels:
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: inventory
    chart: inventory-0.6.0
    heritage: Tiller
    release: bluecompute
    tier: backend
    version: v1
  name: inventory
  namespace: default
spec:
  selector:
    matchLabels:
      app: inventory
      chart: inventory-0.6.0
      heritage: Tiller
      release: bluecompute
      tier: backend
      version: v1
  template:
    metadata:
      labels:
        app: inventory
        chart: inventory-0.6.0
        heritage: Tiller
        release: bluecompute
        tier: backend
        version: v1
    spec:
      containers:
...
```

To learn more about all the requirements for pods and services, please look at Istio's official documentation below:
https://istio.io/docs/setup/kubernetes/spec-requirements/

### Liveness and Readiness Probes
Liveness and Readiness probes are used in Kubernetes to run continuous health checks to determine if a deployment is healthy or not. When you bring Istio into the picture, the probes may stop working if you enable Mutual TLS encryption between services, which makes Kubernetes erroneously think that the services are unhealthy. The reason they stop working is because the liveness and readiness probes are run by the kubelets, which are not part of the service mesh and, therefore, do not benefit from Istio's Mutual TLS.

The `bluecompute-ce` service originally did not have any liveness and readiness probes, so none of the services were affected. But since we are committed to explore most of Istio's features through `bluecompute-ce`, we decided to add our own Liveness and Readiness probes to each service.

Since we knew in advance that we wanted to use Mutual TLS between our services, we knew we had to find a way to implement liveness and readiness probes that would work in environments with Mutual TLS enabled or disabled.

The best approach we found was to open a separate non-Istiofied port that would only serve the `/health` endpoint. We accomplished this by enabling the [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-endpoints.html) endpoints on a separate port. By implementing this approach, we separated the service's application endpoints (which will be protected by Istio's Mutual TLS) from the its health endpoints (which we can afford to leave in in plain HTTP).

To implement the actuator feature, we first had to add the actuator dependency on the services' `build.gradle` files. Here is a snippet of that would look like:
```gradle
dependencies {
	...
	compile("org.springframework.boot:spring-boot-starter-actuator")
	...
}
```

To enable the actuator feature itself on a separate port, we have to specify the new port in the `application.yml` file. Here is a snippet of the `application.yml` file from the Inventory service, where we enabled the actuator endpoints on a separate port:
```yaml
...
# Server configuration
server:
  context-path: /micro
  port: ${SERVICE_PORT:8080}

management:
  port: ${MANAGEMENT_PORT:8090}
...
```

Now if you run the application locally, you can curl the `/health` endpoint on its management port and you will get its current health status in JSON format. To expose this port in a container, you have to add the new port to its list of exposed ports in its Dockerfile. For the Inventory service, the `EXPOSE` line in its Dockerfile will list the 2 ports as follows:
```Dockerfile
EXPOSE 8080 8090
```

Finally, now the we went over the above, here is a snippet of what the Inventory Deployment YAML will look like with the Liveness and Readiness Probes enabled:
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
...
spec:
...
  template:
...
    spec:
      containers:
        name: inventory
...
        livenessProbe:
          failureThreshold: 6
          httpGet:
            path: /health
            port: 8090
            scheme: HTTP
          initialDelaySeconds: 35
          periodSeconds: 20
          successThreshold: 1
          timeoutSeconds: 1
        readinessProbe:
          failureThreshold: 6
          httpGet:
            path: /health
            port: 8090
            scheme: HTTP
          initialDelaySeconds: 20
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        ports:
        - containerPort: 8080
          protocol: TCP
...
```

With the above implemented, we are able to constantly monitor our services with Liveness and Readiness probes while leveraging Istio's Mutual TLS, if enabled!

To learn more about Liveness and Readiness Probes with Istio, check out the document below:
* https://istio.io/docs/tasks/traffic-management/app-health-check/

To accomplish the above in the `bluecompute-web` service, which is a Node.JS app, we had to instantiate a separate Express server that listens on a different port and only serves a custom `/health` endpoint, similar to the Spring Boot services. To learn more about how that was accomplished, check out the git commit below:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-bluecompute-web/commit/7de6a4431e478435b3f34144652d8005483d3bdb

### StatefulSet-Based Services
In the `bluecompute-ce` chart we use a combination of Deployment and StatefulSet services to run the entire application. The StatefulSet service in the `bluecompute-ce` application include `Elasticsearch`, `MariaDB`, and `CouchDB`. These services benefit from StatefulSets because they provide a sticky identity for each of their pods, which is essential to keep the stateful nature of these services.

Unfortunately, Istio does not fully support StatefulSets yet, which prevents the Elasticsearch, MariaDB, and CouchDB services from starting. If you look at the following document, it says that if you disable Mutual TLS, the StatefulSet services should just work, but that's not the case for these workloads:
* https://istio.io/docs/setup/kubernetes/quick-start/#option-1-install-istio-without-mutual-tls-authentication-between-sidecars

**NOTE:** If you want to find out more about Istio and StatefulSets and whether it will be supported, here is an issue that is currently tracking support for StatefulSets in Istio:
* https://github.com/istio/istio/issues/10659

In the meantime, we had to figure out another way to make the StatefulSet services work in Istio, even when Mutual TLS is enabled for the non-StatefulSet workloads. After doing some reading, we ended up doing the following:
* Disabling automatic sidecar injection in Elasticsearch, MariaDB, and CouchDB.
	+ We accomplished this by passing the `sidecar.istio.io/inject: "false"` annotation to their respective StatefulSets. Here is how it was done for each of those services:
		- [bluecompute-ce/values-istio-basic.yaml#L166](../../bluecompute-ce/values.yaml#L166)
		- [bluecompute-ce/values-istio-basic.yaml#L166](../../bluecompute-ce/values.yaml#L175)
		- [bluecompute-ce/values-istio-basic.yaml#L166](../../bluecompute-ce/values.yaml#L184)
		- [bluecompute-ce/values-istio-basic.yaml#L166](../../bluecompute-ce/values.yaml#L265)
		- [bluecompute-ce/values-istio-basic.yaml#L166](../../bluecompute-ce/values.yaml#L413)
		- [bluecompute-ce/values-istio-basic.yaml#L166](../../bluecompute-ce/values.yaml#L424)
	+ This effectively takes out the services from the service mesh, which allowed them to start normally.
	+ However, by leaving the services out from the service mesh, we are preventing the services in the service mesh from communicating with these services when Mutual TLS is enabled, which we overcame with the following.
	+ **NOTE:** Luckily, the Elasticsearch and MariaDB helm charts had the ability to let you provide custom annotations. However, for the CouchDB, we had to fork and edit the chart to enable the ability to provide custom annotations, as shown in the commit below:
		- https://github.com/fabiogomezdiaz/charts/commit/eb51b4f7f66837830385292b7d6220f8048a9537
* Created `DestinationRules` that explicitly indicate that Mutual TLS is not needed to communicate with Elasticsearch, MariaDB, and CouchDB.

Here is a snippet of the Elasticsearch `DestinationRule`, where we disble the need for Mutual TLS:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: {{ template "bluecompute.elasticsearch.client.fullname" . }}
spec:
  host: {{ template "bluecompute.elasticsearch.client.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 9200
      tls:
        mode: DISABLE
    - port:
        number: 9300
      tls:
        mode: DISABLE
```

By doing the above for Elasticsearch, MariaDB, and CouchDB, the services were able to start and we were able to have the Istio-enabled services communicate with them. If you are curious what all the Destination Rules look like for these services, take a look at them here:
* [bluecompute-ce/templates/istio_destination_rules.yaml](../../bluecompute-ce/templates/istio_destination_rules.yaml)

**NOTE:** The following article was useful for determining when to disable sidecar injection.
* https://istio.io/help/ops/setup/injection/

### Custom Istio YAML Files
By doing the stuff we talked about above, the entire `bluecompute-ce` application is now able to leverage most of Istio's features automatically, such as automatic sidecar injection, Mutual TLS, Telemetry and Tracing.

It is great to have Istio automatically inject sidecars, configure Authentication Policies (Mutual TLS), Destination Rules, and Virtual Services for you. However, sometimes your individual services might require more granular control. Perhaps not all application services can benefit from or require Mutual TLS. Perhaps, like in the case with Elasticsearch, MariaDB, and CouchDB, not all of your existing application services meet the requirements for service mesh support and must be handled on a 1x1 basis. In such cases, having Istio automatically handle everything for you is not ideal and you have to manually configure Istio settings for your services.

In this section, we are going to cover 3 basic Istio YAML files that are present on each microservice's Helm chart:
* Authentication Policy.
* Destination Rule.
* Virtual Service.
* Gateway.

#### Authentication Policy
Istio allows you to configure Transport Authentication (Mutual TLS), also known as service-to-service authentication, on multiple levels: cluster, namespace, and service. To create a Service-specific Policy, let's look at the Inventory service policy:
```yaml
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: {{ template "inventory.fullname" . }}
spec:
  targets:
  - name: {{ template "inventory.fullname" . }}
    ports:
    - number: {{ .Values.service.externalPort }}
  peers:
  {{- if eq .Values.istio.mTLS "ISTIO_MUTUAL" }}
  - mtls: {}
  {{- end }}
```
Where:
* `spec.targets[0].ports[0].number` is the service port where this policy will be applied.
	+ **NOTE:** This port is the service's application port, and NOT the management/health port used in liveness and readiness probes.
* `spec.peers[0].mtls` is section that, if provided, enables Mutual TLS for the port above.
	+ At the time of writing, there are no additional settings to configure for Mutual TLS, hence the value of `{}` in the `mtls` field.

By using the above service-specific policy, Istio will isolate this service from any namespace or cluster specific policies.

To learn more about Authentication Policies, read the following document:
* https://istio.io/docs/concepts/security/#authentication-policies

#### Destination Rule
A `DestinationRule` configures the set of policies to be applied to a request after VirtualService (explained in the following section) routing has occurred. They describe the circuit breakers, load balancer settings, TLS settings, and other settings for a specific service. A single `DestinationRule` can also include settings for multiple subsets/versions of the same service. Let's take a look at the Inventory service Destination Rule:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: {{ template "inventory.fullname" . }}
spec:
  host: {{ template "inventory.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: {{ .Values.istio.loadBalancer }}
    portLevelSettings:
    - port:
        number: {{ .Values.service.externalPort }}
      tls:
        mode: {{ .Values.istio.mTLS }}
  subsets:
  - name: v1
    labels:
      version: v1
```

Where:
* `spec.host` is the Fully Qualified Domain Name of the service in question.
* `spec.trafficPolicy.loadBalancer.simple` is where you define the type of load balancing to apply on the service.
* `spec.trafficPolicy.portLevelSettings` is where you specify the TLS mode for this service and the port number to apply it to.
	+ **NOTE:** This port is the service's application port, and NOT the management/health port used in liveness and readiness probes.
* `spec.subsets` is where list the available subsets/versions of the service and their individual settings, if any.
	+ If not version-specific settings are passed here, each version will inherit the settings listed above.


To learn more about Destination Rules, read the following document:
* https://istio.io/docs/concepts/traffic-management/#destination-rules

#### Virtual Service
The last thing. A `VirtualService` defines the rules that control how requests for a service are routed within an Istio service mesh. For example, a virtual service could route requests to different versions of a service or to a completely different service than was requested. Requests can be routed based on the request source and destination, HTTP paths and header fields, and weights associated with individual service versions. Let's take a look at the Inventory service Virtual Service:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{ template "inventory.fullname" . }}
spec:
  hosts:
  {{- if or .Values.istio.gateway.enabled .Values.istio.gateway.name .Values.global.istio.gateway.name }}
  {{ toYaml .Values.istio.gateway.hosts }}
  {{- else }}
  - {{ template "inventory.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
  {{- end }}
  {{- template "inventory.istio.gateway" . }}
  http:
  - match:
    - uri:
        prefix: {{ .Values.ingress.path }}
    route:
    - destination:
        host: {{ template "inventory.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
        port:
          number: {{ .Values.service.externalPort }}
        subset: v1
```

Where:
* `spec.hosts` is where you specify the Fully Qualified Domain Names (FQDN) of the service in question.
	+ As you can see, in this field there is some logic that determines which FQDN to use, which can be a single hostname of multiple.
	+ When an Istio Gateway (explained in the following section) is used to expose the service outside of the cluster, you need to provide the FQDN(s) that is used to access that service in this list so that the Virtual Service can route the external request to the correct service.
	+ If not using a Gateway, then you need provide the internal FQDN for the service, which is in the form of `service.namespace.svc.cluster.local`.
* * `spec.gateways` is where you provide the gateway names, if any, to bind the Virtual Service to in order to route external cluster traffic to the service.
	+ **NOTE:** You can't see `spec.gateways` field in the YAML above directly because we are using a Helm template to handle the gateway logic. Having an empty list of gateway names will cause an error.
* `spec.http[0].match[0].uri.prefix` is where you specify the request path(s) that will be routed to the service.
* `spec.http[0].route[0].destination.host` is the FQDN of the service to route the request path to.
	+ This is useful if you want to route different paths to different subsets/versions of your service.
* `spec.http[0].route[0].destination.port.number` is the application port number for the service subset/version.
* `spec.http[0].route[0].destination.subset` is the subset/version to route the request to.

Even though we are only using one subset/version for our service, from the YAML above you can already see how easy it is to apply routing rules for multiple service versions from one place.

To learn more about Virtual Services, read the following document:
* https://istio.io/docs/concepts/traffic-management/#virtual-services

#### Gateway
The last custom Istio YAML file we are going to look at is an Istio Gateway. A `Gateway` configures a load balancer for HTTP/TCP traffic, most commonly operating at the edge of the mesh to enable ingress traffic for an application.

Unlike Kubernetes Ingress, Istio Gateway only configures the L4-L6 functions (for example, ports to expose, TLS configuration). Users can then use standard Istio rules to control HTTP requests as well as TCP traffic entering a Gateway by binding a VirtualService to it. Let's take a look at the Inventory service Gateway:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: {{ template "inventory.fullname" . }}-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    tls:
      httpsRedirect: {{ .Values.istio.gateway.TLS.httpsRedirect }}
    hosts:
    {{ toYaml .Values.istio.gateway.hosts }}
{{- if .Values.istio.gateway.TLS.enabled }}
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: {{ .Values.istio.gateway.TLS.mode }}
      serverCertificate: {{ .Values.istio.gateway.TLS.serverCertificate }}
      privateKey: {{ .Values.istio.gateway.TLS.privateKey }}
{{- if and (eq .Values.istio.gateway.TLS.mode "MUTUAL") .Values.istio.gateway.TLS.caCertificates }}
      caCertificates: {{ .Values.istio.gateway.TLS.caCertificates }}
{{- end }}
    hosts:
    {{ toYaml .Values.istio.gateway.hosts }}
```

Where:
* `spec.servers[0].port` is where you can specify the port number (80 or 443), name, and protocol (HTTP or HTTPS) supported by the Gateway.
* `spec.servers[0].tls` is where you can provide TLS settings for the port, such as `httpsRedirect` (to redirect HTTP traffic to HTTPS), TLS mode (Simple TLS, Mutual TLS, or none), and TLS certificate files (via `serverCertificate`, `privateKey`, and `caCertificates`).
* `spec.servers[0].hosts` is where you provide the external FQDN(s) used to route traffic into the cluster.

Remember that in order to leverage the gateway, the gateway must be bound to a `Virtual Service` by putting the gateway name in the `spec.gateways` field of the Virtual Service, as shown in the previous section.

Assuming you enabled the gateway and bound it to the Virtual Service correctly, Istio will route external traffic to your service and collect Telemetry and Tracing information for it as well.

To learn more about Gateways, read the following document:
* https://istio.io/docs/concepts/traffic-management/#gateways

#### Istio YAML files in the main bluecompute-ce chart
All the Istio YAML files we talked about in the sections above are mostly specific to the individual microservice charts. The main `bluecompute-ce` leverages those YAML files along with additional Istio YAML files meant for the services Community Charts (MySQL, Elasticsearch, MariaDB, and CouchDB) that we cannot not edit directly. If you are curious to learn about those files, check them out here:
* [bluecompute-ce/templates/istio_auth_policies.yaml](../../bluecompute-ce/templates/istio_auth_policies.yaml)
* [bluecompute-ce/templates/istio_destination_rules.yaml](../../bluecompute-ce/templates/istio_destination_rules.yaml)
* [bluecompute-ce/templates/istio_virtual_services.yaml](../../bluecompute-ce/templates/istio_virtual_services.yaml)

The `bluecompute-ce` chart disables all of the individual gateways in favor of a global gateway, which you can checkout here:
* [bluecompute-ce/templates/istio_gateway.yaml](../../bluecompute-ce/templates/istio_gateway.yaml)

Lastly, in order to avoid tweaking multiple values files or typing long commands to install `bluecompute-ce` with Istio enabled, we decided to provide separate values files, which you can see here:
* [bluecompute-ce/values-istio-basic.yaml](../../bluecompute-ce/values-istio-basic.yaml)
	+ This file just enables Istio for all of the microservices using the settings and files we talked about before.
	+ The only thing is that to access the web application we have to use port-forward the web application to our local machine.
* [bluecompute-ce/values-istio-gateway.yaml](../../bluecompute-ce/values-istio-gateway.yaml)
	+ This file is similar to the file above but has the settings to enable the Global Istio Gateway.
	+ This chart assumes that you have created wildcard SSL certificate for the `bluecompute.com` domain name and uploaded they certificate and keys as secrets into the Kubernetes cluster.
	+ More details on how to deploy the Gateway in the later section.
	+ You can check out the Gateway settings here:
		- [bluecompute-ce/values-istio-gateway.yaml#L11](../../bluecompute-ce/values-istio-gateway.yaml#L11)

#### Recap
You have seen the basic Istio YAML files that we included on each microservice's Helm chart. Having these files will allow each microservice to have more control of its Istio settings rather than leave it all up to Istio and potentially run into issues if certain services are not ready for Istio prime-time yet.

On top of the above Istio YAML files, each individual microservice has Istio YAML files to configure settings for their individual data stores, which are optional if you are using the main `bluecompute-ce` Helm chart but are useful if you are deploying each microservice and its datastore individually.

## Deploy Istiofied Bluecompute Chart


## Telemetry Example

### Generating Load

### Graphana

### Service Graph

### Jaeger - Tracing

### Kiali