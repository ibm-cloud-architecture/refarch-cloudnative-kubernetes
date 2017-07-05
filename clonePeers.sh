#!/usr/bin/env bash

##############################################################################
##
##  Wrapper sript to pull all peer git repositories
##
##############################################################################

# Terminal Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'
coffee=$'\xE2\x98\x95'
coffee3="${coffee} ${coffee} ${coffee}"

# set environment
git_org="ibm-cloud-architecture"
repo_list="refarch-cloudnative-bluecompute-web \
           refarch-cloudnative-auth \
           refarch-cloudnative-micro-inventory \
           refarch-cloudnative-micro-orders \
           refarch-cloudnative-micro-customer \
           refarch-cloudnative-devops-kubernetes \
           refarch-cloudnative-resiliency \
           refarch-cloudnative-kubernetes-csmo"

GIT_BIN=$(which git)
if [ ${?} -ne 0 ]; then
  echo "${red}git not found on your local system.${end} Please install git and try again."
  exit 1
fi

# set branch name
if [ -z "$1" ]; then
    origin_branch=`git rev-parse --abbrev-ref HEAD`
else
    origin_branch=$1
fi
origin_branch=${origin_branch:-master}

# clone repos
currepo=$(git rev-parse --show-toplevel|awk -F '/' '{print $NF}')
echo "${grn}Cloning repos referenced in ${git_org}/${currepo} branch:${origin_branch}...${end}"
base_url="https://github.com/${git_org}"
clone_opts="-b ${origin_branch} --single-branch"
for repo in $repo_list
do
  repo_url="${base_url}/${repo}"
  printf "\n\n${grn}Cloning ${git_org}/${repo}...\n${end}"
  ${GIT_BIN} clone ${repo_url} ${clone_opts} ../${repo}
done

printf "\n${grn}Successfully cloned following repos from branch:${origin_branch}\n${end}"
ls ../ | grep -v refarch-cloudnative-kubernetes$
