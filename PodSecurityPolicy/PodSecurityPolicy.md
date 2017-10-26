# Enable PodSecurityPolicy for BlueCompute

IBM Cloud Private ships with two [PodSecurityPolicies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/), `default`, and `privileged`.  In the `default` namespace, the `default` service account is given the `privileged` pod security policy and is permitted to create privileged containers.  In all other user-created namespaces, the `default` service account is given the `default` pod security policy in which privileged containers are not allowed to be created.

BlueCompute uses an [ElasticSearch image](https://github.com/pires/kubernetes-elasticsearch-cluster) that requires the `IPC_LOCK` capability, which is not permitted while using the `default` PodSecurityPolicy.  This means if BlueCompute is deployed to any other namespace besides `default`, the ElasticSearch container will fail to deploy.  To remedy this, we can add the included PodSecurityPolicy which enables just the required `IPC_LOCK` permission.

```bash
# kubectl create -f bluecompute-psp.yaml
```

Next, we add a [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) that uses the PodSecurityPolicy.

```bash
# kubectl create -f bluecompute-clusterrole.yaml
```

Finally, create a [ClusterRoleBinding](https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding) that applies the ClusterRole to the specified [ServiceAccount](https://kubernetes.io/docs/admin/service-accounts-admin/).  In the example provided, we have applied the ClusterRole to the `default` service account in the `bluecompute` namespace.

```bash
# kubectl create -f bluecompute-clusterrolebinding.yaml
```

