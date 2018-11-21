{{- define "bluecompute.fullname" -}}
  {{- .Release.Name }}-{{ .Chart.Name -}}
{{- end -}}

{{- define "bluecompute.labels" }}
app: bluecompute
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
MySQL
*/}}
{{- define "bluecompute.mysql.fullname" -}}
{{- if .Values.mysql.fullnameOverride -}}
{{- .Values.mysql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "mysql" .Values.mysql.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Elasticsearch
*/}}
{{- define "bluecompute.elasticsearch.fullname" -}}
{{- if .Values.elasticsearch.fullnameOverride -}}
{{- .Values.elasticsearch.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "elasticsearch" .Values.elasticsearch.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "bluecompute.elasticsearch.client.fullname" -}}
{{ template "bluecompute.elasticsearch.fullname" . }}-{{ .Values.elasticsearch.client.name }}
{{- end -}}

{{/*
CouchDB
*/}}
{{- define "bluecompute.couchdb.fullname" -}}
{{- if .Values.couchdb.fullnameOverride -}}
{{- printf "%s-%s" .Values.couchdb.fullnameOverride "couchdb" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "couchdb" .Values.couchdb.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
In the event that we create both a headless service and a traditional one,
ensure that the latter gets a unique name.
*/}}
{{- define "bluecompute.couchdb.svcname" -}}
{{- if .Values.couchdb.fullnameOverride -}}
{{- printf "%s-svc-%s" .Values.couchdb.fullnameOverride "couchdb" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "couchdb" .Values.couchdb.nameOverride -}}
{{- printf "%s-svc-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
MariaDB
*/}}
{{- define "bluecompute.mariadb.fullname" -}}
{{- $name := default "mariadb" .Values.mariadb.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bluecompute.mariadb.slave.fullname" -}}
{{- printf "%s-%s" .Release.Name "mariadb-slave" | trunc 63 | trimSuffix "-" -}}
{{- end -}}