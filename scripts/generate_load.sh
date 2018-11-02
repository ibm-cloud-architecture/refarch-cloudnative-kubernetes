#!/bin/bash
HS256_KEY=E6526VJkKYhyTFRFMC0pTECpHcZ7TGcq8pKsVVgz9KtESVpheEO284qKzfzg8HpWNBPeHOxNGlyudUHi6i8tFQJXC8PiI48RUpMh23vPDLGD35pCM0417gf58z5xlmRNii56fwRCmIhhV7hDsm3KO2jRv4EBVz7HrYbzFeqI45CaStkMYNipzSm2duuer7zRdMjEKIdqsby0JfpQpykHmC5L6hxkX0BT7XWqztTr6xHCwqst26O0g8r7bXSYjp4a;
TEST_USER=user;
TEST_PASSWORD=passw0rd;
ITEM_ID=13401

# trap ctrl-c and call ctrl_c() to stop port forwarding
trap ctrl_c INT

function ctrl_c() {
	echo "** Trapped CTRL-C... Killing Port Forwarding and Stopping Load";
	killall kubectl;
	exit 0;
}

function start_port_forwarding() {
	echo "Forwarding customer ports 8000, 8080, 8081, 8082, 8083, 8084";
	kubectl port-forward deployment/web-web 			8000:8000 --pod-running-timeout=1h &
	kubectl port-forward deployment/inventory-inventory 8080:8080 --pod-running-timeout=1h &
	kubectl port-forward deployment/catalog-catalog 	8081:8081 --pod-running-timeout=1h &
	kubectl port-forward deployment/customer-customer 	8082:8082 --pod-running-timeout=1h &
	kubectl port-forward deployment/auth-auth 			8083:8083 --pod-running-timeout=1h &
	kubectl port-forward deployment/orders-orders 		8084:8084 --pod-running-timeout=1h &
	echo "Sleeping for 3 seconds while connection is established...";
	sleep 3;
}

function create_jwt_admin() {
	# Secret Key
	secret=${HS256_KEY};
	# JWT Header
	jwt1=$(echo -n '{"alg":"HS256","typ":"JWT"}' | openssl enc -base64);
	# JWT Payload
	jwt2=$(echo -n "{\"scope\":[\"admin\"],\"user_name\":\"${TEST_USER}\"}" | openssl enc -base64);
	# JWT Signature: Header and Payload
	jwt3=$(echo -n "${jwt1}.${jwt2}" | tr '+\/' '-_' | tr -d '=' | tr -d '\r\n');
	# JWT Signature: Create signed hash with secret key
	jwt4=$(echo -n "${jwt3}" | openssl dgst -binary -sha256 -hmac "${secret}" | openssl enc -base64 | tr '+\/' '-_' | tr -d '=' | tr -d '\r\n');
	# Complete JWT
	jwt=$(echo -n "${jwt3}.${jwt4}");

	#echo $jwt	
}

function create_jwt_blue() {
	# Secret Key
	secret=${HS256_KEY};
	# JWT Header
	jwt1=$(echo -n '{"alg":"HS256","typ":"JWT"}' | openssl enc -base64);
	# JWT Payload
	jwt2=$(echo -n "{\"scope\":[\"blue\"],\"user_name\":\"admin\"}" | openssl enc -base64);
	# JWT Signature: Header and Payload
	jwt3=$(echo -n "${jwt1}.${jwt2}" | tr '+\/' '-_' | tr -d '=' | tr -d '\r\n');
	# JWT Signature: Create signed hash with secret key
	jwt4=$(echo -n "${jwt3}" | openssl dgst -binary -sha256 -hmac "${secret}" | openssl enc -base64 | tr '+\/' '-_' | tr -d '=' | tr -d '\r\n');
	# Complete JWT
	jwt_blue=$(echo -n "${jwt3}.${jwt4}");

	#echo $jwt_blue
}

# Port Forwarding
start_port_forwarding

# Load Generation
echo "Generating load for all services..."
create_jwt_admin
create_jwt_blue

while true; do
	# Web -> Catalog -> Elasticsearch
	curl -s localhost:8000/catalog > /dev/null;

	# Inventory -> MySQL
	curl -s localhost:8080/micro/inventory > /dev/null;

	# Catalog -> Elasticsearch
	curl -s localhost:8081/micro/items > /dev/null;

	# Customer -> CouchDB
	curl -s -X GET "localhost:8082/micro/customer/search?username=${TEST_USER}" \
		-H 'Content-type: application/json' -H "Authorization: Bearer ${jwt}" > /dev/null;

	# Auth -> Customer -> CouchDB
	curl -s -X POST -u bluecomputeweb:bluecomputewebs3cret \
		localhost:8083/oauth/token\?grant_type\=password\&username\=${TEST_USER}\&password\=${TEST_PASSWORD}\&scope\=blue > /dev/null;

	# Orders -> MariaDB
	curl -s -H "Authorization: Bearer ${jwt_blue}" localhost:8084/micro/orders > /dev/null;

	sleep 0.2;
done