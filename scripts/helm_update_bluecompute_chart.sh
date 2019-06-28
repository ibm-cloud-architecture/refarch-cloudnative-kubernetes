#!/bin/bash

source ./colors.sh

REPO_NAMES="refarch-cloudnative-kubernetes"

# This will be used when building the chart location URL
GIT_ORG="ibm-cloud-architecture"

# Also used when building the chart location URL
GIT_BRANCH="spring"

# Convenience flag to stash uncommitted work when repackaging the charts
GIT_STASH="no"

# Chart name
CHART="bluecompute-ce"

# Helm repo location in git repo
HELM_REPO_LOCATION="docs/charts/${CHART}"

# The Base URL for the chart location
HELM_REPO_URL=$"https://raw.githubusercontent.com/${GIT_ORG}/refarch-cloudnative-kubernetes/${GIT_BRANCH}/${HELM_REPO_LOCATION}"

if [ "$GIT_STASH" = "yes" ]; then
  echo "Stashing"
  git stash
fi

helm repo add ibmcase-charts https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts
helm repo update

printf "\n\n${grn}Updating ${CHART} chart...${end}\n"
cd ../$CHART

helm dependency update
cd ..
helm lint $CHART
helm package $CHART
mv  -f *.tgz ${HELM_REPO_LOCATION}

if [ "$GIT_STASH" = "yes" ]; then
  echo "Popping Stash"
  git stash pop
fi

printf "\n\n${grn}Reindexing charts Helm repo...${end}\n"

helm repo index ${HELM_REPO_LOCATION} --url=${HELM_REPO_URL}

cd scripts