{{- define "bluecompute.fullname" -}}
  {{- .Release.Name }}-{{ .Chart.Name -}}
{{- end -}}

{{- define "bluecompute.labels" }}
app: bluecompute
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "bluecompute.tls.secretName" -}}
  {{- if .Values.tls.secretName -}}
    {{- printf "%s" .Values.tls.secretName -}}
  {{- else -}}
    {{- printf "%s-%s-tls" .Release.Name .Chart.Name -}}
  {{- end -}}
{{- end -}}
