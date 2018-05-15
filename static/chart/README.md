# Deploy BlueCompute to IBM Bluemix Container Service using IBM Bluemix Services

We have also prepared a chart that uses managed database services from the IBM Bluemix catalog instead of local docker containers, to be used when deploying the application on a cluster in the IBM Bluemix Container Service.  Please be aware that this will incur a cost in your IBM Bluemix account.  The following services are instantiated by the helm chart:

- [Compose for Elasticsearch](https://www.compose.com/databases/elasticsearch) (one instance for the Catalog microservice is created)
- [IBM Cloudant](https://www.ibm.com/analytics/us/en/technology/cloud-data-services/cloudant/) (a free Lite instance is created for the Customer Microservice)
- [Compose for MySQL](https://www.compose.com/databases/mysql) (two instances, one for Orders microservice and one for Inventory microservice)
- [IBM Message Hub](http://www-03.ibm.com/software/products/en/ibm-message-hub) - (for asynchronous communication between Orders and Inventory microservices; a topic named `orders` is created)

Use the following commands to install the chart:

```bash
$ helm init

$ helm repo add ibmcase https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/master/docs/charts/bluecompute

$ helm install --name bluecompute ibmcase/bluecompute \
    --set global.bluemix.target.endpoint=<Bluemix API endpoint> \
    --set global.bluemix.target.org=<Bluemix Org> \
    --set global.bluemix.target.space=<Bluemix Space> \
    --set global.bluemix.clusterName=<Name of cluster> \
    --set global.bluemix.apiKey=<Bluemix API key for user account>
```

Where,

- `<Bluemix API endpoint>` specifies an API endpoint (e.g. `api.ng.bluemix.net`).  This controls which region the Bluemix services are created.
- `<Bluemix Org>` and `<Bluemix Space>` specifies a space where the Bluemix Services are created.
- `<Name of cluster>` specifies the name of the cluster as created in the IBM Bluemix Container Service
- `<Bluemix API key for user account>` is an API key used to authenticate against Bluemix.  To create an API key, follow [these instructions](https://console.bluemix.net/docs/iam/apikeys.html#creating-an-api-key).

When deleting the application, note that the services are not automatically removed from Bluemix with the chart.