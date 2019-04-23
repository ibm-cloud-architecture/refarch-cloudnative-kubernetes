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

${HELM} delete web            --purge ${TLS}
${HELM} delete auth           --purge ${TLS}
${HELM} delete orders         --purge ${TLS}
${HELM} delete customer       --purge ${TLS}
${HELM} delete catalog        --purge ${TLS}
${HELM} delete inventory      --purge ${TLS}
${HELM} delete orders-mariadb --purge ${TLS}
${HELM} delete couchdb        --purge ${TLS}
${HELM} delete elasticsearch  --purge ${TLS}
${HELM} delete mysql          --purge ${TLS}