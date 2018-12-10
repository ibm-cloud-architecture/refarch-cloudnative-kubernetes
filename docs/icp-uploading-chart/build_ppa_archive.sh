#!/bin/bash

CHART_VERSION=0.0.9

auth="ibmcase/bluecompute-auth:0.6.0"
bash="ibmcase/bluecompute-bash-curl-ssl:latest"
catalog="ibmcase/bluecompute-catalog:0.6.0"
curl="alexeiled/curl:latest"
elasticsearch="docker.elastic.co/elasticsearch/elasticsearch-oss:6.3.1"
busybox="busybox:latest"
customer="ibmcase/bluecompute-customer:0.6.0"
couchdb="couchdb:2.1.1"
couchdbhelper="kocolosk/couchdb-statefulset-assembler:1.1.0"
inventory="ibmcase/bluecompute-inventory:0.6.0"
mysql="mysql:5.7.14"
orders="ibmcase/bluecompute-orders:0.6.0"
mariadb="bitnami/mariadb:10.1.36-debian-9"
web="ibmcase/bluecompute-web:0.6.0"

_images="\
${auth} \
${bash} \
${catalog} \
${curl} \
${elasticsearch} \
${busybox} \
${customer} \
${couchdb} \
${couchdbhelper} \
${inventory} \
${mysql} \
${orders} \
${mariadb} \
${web}"

mkdir ppa_archive
mkdir -p ppa_archive/images
mkdir -p ppa_archive/charts

echo "Pulling images and saving in images/ ..."
for i in ${_images}; do
  docker pull ${i}

  if [ "$i" == "$bash" ]; then
  	new="ibmcase/bluecompute-bash-curl-ssl:latest"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$curl" ]; then
  	new="ibmcase/curl:latest"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$elasticsearch" ]; then
  	new="ibmcase/elasticsearch:6.3.1"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$busybox" ]; then
  	new="ibmcase/busybox:latest"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$couchdb" ]; then
  	new="ibmcase/couchdb:2.1.1"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$couchdbhelper" ]; then
  	new="ibmcase/couchdb-statefulset-assembler:1.1.0"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$mysql" ]; then
  	new="ibmcase/mysql:5.7.14"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  if [ "$i" == "$mariadb" ]; then
  	new="ibmcase/mariadb:10.1.36-debian-9"
    echo "Tagging \"${i}\" into ${new}";
    docker tag ${i} ${new}
  fi

  _shortname=`echo ${i} | cut -d'/' -f2 | cut -d':' -f1`
  docker save ${i} -o ppa_archive/images/${_shortname}.tar.gz

done

if [ -f ./bluecompute-ce-${CHART_VERSION}.tgz ]; then
  echo "Copying chart from ./bluecompute-ce-${CHART_VERSION}.tgz to charts/ ..."
  cp ./bluecompute-ce-${CHART_VERSION}.tgz ppa_archive/charts/
else
  echo "Copying chart from ../docs/charts/bluecompute-ce-${CHART_VERSION}.tgz to charts/ ..."
  cp ../charts/bluecompute-ce/bluecompute-ce-${CHART_VERSION}.tgz ppa_archive/charts/
fi

echo "Updating manifest.json with chart version ..."
sed -e 's/__CHART_VERSION__/'${CHART_VERSION}'/' manifest.json.tmpl > ppa_archive/manifest.json

echo "Updating manifest.yaml with chart version ..."
sed -e 's/__CHART_VERSION__/'${CHART_VERSION}'/' manifest.yaml.tmpl > ppa_archive/manifest.yaml

echo "Building bluecompute-ce-ppa-${CHART_VERSION}.tgz ..."
tar -C ./ppa_archive -czvf bluecompute-ce-ppa-${CHART_VERSION}.tgz images charts manifest.json manifest.yaml

rm -rf ./ppa_archive