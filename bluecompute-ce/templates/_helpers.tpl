{{- define "tlsSecretName" -}}
  {{- if .Values.tls.secretName -}}
    {{- printf "%s" .Values.tls.secretName -}}
  {{- else -}}
    {{- printf "%s-%s-tls" .Release.Name .Chart.Name -}}
  {{- end -}}
{{- end -}}