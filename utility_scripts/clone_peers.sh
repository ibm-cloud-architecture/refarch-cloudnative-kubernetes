#!/bin/bash
#################################################################################
# Clone peer repositories
#################################################################################
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#Get the repo name for all the microservices
source $SCRIPTDIR/.reporc

GIT_AVAIL=$(which git)
if [ ${?} -ne 0 ]; then
  echo -e "${RED}git is not available on your local system.  Please install git for your operating system and try again.${NC}"
  exit 1
fi

#Optional overrides to allow for specific default branches to be used.
DEFAULT_BRANCH=${1:-microprofile}

#IBM Cloud Architecture GitHub Repository.
GITHUB_ORG=${CUSTOM_GITHUB_ORG:-ibm-cloud-architecture}
echo -e "Cloning from GitHub Organization or User Account of ${RED}\"${GITHUB_ORG}\"${NC}."
echo "--> To override this value, run \"export CUSTOM_GITHUB_ORG=your-github-org\" prior to running this script."
echo -e "Cloning from repository branch ${RED}\"${DEFAULT_BRANCH}\"${NC}."
echo "--> To override this value, pass in the desired branch as a parameter to this script. E.g \"./clone-peers.sh master\""
echo -e "Press ${GREEN}ENTER${NC} to continue"
read

#Clone all required repositories as a peer of the current directory (root refapp-cloudnative-wfd repository)
for REPO in ${REQUIRED_REPOS[@]}; do
  GIT_REPO="https://github.com/${GITHUB_ORG}/${REPO}.git"
  echo -e "\nCloning ${GREEN}${REPO}${NC} project"
  git clone -b ${DEFAULT_BRANCH} ${GIT_REPO} ../../${REPO}
done
