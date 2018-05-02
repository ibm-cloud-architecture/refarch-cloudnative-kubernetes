#!/bin/bash
# A sample Bash script, by Ryan
echo Hello World!
keytool -genkeypair -dname "cn=bc.ibm.com, o=Hema, ou=IBM, c=US" -alias bckey -keyalg RSA -keysize 2048 -keypass password -storetype JKS -keystore ./BCKeyStoreFile.jks -storepass password -validity 3650
keytool -list -keystore ./BCKeyStoreFile.jks -storepass password
keytool -export -alias bckey -file client.cer -keystore ./BCKeyStoreFile.jks
keytool -import -v -trustcacerts -alias bckey -file client.cer -keystore ./truststore.jks -storepass password -noprompt
kubectl version
kubectl create secret generic keystoresecret --from-file=./BCKeyStoreFile.jks --from-file=./truststore.jks
echo done!
