# Exploring Istio Service Mesh Features with Bluecompute

## Table of Contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Blue-Compute Istiofied](#blue-compute-istiofied)
* [Deploying Istio Helm Chart](#deploying-istio-helm-chart)
* [Setting up your Istio environment](#setting-up-your-istio-environment)
* [Deploying the Istio Bluecompute Helm Chart](#deploying-the-istio-bluecompute-helm-chart)
  * [Visit your App](#visit-your-app)
* [Cleanup](#cleanup)

## Introduction

This document serves to provide basic information to prop up a Bluecompute instance along with Istio. For a more robust explanation of Bluecompute, Istio, and architectural design choices, please refer to our [Istio document](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/docs/istio.md) in the master branch.

## Requirements

* A Kubernetes cluster
  * [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/container-service) - Create a Kubernetes cluster in IBM Cloud.  The application runs in the Lite cluster, which is free of charge.  Follow the instructions [here](https://console.bluemix.net/docs/containers/container_index.html).
  * For local development/deployment, try a single-node cluster setup with [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
* [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) (Kubernetes CLI) - Follow instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it onto your platform.
* [helm](https://github.com/kubernetes/helm) (Kubernetes package manager) - Follow the instructions [here](https://github.com/kubernetes/helm/blob/master/docs/install.md) to install it on your platform.
  * If using `IBM Cloud Private`, we recommend you follow these [instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html) to install `helm`.
  * If using IBM Cloud Kubernetes Service (IKS), please use the most up-to-date version of helm

## Blue-Compute Istiofied

For information regarding the Bluecompute architecture and further details on the Istio files, check our guide [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/master/docs/istio.md).

## Setting up your Istio environment

We will be using IBM's official [Istio Helm Chart](https://github.com/IBM/charts/tree/master/stable/ibm-istio). This chart comes with an easy way to toggle on/off different Istio components, such as Ingress and Egress gateways, with a simple boolean. Also bundled in, the chart comes with non-Istio components such as Grafana, Service Graph, and Kiali, which we can also easily toggle on/off.

1) First, we must add the `IBM Cloud Charts` Helm repository with the command below:

    ```bash
    helm repo add ibm-charts https://registry.bluemix.net/helm/ibm-charts
    ```

1) To enable Kiali, an open source project that seeks to visualize your service mesh topology, we will need to create a secret containing a username and passphrase to access the Kiali dashboard.

    ```bash
    # Username and Passphrase in base64 format
    DASHBOARD_USERNAME=$(echo -n 'admin' | base64);
    DASHBOARD_PASSPHRASE=$(echo -n 'secret' | base64);

    # Namespace, and Create if does not exist
    kubectl create namespace istio-system
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

1) Now we can deploy the Istio chart if `helm` version is **2.10.0** or higher:

    ```bash
    # Install Istio Chart and enable Grafana, Service Graph, and Jaeger (tracing)

    helm upgrade --install istio --version 1.1.7 \
      --set grafana.enabled=true \
      --set servicegraph.enabled=true \
      --set tracing.enabled=true \
      --set kiali.enabled=true \
      ibm-charts/ibm-istio --namespace istio-system
    ```

    If your helm version cannot be updated, install IBM Istio's Custom Resource Definitions (CRDs) with the command below. You will have to wait a few seconds for the changes to be committed to the kube-apiserver:

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml
    ```

    If you want to disable select features, simply set the desired feature to `false`.

    You can check the availability of your Istio pods with the following waiting command:

    ```bash
    kubectl get pods -n istio-system -w
    ```

1) Istio works best when you leverage its automatic sidecar injection feature, which automatically puts all of the YAML pertaining to the Istio sidecar into your deployments/pods upon deployment. 

    To leverage Istio's automatic sidecar injection feature, we need to enable it by labeling the namespace in which you will leverage this feature. We will use the `default` namespace, which you can label with:

    ```bash
    kubectl label namespace default istio-injection=enabled
    ```

## Deploying the Istio Bluecompute Helm Chart

Now let's proceed with installing the `bluecompute` chart itself as follows:

1) Add the remote Helm chart repository:

    ```bash
    # Add Helm repository
    helm repo add bluecompute-mp https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/microprofile/bluecompute-mp

    # Refresh Helm repositories
    helm repo update
    ```

1) Now install the chart with the command below:

    ```bash
    # Install helm chart
    helm install bluecompute --name bluecompute
    ```

    It should take a few minutes for all of the pods to be up and running. Run the following command multiple times until all of the pods show a status of `RUNNING`.

    ```bash
    kubectl get pods
    ```

### Visit your App

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

Or if deploying with minikube, you can simply run:

```bash
minikube service bluecompute-web
```

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
