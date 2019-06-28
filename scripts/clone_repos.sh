#!/bin/bash

source ./colors.sh

GIT_ORG="ibm-cloud-architecture"

REPO_NAMES="\
refarch-cloudnative-micro-inventory \
refarch-cloudnative-micro-catalog \
refarch-cloudnative-micro-customer \
refarch-cloudnative-micro-orders \
refarch-cloudnative-auth \
refarch-cloudnative-bluecompute-web"

cd ../..

for i in ${REPO_NAMES}; do
	printf "${grn}\n\nCloning ${GIT_ORG}/${i}${end}\n\n"
	git clone -b spring --single-branch https://github.com/${GIT_ORG}/${i}
done

cd refarch-cloudnative-kubernetes/scripts