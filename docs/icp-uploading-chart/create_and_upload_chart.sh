#!/bin/bash

CLUSTER_NAME="$1"
NAMESPACE="$2"
USR="$3"
PASSWORD="$4"
ACCOUNT_ID="$5"
CHART_VERSION="0.0.9"

if [ -z "$CLUSTER_NAME" ]; then
	CLUSTER_NAME="mycluster.icp"
fi

if [ -z "$NAMESPACE" ]; then
	NAMESPACE="default"
fi

if [ -z "$USR" ]; then
	USR="admin"
fi

if [ -z "$PASSWORD" ]; then
	PASSWORD="admin"
fi

if [ -z "$ACCOUNT_ID" ]; then
	ACCOUNT_ID="mycluster-id"
fi

# Copy Chart
cp ../charts/bluecompute-ce/bluecompute-ce-${CHART_VERSION}.tgz .

# Unpack the chart
tar zxvf bluecompute-ce-${CHART_VERSION}.tgz

# Compose image name prefix
REGISTRY="${CLUSTER_NAME}:8500"
ORG="ibmcase"
IMAGE_NAME_PREFIX="${REGISTRY}/${NAMESPACE}/${ORG}"

# sed in-place replacement requires an extra parameter in macOS
SED_OPTION=""
if [ "$(uname)" == "Darwin" ]; then
    SED_OPTION="''"
fi

# Replace Image Registry values to that of the IBM Cloud Private Private Registry
sed -i ${SED_OPTION} "s|ibmcase|${IMAGE_NAME_PREFIX}|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|alexeiled/curl|${IMAGE_NAME_PREFIX}/curl|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|docker.elastic.co/elasticsearch/elasticsearch-oss|${IMAGE_NAME_PREFIX}/elasticsearch|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|\"busybox\"|\"${IMAGE_NAME_PREFIX}/busybox\"|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|repository: \"couchdb\"|repository: \"${IMAGE_NAME_PREFIX}/couchdb\"|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|kocolosk/couchdb-statefulset-assembler|${IMAGE_NAME_PREFIX}/couchdb-statefulset-assembler|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|image: \"mysql\"|image: \"${IMAGE_NAME_PREFIX}/mysql\"|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|docker.io|${IMAGE_NAME_PREFIX}|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|bitnami/mariadb|mariadb|g" bluecompute-ce/values.yaml;

# For the elasticsearch chart we have to tell it to pull the docker images from
# the internal registry using the imagePullSecret of the default account
sed -i ${SED_OPTION} "s|#pullSecrets|pullSecrets|g" bluecompute-ce/values.yaml;
sed -i ${SED_OPTION} "s|#- sa-default|- sa-${NAMESPACE}|g" bluecompute-ce/values.yaml;

# Re-package new chart and delete chart folder
helm package bluecompute-ce
rm -rf bluecompute-ce

# Build PPA
./build_ppa_archive.sh

# Docker Login
docker login -u "${USR}" -p "${PASSWORD}" "${REGISTRY}"

# Login to IBM Cloud Private Cluster
cloudctl login -a "https://${CLUSTER_NAME}:8443" -n "${NAMESPACE}" -u "${USR}" -p "${PASSWORD}" -c "${ACCOUNT_ID}" --skip-ssl-validation

# Load PPA Archive and Images
cloudctl catalog load-ppa-archive -a bluecompute-ce-ppa-${CHART_VERSION}.tgz --registry ${REGISTRY}