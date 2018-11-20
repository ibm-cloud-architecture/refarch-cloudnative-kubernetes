#!/bin/bash
BASE_URL="$1"
INVENTORY_URL="$2"
CATALOG_URL="$3"
CUSTOMER_URL="$4"
AUTH_URL="$5"
ORDERS_URL="$6"
WEB_URL="$7"

HS256_KEY=E6526VJkKYhyTFRFMC0pTECpHcZ7TGcq8pKsVVgz9KtESVpheEO284qKzfzg8HpWNBPeHOxNGlyudUHi6i8tFQJXC8PiI48RUpMh23vPDLGD35pCM0417gf58z5xlmRNii56fwRCmIhhV7hDsm3KO2jRv4EBVz7HrYbzFeqI45CaStkMYNipzSm2duuer7zRdMjEKIdqsby0JfpQpykHmC5L6hxkX0BT7XWqztTr6xHCwqst26O0g8r7bXSYjp4a;
TEST_USER=user;
TEST_PASSWORD=passw0rd;
ITEM_ID=13401

# INVENTORY_URL
if [ -z "$INVENTORY_URL" ] && [ -z "$BASE_URL" ]; then
	INVENTORY_URL="http://localhost:8080"
	echo "No INVENTORY_URL or BASE_URL provided! Using ${INVENTORY_URL}"

elif [ -z "$INVENTORY_URL" ]; then
	INVENTORY_URL="${BASE_URL}"
	echo "No INVENTORY_URL provided! Using ${INVENTORY_URL}"
fi

# CATALOG_URL
if [ -z "$CATALOG_URL" ] && [ -z "$CATALOG_URL" ]; then
	CATALOG_URL="http://localhost:8081"
	echo "No CATALOG_URL or BASE_URL provided! Using ${CATALOG_URL}"

elif [ -z "$CATALOG_URL" ]; then
	CATALOG_URL="${BASE_URL}"
	echo "No CATALOG_URL provided! Using ${CATALOG_URL}"
fi

# CUSTOMER_URL
if [ -z "$CUSTOMER_URL" ] && [ -z "$BASE_URL" ]; then
	CUSTOMER_URL="http://localhost:8082"
	echo "No CUSTOMER_URL or BASE_URL provided! Using ${CUSTOMER_URL}"

elif [ -z "$CUSTOMER_URL" ]; then
	CUSTOMER_URL="${BASE_URL}"
	echo "No CUSTOMER_URL provided! Using ${CUSTOMER_URL}"
fi

# AUTH_URL
if [ -z "$AUTH_URL" ] && [ -z "$BASE_URL" ]; then
	AUTH_URL="http://localhost:8083"
	echo "No AUTH_URL or BASE_URL provided! Using ${AUTH_URL}"

elif [ -z "$AUTH_URL" ]; then
	AUTH_URL="${BASE_URL}"
	echo "No AUTH_URL provided! Using ${AUTH_URL}"
fi

# ORDERS_URL
if [ -z "$ORDERS_URL" ] && [ -z "$BASE_URL" ]; then
	ORDERS_URL="http://localhost:8084"
	echo "No ORDERS_URL or BASE_URL provided! Using ${ORDERS_URL}"

elif [ -z "$ORDERS_URL" ]; then
	ORDERS_URL="${BASE_URL}"
	echo "No ORDERS_URL provided! Using ${ORDERS_URL}"
fi

# WEB_URL
if [ -z "$WEB_URL" ] && [ -z "$BASE_URL" ]; then
	WEB_URL="http://localhost:8000"
	echo "No WEB_URL or BASE_URL provided! Using ${WEB_URL}"

elif [ -z "$WEB_URL" ]; then
	WEB_URL="${BASE_URL}"
	echo "No WEB_URL provided! Using ${WEB_URL}"
fi



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

# Load Generation
echo "Generating load for all services..."
create_jwt_admin
create_jwt_blue

while true; do
	# Web -> Catalog -> Elasticsearch
	curl -s "${WEB_URL}/catalog" > /dev/null;

	# Inventory -> MySQL
	curl -s "${INVENTORY_URL}/micro/inventory" > /dev/null;

	# Catalog -> Elasticsearch
	curl -s "${CATALOG_URL}/micro/items" > /dev/null;

	# Customer -> CouchDB
	curl -s -X GET "${CUSTOMER_URL}/micro/customer/search?username=${TEST_USER}" \
		-H 'Content-type: application/json' -H "Authorization: Bearer ${jwt}" > /dev/null;

	# Auth -> Customer -> CouchDB
	curl -s -X POST -u bluecomputeweb:bluecomputewebs3cret \
		"${AUTH_URL}/oauth/token\?grant_type\=password\&username\=${TEST_USER}\&password\=${TEST_PASSWORD}\&scope\=blue" > /dev/null;

	# Orders -> MariaDB
	curl -s -H "Authorization: Bearer ${jwt_blue}" "${ORDERS_URL}/micro/orders" > /dev/null;

	echo -n .;
	sleep 0.2;
done