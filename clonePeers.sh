#!/usr/bin/env bash

##############################################################################
##
##  Wrapper sript to pull all peer git repositories
##
##############################################################################

# set environment
git_org="ibm-cloud-architecture"
repo_list="refarch-cloudnative-bluecompute-mobile \
           refarch-cloudnative-bluecompute-web \
           refarch-cloudnative-bluecompute-bff-ios \
           refarch-cloudnative-auth \
           refarch-cloudnative-micro-inventory \
           refarch-cloudnative-micro-orders \
           refarch-cloudnative-micro-customer \
           refarch-cloudnative-netflix-hystrix \
           refarch-cloudnative-devops \
           refarch-cloudnative-resiliency \
           refarch-cloudnative-csmo"

GIT_BIN=$(which git)
if [ ${?} -ne 0 ]; then
  echo "git not found on your local system.  Please install git and try again."
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
echo "Cloning repos referenced in ${git_org}/${currepo} branch:${origin_branch}..."
base_url="https://github.com/${git_org}"
clone_opts="-b ${origin_branch} --single-branch"
for repo in $repo_list
do
  repo_url="${base_url}/${repo}"
  echo "\nclone ${git_org}/${repo}.."
  ${GIT_BIN} clone ${repo_url} ${clone_opts} ../${repo}
done

echo "\nSuccessfully cloned following repos from branch:${origin_branch}"
ls ../ | grep -v refarch-cloudnative-kubernetes
