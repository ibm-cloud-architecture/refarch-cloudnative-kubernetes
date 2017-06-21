This directory holds Windows CLI utilities.
default files:
* Curl - since we use this file to download other files, not having it would give us a recursion problem :)

Files that will be placed here by install_cli.bat:
* Bluemix CLI installer
* kubectl
* jq
* yaml

Files that will be placed here manually:
* helm - this file can only be automatically downloaded as a zip, so we don't want to have a risk of unzipping a file without depending on zip utils, java and/or Powershell & .net

An unzipped instance is kept at https://ibm.box.com/s/m2iau50fdiblleoeafvd5svbd4uvmcdr and the user will be prompted to manually install it.
