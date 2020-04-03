# Deploy BlueCompute to IBM Cloud Private

## Table of Contents
  * [Introduction](#introduction)
  * [OPTIONAL: Deploying BlueCompute to non-default Namespaces](#optional-deploying-bluecompute-to-non-default-namespaces)
  * [Access and Validate the Application](#access-and-validate-the-application-1)
  * [Delete the Application](#delete-the-application-1)
  * [Helm Version](#helm-version)
  * [Deploy BlueCompute to IBM Cloud Private Cluster with No Internet Access](#deploy-bluecompute-to-ibm-cloud-private-cluster-with-no-internet-access)

## Introduction

IBM Cloud Private (ICP) contains integration with Helm that allows you to install the application and all of its components in a few steps. This can be done as an administrator using the following steps:

1. Click on the user icon on the top right corner and then click on `Configure client`.

2. Copy the displayed `kubectl` configuration, paste it in your terminal, and press Enter on your keyboard.

3. Download and initialize helm in your cluster using [these instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/app_center/create_helm_cli.html).

4. **NOTE**: If using IBM Cloud Private 3.1 or newer, you are required to create an [ImagePolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_images/image_security.html) that allows you to deploy images from the `docker.io` and `docker.elastic.co` Docker Registries:

```bash
kubectl apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/static/image_policy.yaml
```

5. Add the `helm` package repository containing the reference application:

```bash
helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts/bluecompute-ce
```

6. Install the reference application:

```bash
helm upgrade --install bluecompute ibmcase/bluecompute-ce --tls
```

7. **NOTE**: If you want to deploy `bluecompute-ce` to a `non-default` namespace, follow the instructions in [Deploying BlueCompute to non-default Namespaces](#optional-deploying-bluecompute-to-non-default-namespaces) as there are a few extra steps required that involve **PodSecurityPolicies**.

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).

## OPTIONAL: Deploying BlueCompute to non-default Namespaces

The `default` namespace in IBM Cloud Private is a special namespace that lets you deploy any type of container (including privileged containers) as long as you create an [ImagePolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_images/image_security.html) for it. That's because the default namespace's service account is authorized to use the [`ibm-privileged-psp` PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), which provides admin-level access to that service account. This is great for deploying workloads that require admin-level access, such as monitoring or networking agents.

However, most Kubernetes users don't require admin-level access to the cluster so they are usually assigned to work with non-default namespaces that have the [`ibm-restricted-psp` PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), which doesn't have admin-level access and only allows you to deploy non-root unprivileged containers. Shall those users (or service accounts) require admin-level access to the cluster, they would have to request it before it is granted.

In order to deploy `bluecompute-ce` to a `non-default` namespace, you will need to bind that namespace's default service account to the `ibm-privileged-psp` [PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html). That's because the `mysql`, `elasticsearch`, `couchdb`, and `mariadb` community Helm Charts are running their processes as root because they don't specify a `numeric id` for their container users in their [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) (i.e. checkout SecurityContext in [Elasticsearch Helm Chart](https://github.com/helm/charts/blob/master/stable/elasticsearch/templates/master-statefulset.yaml#L30)) if they have any. That's unfortunate because the Dockerfiles used in the Helm charts **DO** specify a non-root username (as shown in the [MySQL Dockerfile](https://github.com/docker-library/mysql/blob/bb7ea52db4e12d3fb526450d22382d5cd8cd41ca/5.7/Dockerfile#L4)) but Kubernetes requires a **NUMERIC** instead.

The Elasticsearch Helm Chart also requires the use of a root [Init Container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) (as shown [here](https://github.com/helm/charts/blob/master/stable/elasticsearch/templates/master-state-fulset.yaml#L101)) and a privileged Init Container (as shown [here](https://github.com/helm/charts/blob/master/stable/elasticsearch/templates/master-statefulset.yaml#L79)) to manually increase lockable memory limits and disable swapping in the worker nodes for Elasticsearch to work properly, even though Elasticsearch itself does not run as root.

Now that you understand why we need to authorize a non-default namespace to use the `ibm-privileged-psp` [PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), let's go ahead and do that with the following commands:

```bash
# Create non-default bluecompute namespace
kubectl create namespace bluecompute

# Create Role that allows the use of ibm-privileged-psp PodSecurityPolicy
kubectl create role psp:privileged -n bluecompute \
    --verb=use \
    --resource=podsecuritypolicy \
    --resource-name=ibm-privileged-psp

# Bind the above role to the default service account in bluecompute namespace
kubectl create rolebinding bluecompute:psp:privileged -n bluecompute \
    --role=psp:privileged \
    --serviceaccount=bluecompute:default
```

Now that the `default` service account for the `bluecompute` namespace is authorized to use the `ibm-privileged-psp` [PodSecurityPolicy](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.2/manage_cluster/security.html), let's deploy `bluecompute-ce` chart with the following command:

```bash
helm upgrade --install bluecompute --namespace bluecompute ibmcase/bluecompute-ce --tls
```

After a minute or so, the containers will be deployed to the cluster.  The output of the installation contains instructions on how to access the application once it has finished deploying.  For more information on the additional options for the chart, see [this document](bluecompute-ce/README.md).

## Access and Validate the Application

To access the application, you need to access the IP address of one of your proxy nodes. Pick the IP of any of your proxy nodes.

In your browser navigate to **`http://<IP>:31337`**.

To validate the application itself, feel free to use the instructions [here](#validate-the-application).

## Delete the Application

To delete the application from your cluster, run the following commands:

```bash
# Delete the bluecompute-ce chart
helm delete bluecompute --purge --tls

# If you deployed the chart to a non-default namespace,
# you also have to delete both the Role and the RoleBinding
# NOTE: The following assumes that you deployed the chart to bluecompute namespace
kubectl --namespace bluecompute delete rolebinding bluecompute:psp:privileged;
kubectl --namespace bluecompute delete role psp:privileged;
```

## Helm Version

If Chart installation fails, it usually has to do with the version of helm in your workstation being incompatible with the one installed in the IBM Cloud Private Cluster. To verify installed versions of helm, use the following command:

```bash
helm version --tls
```

If the versions are different, you might want to delete the current helm client and install a version of helm client that matches the server one. To do so, please refer to Helm's guide [here](https://github.com/kubernetes/helm/blob/master/docs/install.md).

## Deploy BlueCompute to IBM Cloud Private Cluster with No Internet Access

Sometimes you are required to deploy services to an ICP cluster that has no internet access, which means that it can only pull docker images from ICP's Private Docker Registry. To learn how you can package the BlueCompute Chart (and all its Docker images), upload it directly to ICP, and install it without an Internet connection, checkout [Running Microservices Reference Architecture in Airgapped ICP Environments](../icp-uploading-chart).
