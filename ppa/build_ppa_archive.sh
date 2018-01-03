#!/bin/bash


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

mkdir -p images
mkdir -p charts

echo "Pulling images and saving in images/ ..."
for i in ${_images}; do
  docker pull ${i}
  _shortname=`echo ${i} | cut -d'/' -f2 | cut -d':' -f1`
  docker save ${i} -o images/${_shortname}.tar.gz
done

echo "Copying chart from ../docs/charts/bluecompute-ce/bluecompute-ce-0.0.3.tgz to charts/ ..."
cp ../docs/charts/bluecompute-ce/bluecompute-ce-0.0.3.tgz charts/


tar czvf bluecompute-ce-ppa-0.0.3.tgz images charts manifest.json manifest.yaml
