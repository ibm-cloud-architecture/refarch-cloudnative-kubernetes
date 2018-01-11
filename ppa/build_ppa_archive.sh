#!/bin/bash

CHART_VERSION=0.0.4

_images="\
ibmcase/bluecompute-dataloader:latest \
ibmcase/bluecompute-bash-curl-ssl:latest \
ibmcase/bluecompute-mysql:latest \
ibmcase/bluecompute-elasticsearch:latest \
ibmcase/bluecompute-couchdb:latest \
ibmcase/bluecompute-auth:latest \
ibmcase/bluecompute-catalog:latest \
ibmcase/bluecompute-customer:latest \
ibmcase/bluecompute-inventory:latest \
ibmcase/bluecompute-orders:latest \
ibmcase/bluecompute-web:latest"

mkdir ppa_archive
mkdir -p ppa_archive/images
mkdir -p ppa_archive/charts

echo "Pulling images and saving in images/ ..."
for i in ${_images}; do
  docker pull ${i}
  _shortname=`echo ${i} | cut -d'/' -f2 | cut -d':' -f1`
  docker save ${i} -o ppa_archive/images/${_shortname}.tar.gz
done

if [ -f ./bluecompute-ce-${CHART_VERSION}.tgz ]; then
  echo "Copying chart from ./bluecompute-ce-${CHART_VERSION}.tgz to charts/ ..."
  cp ./bluecompute-ce-${CHART_VERSION}.tgz ppa_archive/charts/
else
  echo "Copying chart from ../docs/charts/bluecompute-ce-${CHART_VERSION}.tgz to charts/ ..."
  cp ../docs/charts/bluecompute-ce/bluecompute-ce-${CHART_VERSION}.tgz ppa_archive/charts/
fi

echo "Updating manifest.json with chart version ..."
sed -e 's/__CHART_VERSION__/'${CHART_VERSION}'/' manifest.json.tmpl > ppa_archive/manifest.json

echo "Updating manifest.yaml with chart version ..."
sed -e 's/__CHART_VERSION__/'${CHART_VERSION}'/' manifest.yaml.tmpl > ppa_archive/manifest.yaml

echo "Building bluecompute-ce-ppa-${CHART_VERSION}.tgz ..."
tar -C ./ppa_archive -czvf bluecompute-ce-ppa-${CHART_VERSION}.tgz images charts manifest.json manifest.yaml

rm -rf ./ppa_archive
