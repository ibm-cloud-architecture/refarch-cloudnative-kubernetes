# Running Microservices Reference Architecture in Airgapped ICP Environments

In some cases, the ICP cluster has no Internet access and cannot pull images from public DockerHub.  In this case, we provide a script to generate a PPA archive that can be imported into ICP using the `cloudctl` CLI.  For more information on the CLI, see [this link](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/manage_cluster/install_cli.html).

Before starting with this process you will need to add an entry to your `/etc/hosts` file that points the cluster CA domain name to the Master Node's IP Address. To do so, run the following command:
```bash
# Replace 10.0.0.1 with the IP Address of your cluster
# Also replace mycluster.icp with the actual CA domain name of your cluster
sudo echo "10.0.0.1 mycluster.icp" >> /etc/hosts
```

Now, you need to add IBM Cloud Private's Docker Registry (i.e. `https://mycluster.icp:8500`) to the list of trusted registries so we can push the Docker images to it. To do so, follow the instructions in the document below to add an insecure registry to your Docker client:
* https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry

If the above was done correctly, then you are ready to generate the archive.

To generate the archive, use a machine with Internet access to clone this git repository. Then, copy the chart for the reference architecture into this directory:

```bash
# Clone the git repository
git clone -b spring --single-branch https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes

# Go to this directory
cd docs/icp-uploading-chart

# Copy latest bluecompute-ce helm chart
cp ../charts/bluecompute-ce/bluecompute-ce-0.0.9.tgz .
```

Unpack the chart to update the `values.yaml` to correspond to the local cluster.

```bash
tar zxvf bluecompute-ce-0.0.9.tgz
```

Update the `bluecompute-ce/values.yaml` so that the image repositories correspond to the private registry in ICP.  For example, if the cluster is named `mycluster.icp`, you can update the yaml keys like this:

| name                  					| value                                                    							|
|-------------------------------------------|-----------------------------------------------------------------------------------|
| `auth.image.repository` 					| `mycluster.icp:8500/default/ibmcase/bluecompute-auth` 							|
| `auth.bash.image.repository`				| `mycluster.icp:8500/default/ibmcase/bluecompute-bash-curl-ssl` 					|
| `catalog.image.repository` 				| `mycluster.icp:8500/default/ibmcase/bluecompute-catalog` 							|
| `catalog.curl.image` 						| `mycluster.icp:8500/default/ibmcase/curl` 										|
| `elasticsearch.image.repository` 			| `mycluster.icp:8500/default/ibmcase/elasticsearch/elasticsearch-oss` 	|
| `elasticsearch.initImage.repository` 		| `mycluster.icp:8500/default/ibmcase/busybox` 												|
| `customer.image.repository` 				| `mycluster.icp:8500/default/ibmcase/bluecompute-customer` 						|
| `customer.bash.image.repository` 			| `mycluster.icp:8500/default/ibmcase/bluecompute-bash-curl-ssl` 					|
| `couchdb.image.repository` 				| `mycluster.icp:8500/default/ibmcase/couchdb` 												|
| `couchdb.helperImage.repository`		 	| `mycluster.icp:8500/default/ibmcase/couchdb-statefulset-assembler` 				|
| `inventory.image.repository` 				| `mycluster.icp:8500/default/ibmcase/bluecompute-inventory` 						|
| `inventory.mysql.image` 					| `mycluster.icp:8500/default/ibmcase/mysql` 												|
| `mysql.image` 							| `mycluster.icp:8500/default/ibmcase/mysql` 												|
| `orders.image.repository` 				| `mycluster.icp:8500/default/ibmcase/bluecompute-orders` 							|
| `orders.mysql.image` 						| `mycluster.icp:8500/default/ibmcase/mysql` 												|
| `mariadb.image.registry`	 				| `mycluster.icp:8500/default` 														|
| `mariadb.image.repository` 				| `mariadb` 																|
| `web.image.repository` 					| `mycluster.icp:8500/default/ibmcase/bluecompute-web` 								|

You can also use the following following command to update the image repository location:
```bash
# Update the ibmcase images
# Then manually change the non-ibmcase ones
REGISTRY="mycluster.icp:8500";
NAMESPACE="default";
ORG="ibmcase";
IMAGE_NAME_PREFIX="${REGISTRY}/${NAMESPACE}/${ORG}";

# OPTIONAL: sed in-place replacement requires an extra parameter in macOS
# If using Linux, don't set this variable
SED_OPTION="''";

# Replace Image Registry values to that of the IBM Cloud Private Private Registry
sed -i ${SED_OPTION} "s|ibmcase|${IMAGE_NAME_PREFIX}|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|alexeiled/curl|${IMAGE_NAME_PREFIX}/curl|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|docker.elastic.co/elasticsearch/elasticsearch-oss|${IMAGE_NAME_PREFIX}/elasticsearch|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|busybox|${IMAGE_NAME_PREFIX}/busybox|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|repository: \"couchdb\"|repository: \"${IMAGE_NAME_PREFIX}/couchdb\"|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|kocolosk/couchdb-statefulset-assembler|${IMAGE_NAME_PREFIX}/couchdb-statefulset-assembler|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|image: \"mysql\"|image: \"${IMAGE_NAME_PREFIX}/mysql\"|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|docker.io|${IMAGE_NAME_PREFIX}|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|bitnami/mariadb|mariadb|g" bluecompute-ce/values.yaml;

# For the elasticsearch chart we have to tell it to pull the docker images from
# the internal registry using the imagePullSecret of the default account
sed -i ${SED_OPTION} "s|#pullSecrets|pullSecrets|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|#- sa-default|- sa-${NAMESPACE}|g" bluecompute-ce/values.yaml;
```

Once the `values.yaml` file is updated correctly, re-package the helm chart, which will create an updated tarball containing the changes made above.

```bash
helm package bluecompute-ce
rm -rf bluecompute-ce
```

Execute the script to create the PPA archive. This script downloads all of the Docker images and creates a PPA archive using the Docker images, the `bluecompute-ce` chart and the `manifest.json.tmpl` and `manifest.yaml.tmpl`:

```bash
./build_ppa_archive.sh
```

This will pull all the pre-requisite Docker images and the chart into a single tarball.  Copy this tarball to the boot node of the ICP cluster (or one of the master nodes).  Authenticate to the docker private registry from the boot node, using the cluster CA domain.  For example, for a cluster named `mycluster.icp`, use:

```bash
docker login mycluster.icp:8500
```

Authenticate with the `cloudctl` CLI (which you can install using [these](#installing-the-bx-pr-cli) instructions) using the following command.  For a cluster named `mycluster.icp`, use the following:

```bash
cloudctl login -a https://mycluster.icp:8443 -n default --skip-ssl-validation
```

Once you are authenticated, use the following command to import all of the images in the PPA archive named `bluecompute-ce-ppa-0.0.9.tgz`, for a cluster named `mycluster.icp`:

```bash
cloudctl catalog load-ppa-archive -a bluecompute-ce-ppa-0.0.9.tgz --registry mycluster.icp:8500
```

This will push all of the images into the private registry under the `default` namespace and load the chart to the `local-charts` helm chart repository in ICP.  You can install the chart from the catalog in the `local-charts` repository.

For more information on this procedure in ICP, see the [documentation](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/app_center/add_package_offline.html).

## Installing the `cloudctl` CLI
Navigate to the `Cloud Private CLI` page in the ICP dashboard (as shown below) and download the CLI for your platform.

![cloudctl cli install instructions](imgs/bx_pr_cli.png?raw=true)

Once downloaded, you can install the `Cloud Private CLI` using [these](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/install_cli.html) instructions.

## Cleanup
To delete the helm chart from the catalog, use the following command:
```bash
cloudctl catalog delete-chart -n bluecompute-ce -r local-charts -v 0.0.9
```

Now, on the web console, go ahead and refresh the helm repositories so that it picks up the chart deletion.