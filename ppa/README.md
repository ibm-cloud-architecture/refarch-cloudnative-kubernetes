# Running Microservices Reference Architecture in Airgapped ICP Environments

In some cases, the ICP cluster has no Internet access and cannot pull images from public DockerHub.  In this case, we provide a script to generate a PPA archive that can be imported into ICP using the `bx pr` CLI.  For more information on the CLI, see [this link](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/manage_cluster/install_cli.html).

To generate the archive, use a machine with Internet access to clone this git repository. Copy the chart for the reference architecture into this directory:

```bash
cd ppa
cp ../docs/charts/bluecompute-ce/bluecompute-ce-0.0.3.tgz .
```

Unpack the chart to update the `values.yaml` to correspond to the local cluster.  

```bash
tar zxvf bluecompute-ce-0.0.3.tgz
```

Update the `bluecompute-ce/values.yaml` so that the image repositories correspond to the private registry in ICP.  For example, if the cluster is named `mycluster.icp`, you can update the yaml keys like this:

| name                  | value                                                    |
|-----------------------|-----------------------------------------------------|
| `auth.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-auth` |
| `auth.dataloader.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-dataloader` |
| `catalog.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-catalog` |
| `catalog.dataloader.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-dataloader` |
| `ibmcase-elasticsearch.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-elasticsearch` |
| `customer.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-customer` |
| `customer.dataloader.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-dataloader` |
| `customer.bash.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-bash-curl-ssl` |
| `ibmcase-couchdb.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-couchdb` |
| `inventory.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-inventory` |
| `inventory.dataloader.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-dataloader` |
| `ibmcase-inventory-mysql.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-mysql` |
| `orders.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-orders` |
| `orders.dataloader.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-dataloader` |
| `ibmcase-orders-mysql.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-mysql` |
| `web.image.repository` | `mycluster.icp:8500/default/ibmcase/bluecompute-web` |

Once the `values.yaml` file is updated correctly, re-package the helm chart, which will create an updated tarball containing the changes made above.

```bash
helm package bluecompute-ce
rm -rf bluecompute-ce
```

Execute the script to create the PPA archive:

```bash
./build_ppa_archive.sh
```

This will pull all the pre-requisite Docker images and the chart into a single tarball.  Copy this tarball to the boot node of the ICP cluster (or one of the master nodes).  Authenticate to the docker private registry from the boot node, using the cluster CA domain.  For example, for a cluster named `mycluster.icp`, use:

```bash
docker login mycluster.icp:8500
```

Authenticate with the `bx pr` CLI using the following command.  For a cluster named `mycluster.icp`, use the following:

```bash
bx pr login -a https://mycluster.icp:8443 --skip-ssl-validation
```

Once you are authenticated, use the following command to import all of the images in the PPA archive named `bluecompute-ce-ppa-0.0.3.tgz`, for a cluster named `mycluster.icp`:

```bash
bx pr load-ppa-archive --archive bluecompute-ce-ppa-0.0.3.tgz --clustername mycluster.icp
```

This will push all of the images into the private registry under the `default` namespace and load the chart to the `local-charts` helm chart repository in ICP.  You can install the chart from the catalog in the `local-charts` repository.

For more information on this procedure in ICP, see the [documentation](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/app_center/add_package_offline.html).
