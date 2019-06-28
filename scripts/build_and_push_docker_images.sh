#!/bin/bash

source ./colors.sh

REGISTRY="docker.io"

NAMESPACE="ibmcase"

TAG="0.6.0"

function dockerBuildAndPush {
	DIRECTORY=$1
	IMAGE_NAME=$2

	FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}"

	printf "\n\n${grn}Updating ${FULL_IMAGE_NAME} docker image...${end}\n"
	cd $DIRECTORY
	docker build -t ${FULL_IMAGE_NAME} . && docker push ${FULL_IMAGE_NAME}
	cd ..
}

cd ../..

dockerBuildAndPush "refarch-cloudnative-micro-inventory" 	"bluecompute-inventory"
dockerBuildAndPush "refarch-cloudnative-micro-catalog" 		"bluecompute-catalog"
dockerBuildAndPush "refarch-cloudnative-micro-customer" 	"bluecompute-customer"
dockerBuildAndPush "refarch-cloudnative-micro-orders" 		"bluecompute-orders"
dockerBuildAndPush "refarch-cloudnative-auth" 				"bluecompute-auth"
dockerBuildAndPush "refarch-cloudnative-bluecompute-web" 	"bluecompute-web"

cd refarch-cloudnative-kubernetes/scripts