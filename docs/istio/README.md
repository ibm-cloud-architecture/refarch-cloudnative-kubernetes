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