This directory holds Windows CLI utilities.
default files:
* Curl - since we use this file to download other files, not having it would give us a recursion problem :)
* helm - this file can only be downloaded as a zip, so keeping the unzipped version here saves the effort of unzipping a file without depending on zip utils, java and/or Powershell & .net

files that will be placed here by install_cli.bat:
* Bluemix CLI installer
* kubectl
* jq
* yaml
