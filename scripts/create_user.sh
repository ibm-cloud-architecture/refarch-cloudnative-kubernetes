#!/bin/bash
NAMESPACE=$1
HS256_KEY=E6526VJkKYhyTFRFMC0pTECpHcZ7TGcq8pKsVVgz9KtESVpheEO284qKzfzg8HpWNBPeHOxNGlyudUHi6i8tFQJXC8PiI48RUpMh23vPDLGD35pCM0417gf58z5xlmRNii56fwRCmIhhV7hDsm3KO2jRv4EBVz7HrYbzFeqI45CaStkMYNipzSm2duuer7zRdMjEKIdqsby0JfpQpykHmC5L6hxkX0BT7XWqztTr6xHCwqst26O0g8r7bXSYjp4a;
TEST_USER=user
TEST_PASSWORD=passw0rd
CUSTOMER_HOST=127.0.0.1
CUSTOMER_PORT=8082

# INVENTORY_URL
if [ -z "$NAMESPACE" ]; then
	NAMESPACE="default"
	echo "No NAMESPACE provided! Using ${NAMESPACE}"
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
	jwt2=$(echo -n "{\"scope\":[\"blue\"],\"user_name\":\"${TEST_USER}\"}" | openssl enc -base64);
	# JWT Signature: Header and Payload
	jwt3=$(echo -n "${jwt1}.${jwt2}" | tr '+\/' '-_' | tr -d '=' | tr -d '\r\n');
	# JWT Signature: Create signed hash with secret key
	jwt4=$(echo -n "${jwt3}" | openssl dgst -binary -sha256 -hmac "${secret}" | openssl enc -base64 | tr '+\/' '-_' | tr -d '=' | tr -d '\r\n');
	# Complete JWT
	jwt_blue=$(echo -n "${jwt3}.${jwt4}");

	#echo $jwt_blue
}

function create_user() {
	CURL=$(curl --write-out %{http_code} --silent --output /dev/null --max-time 5 -X POST "http://${CUSTOMER_HOST}:${CUSTOMER_PORT}/micro/customer" -H "Content-type: application/json" -H "Authorization: Bearer ${jwt}" -d "{\"username\": \"${TEST_USER}\", \"password\": \"${TEST_PASSWORD}\", \"firstName\": \"user\", \"lastName\": \"name\", \"email\": \"user@name.com\"}");

	# Check for 201 Status Code
	if [ "$CURL" == "400" ]; then
		printf "create_user: ❌ \n${CURL}\n";
		echo "user exists already! Deleting user and retrying user creation"
		delete_user
		create_user
    elif [ "$CURL" != "201" ]; then
		printf "create_user: ❌ \n${CURL}\n";
		kill_port_forwarding;
        exit 1;
    else 
    	echo "create_user: ✅";
    fi
}

function search_user() {
	CURL=$(curl -s --max-time 5 -X GET "http://${CUSTOMER_HOST}:${CUSTOMER_PORT}/micro/customer/search?username=${TEST_USER}" -H 'Content-type: application/json' -H "Authorization: Bearer ${jwt}" | jq -r '.[0].username' | grep ${TEST_USER});
	#echo "Found user with name: \"${CURL}\""

	if [ "$CURL" != "$TEST_USER" ]; then
		echo "search_user: ❌ could not find user";
		kill_port_forwarding;
        exit 1;
    else 
    	echo "search_user: ✅";
    fi
}

function delete_user() {
	CUSTOMER_ID=$(curl -s --max-time 5 -X GET "http://${CUSTOMER_HOST}:${CUSTOMER_PORT}/micro/customer/search?username=${TEST_USER}" -H 'Content-type: application/json' -H "Authorization: Bearer ${jwt}" | jq -r '.[0].customerId');
	
	#echo "Deleting customer with name: ${TEST_USER} and id: ${CUSTOMER_ID}"
	CURL=$(curl --write-out %{http_code} --silent --output /dev/null --max-time 5 -X DELETE "http://${CUSTOMER_HOST}:${CUSTOMER_PORT}/micro/customer/${CUSTOMER_ID}" -H "Content-type: application/json" -H "Authorization: Bearer ${jwt}");

	# Check for 201 Status Code
	if [ "$CURL" != "200" ]; then
		printf "delete_user: ❌ \n${CURL}\n";
        exit 1;
    else 
    	echo "delete_user: ✅";
    fi
}

function kill_port_forwarding() {
	killall kubectl
}

# Setup
create_jwt_admin
create_jwt_blue

# Wait for customer to be ready?

# Forward port
echo "Forwarding customer port 8082"
kubectl -n $NAMESPACE port-forward deployment/customer 8082:8082 --pod-running-timeout=1h &
echo "Sleeping for 3 seconds while connection is established..."
sleep 3

# Create user and search
echo "Starting Tests"
create_user
search_user

# Kill port forwarding
kill_port_forwarding