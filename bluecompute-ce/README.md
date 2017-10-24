# Run a Cloud Native Microservices Application on a Kubernetes Cluster

## Introduction

This helm chart provides a [reference implementation](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes) for running a Cloud Native Mobile and Web Application using a Microservices architecture on a Kubernetes cluster.  The logical architecture for this reference implementation is shown in the picture below.  

   ![Application Architecture](../static/imgs/bluecompute_ce.png?raw=true)

### Deployment

To install, use the following command in the current directory to install the chart:

```
$ helm install --name bluecompute .
```

The following variables influence chart behaviors, and can be passed using the `--set` arguments passed to `helm`:

- `global.persistence.enabled=true`
  
  Create [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) for all database charts.  If this is not set, a `hostPath` is used for the volumes instead.
  
- `global.persistence.volume.size=<size in Gi>`

  This string is used to set the size of the PersistentVolumeClaim.  By default, 1Gi is requested for each of the database data volumes.  Note in the IBM Bluemix Container Service, the minimum is 20Gi.
  
- `global.persistence.volume.storageClass=<storageClassName>`

  This string is used to set the storage class of the PersistentVolumeClaim being requested.  Valid values depend on the Kubernetes cluster where the application is deployed and can be retrieved using the following command:
  
  ```
  $ kubectl get storageclasses
  ```

  For example, IBM Bluemix Container Service provides the following valid storage classes:
  
  ```
  NAME                         TYPE
  default                      ibm.io/ibmc-file   
  ibmc-file-bronze (default)   ibm.io/ibmc-file   
  ibmc-file-gold               ibm.io/ibmc-file   
  ibmc-file-silver             ibm.io/ibmc-file   
  ```
  
  By default, no storage class is provided.
  
- `web.ingress.hostname=<ingress hostname>`

  If this variable is set, a host rule is added to the Ingress resource for the web deployment.  In IBM Bluemix Container Service, this value [is required](https://console.bluemix.net/docs/containers/cs_apps.html#ibm_domain) (see step 4b) and must be set to the Ingress hostname, otherwise the Ingress Controller will not forward traffic to the web service.
    
- `web.ingress.path=<path>`

  This variable controls the path that the web BFF is available on in the ingress controller.  For example, if set to `/web`, the web application becomes available at `http://<ingress hostname>/web`.  The path is set to `/bluecompute` by default, which means that the web application is served at the path `/bluecompute` of the Ingress Controller.
  

NOTE: if deploying BlueCompute to a namespace other than `default` in IBM Cloud Private, please see [this note](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/PodSecurityPolicy/PodSecurityPolicy.md) on PodSecurityPolicy.
  
