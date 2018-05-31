# Keystore Generation

1. [Locally in Minikube](#locally-in-minikube)
2. [Remotely in ICP](#remotely-in-icp)


### Locally in Minikube

#### Setting up your environment

1. Start your minikube. Run the below command.

`minikube start`

You will see output similar to this.

```
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
```
2. To install Tiller which is a server side component of Helm, initialize helm. Run the below command.

`helm init`

If it is successful, you will see the below output.

```
$HELM_HOME has been configured at /Users/user@ibm.com/.helm.

Tiller (the helm server side component) has been installed into your Kubernetes Cluster.
Happy Helming!
```
3. Check if your tiller is available. Run the below command.

`kubectl get deployment tiller-deploy --namespace kube-system`

If it available, you can see the availability as below.

```
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
tiller-deploy   1         1         1            1           1m
```

4. Verify your helm before proceeding like below.

`helm version`

You will see the below output.

```
Client: &version.Version{SemVer:"v2.4.2", GitCommit:"82d8e9498d96535cc6787a6a9194a76161d29b4c", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.5.0", GitCommit:"012cb0ac1a1b2f888144ef5a67b8dab6c2d45be6", GitTreeState:"clean"}
```

#### Running the application on Minikube

1. Build the docker image.

Before building the docker image, set the docker environment.

- Run the below command.

`minikube docker-env`

You will see the output similar to this.

```
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/user@ibm.com/.minikube/certs"
export DOCKER_API_VERSION="1.23"
# Run this command to configure your shell:
# eval $(minikube docker-env)
```
- For configuring your shell, run the below command.

`eval $(minikube docker-env)`

- Now run the docker build.

`docker build -t keygen-mp:v1.0.0 .`

If it is a success, you will see the below output.

```
Successfully built b984978b74h2
Successfully tagged keygen-mp:v1.0.0
```
2. Run the helm chart.

`helm install --name=keystore chart/keystore`

3. To validate, check if the secrets are created as below.

`kubectl get secrets`

You will see something like below.

```
NAME                                        TYPE                                  DATA      AGE
keystoresecret                              Opaque                                2         6m
```

### Remotely in ICP

[IBM Cloud Private](https://www.ibm.com/cloud/private)

IBM Private Cloud has all the advantages of public cloud but is dedicated to single organization. You can have your own security requirements and customize the environment as well. Basically it has tight security and gives you more control along with scalability and easy to deploy options. You can run it externally or behind the firewall of your organization.

Basically this is an on-premise platform.

Includes docker container manager
Kubernetes based container orchestrator
Graphical user interface
You can find the detailed installation instructions for IBM Cloud Private [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.2/installing/install_containers_CE.html)

#### Pushing the image to Private Registry

1. Now run the docker build.

`docker build -t keygen-mp:v1.0.0 .`

If it is a success, you will see the below output.

```
Successfully built c763478b74k1
Successfully tagged keygen-mp:v1.0.0
```

2. Tag the image to your private registry.

`docker tag keygen:latest <Your ICP registry>/keygen:latest`

3. Push the image to your private registry.

`docker push <Your ICP registry>/keygen:latest`

You should see something like below.

```
latest: digest: sha256:7f3deb2c43854df725efde5b0a3e6977cc7b6e8e26865b484d8cb20c2e4a6dd0 size: 3873
```

#### Running the application on ICP

1. Your [IBM Cloud Private Cluster](https://www.ibm.com/cloud/private) should be up and running.

2. Log in to the IBM Cloud Private. 

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/icp_dashboard.png">
</p>

3. Go to `admin > Configure Client`.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/client_config.png">
</p>

4. Grab the kubectl configuration commands.

<p align="center">
    <img src="https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/blob/microprofile/static/imgs/kube_cmds.png">
</p>

5. Run those commands in your terminal.

6. If successful, you should see something like below.

```
Switched to context "xxx-cluster.icp-context".
```
7. Run the below command.

`helm init --client-only`

You will see the below

```
$HELM_HOME has been configured at /Users/user@ibm.com/.helm.
Not installing Tiller due to 'client-only' flag having been set
Happy Helming!
```

8. Verify the helm version

`helm version --tls`

You will see something like below.

```
Client: &version.Version{SemVer:"v2.7.2+icp", GitCommit:"d41a5c2da480efc555ddca57d3972bcad3351801", GitTreeState:"dirty"}
Server: &version.Version{SemVer:"v2.7.2+icp", GitCommit:"d41a5c2da480efc555ddca57d3972bcad3351801", GitTreeState:"dirty"}
```

9. Before running the helm chart in minikube, access [values.yaml](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/microprofile/catalog/chart/catalog/values.yaml) and replace the repository with the below.

`repository: <Your IBM Cloud Private Docker registry>`

Then run the helm chart.

`helm install --name=keystore chart/keystore --tls`

3. To validate, check if the secrets are created as below.

`kubectl get secrets`

You will see something like below.

```
NAME                                        TYPE                                  DATA      AGE
keystoresecret                              Opaque                                2         6m
```

**NOTE**: If you are using a version of ICP older than 2.1.0.2, you don't need to add the --tls at the end of the helm command.

