#!/bin/bash
# Install BlueCompute charts separately
NAMESPACE="$1"
TLS="$2"
HELM="$3"

if [ -z "$NAMESPACE" ]; then
	NAMESPACE="default"
	echo "No NAMESPACE provided! Using \"${NAMESPACE}\""
fi

if [ -z "$TLS" ]; then
	echo "--tls option will NOT be used!"
fi

if [ -z "$HELM" ]; then
	HELM="helm"
fi

###### 1. INVENTORY ######
RELEASE_NAME=inventory
CHART_NAME="inventory"
MYSQL_ROOT_PASSWORD="admin123"
MYSQL_USER="dbuser"
MYSQL_PASSWORD="password"
MYSQL_DATABASE="inventorydb"

# Install MySQL
${HELM} upgrade --install mysql --version 0.10.2 --namespace ${NAMESPACE} \
	--set fullnameOverride=${RELEASE_NAME}-mysql \
	--set mysqlRootPassword=${MYSQL_ROOT_PASSWORD} \
	--set mysqlUser=${MYSQL_USER} \
	--set mysqlPassword=${MYSQL_PASSWORD} \
	--set mysqlDatabase=${MYSQL_DATABASE} \
	--set persistence.enabled=false \
	stable/mysql ${TLS}

# Wait for MySQL to start
kubectl --namespace ${NAMESPACE} rollout status deployment/${RELEASE_NAME}-mysql

# Install Inventory
${HELM} upgrade --install ${RELEASE_NAME} --namespace ${NAMESPACE} \
	--set mysql.existingSecret=${RELEASE_NAME}-mysql \
	../../refarch-cloudnative-micro-inventory/chart/inventory ${TLS}
	#ibmcase-charts/inventory ${TLS}

# Get Deployment Name
DEPLOYMENT="deployment/${RELEASE_NAME}-${CHART_NAME}"

# Wait for deployment to be ready
kubectl --namespace ${NAMESPACE} rollout status ${DEPLOYMENT}



###### 2. CATALOG ######
RELEASE_NAME=catalog
CHART_NAME=catalog
INVENTORY_RELEASE_NAME=inventory
INVENTORY_CHART_NAME=inventory

# Install Elasticsearch
${HELM} upgrade --install elasticsearch --version 1.13.2 --namespace ${NAMESPACE} \
	--set fullnameOverride=${RELEASE_NAME}-elasticsearch \
	--set cluster.env.MINIMUM_MASTER_NODES="2" \
	--set client.replicas=1 \
	--set master.replicas=2 \
	--set master.persistence.enabled=false \
	--set data.replicas=1 \
	--set data.persistence.enabled=false \
	stable/elasticsearch ${TLS}

# Wait for Elasticsearch to start
kubectl --namespace ${NAMESPACE} rollout status deployment/${RELEASE_NAME}-elasticsearch-client

# Install Catalog
${HELM} upgrade --install ${RELEASE_NAME} --namespace ${NAMESPACE} \
	--set elasticsearch.host=${RELEASE_NAME}-elasticsearch-client \
	--set inventory.url=http://${INVENTORY_RELEASE_NAME}-${INVENTORY_CHART_NAME}:8080 \
	../../refarch-cloudnative-micro-catalog/chart/${CHART_NAME} ${TLS}

# Get Deployment Name
DEPLOYMENT="deployment/${RELEASE_NAME}-${CHART_NAME}"

# Wait for deployment to be ready
kubectl --namespace ${NAMESPACE} rollout status ${DEPLOYMENT}



###### 3. CUSTOMER ######
RELEASE_NAME=customer
COUCHDB_USER=admin
COUCHDB_PASSWORD=passw0rd
CHART_NAME=customer

# Install CouchDB
${HELM} upgrade --install couchdb --version 0.2.2 --namespace ${NAMESPACE} \
	--set service.externalPort=5985 \
	--set fullnameOverride=${RELEASE_NAME}-couchdb \
	--set createAdminSecret=true \
	--set adminUsername=${COUCHDB_USER} \
	--set adminPassword=${COUCHDB_PASSWORD} \
	--set clusterSize=1 \
	--set persistentVolume.enabled=false \
	incubator/couchdb ${TLS}

# Install Customer
${HELM} upgrade --install ${RELEASE_NAME} --namespace ${NAMESPACE} \
	--set couchdb.adminUsername=${COUCHDB_USER} \
	--set couchdb.adminPassword=${COUCHDB_PASSWORD} \
	../../refarch-cloudnative-micro-customer/chart/${CHART_NAME} ${TLS}

# Get Deployment Name
DEPLOYMENT="deployment/${RELEASE_NAME}-${CHART_NAME}"

# Wait for deployment to be ready
kubectl --namespace ${NAMESPACE} rollout status ${DEPLOYMENT}



###### 4. ORDERS ######
RELEASE_NAME=orders
CHART_NAME=orders
MYSQL_DATABASE=ordersdb
MYSQL_ROOT_PASSWORD=admin123
MYSQL_PORT=3307
MYSQL_USER=dbuser
MYSQL_PASSWORD=password

# Install MariaDB
${HELM} upgrade --install orders-mariadb --version 5.2.2 --namespace ${NAMESPACE} \
	--set service.port=${MYSQL_PORT} \
	--set nameOverride=${RELEASE_NAME}-mariadb \
	--set rootUser.password=${MYSQL_ROOT_PASSWORD} \
	--set db.user=${MYSQL_USER} \
	--set db.password=${MYSQL_PASSWORD} \
	--set db.name=${MYSQL_DATABASE} \
	--set replication.enabled=false \
	--set master.persistence.enabled=false \
	--set slave.replicas=1 \
	--set slave.persistence.enabled=false \
	stable/mariadb ${TLS}

# Install Orders
${HELM} upgrade --install ${RELEASE_NAME} --namespace ${NAMESPACE} \
	--set mariadb.user=${MYSQL_USER} \
	--set mariadb.password=${MYSQL_PASSWORD} \
	--set mariadb.database=${MYSQL_DATABASE} \
	../../refarch-cloudnative-micro-orders/chart/${CHART_NAME} ${TLS}

# Get Deployment Name
DEPLOYMENT="deployment/${RELEASE_NAME}-${CHART_NAME}"

# Wait for deployment to be ready
kubectl --namespace ${NAMESPACE} rollout status ${DEPLOYMENT}



###### 5. AUTH ######
RELEASE_NAME=auth
CHART_NAME=auth

# Customer
CUSTOMER_RELEASE_NAME=customer
CUSTOMER_CHART_NAME=customer
CUSTOMER_SERVICE_PORT=8082

# Install Auth
${HELM} upgrade --install ${RELEASE_NAME} --namespace ${NAMESPACE} \
	--set customer.url=http://${CUSTOMER_RELEASE_NAME}-${CUSTOMER_CHART_NAME}:${CUSTOMER_SERVICE_PORT} \
	../../refarch-cloudnative-auth/chart/${CHART_NAME} ${TLS}

# Get Deployment Name
DEPLOYMENT="deployment/${RELEASE_NAME}-${CHART_NAME}"

# Wait for deployment to be ready
kubectl --namespace ${NAMESPACE} rollout status ${DEPLOYMENT}



###### 6. WEB ######
RELEASE_NAME=web
CHART_NAME=web

# Install Web
${HELM} upgrade --install ${RELEASE_NAME} --namespace ${NAMESPACE} \
	../../refarch-cloudnative-bluecompute-web/chart/${CHART_NAME} ${TLS}

# Get Deployment Name
DEPLOYMENT="deployment/${RELEASE_NAME}-${CHART_NAME}"

# Wait for deployment to be ready
kubectl --namespace ${NAMESPACE} rollout status ${DEPLOYMENT}
