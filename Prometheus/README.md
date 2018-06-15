## WebSphere Liberty Metrics

1. Enable mpMetrics-1.0 in your `server.xml`.
2. For the service you wanted to enable the metrics, add the annotation metadata.

```
apiVersion: v1
kind: Service
metadata:
  annotations:
    bluecompute: "true"
  name: {{ .Release.Name }}-{{ .Values.service.name }}
  labels:
    chart: "{{ .Release.Name }}-{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
    implementation: microprofile
spec:
  type: {{ .Values.service.type }}
  ports:
  - name: http
    port: {{ .Values.service.servicePort }}
  - name: https
    port: {{ .Values.service.servicePortHttps }}
  selector:
    app: "{{ .Release.Name }}-{{  .Chart.Name }}-selector"
    implementation: microprofile
 ```
 
 In the above `service.yaml`, we defined the annotation `bluecompute: "true"` which will be used in the later steps.
 
 3. Populate a job with the name of the annotation metadata you created before in the configuartion file of Prometheus like below.
 
 ```
    # config for Liberty monitoring
    #

    - job_name: 'blue-compute'
      scheme: 'https'
      basic_auth:
        username: 'admin'
        password: 'password'
      tls_config:
        insecure_skip_verify: true
      kubernetes_sd_configs:
        - role: endpoints
      relabel_configs:
        - source_labels: [__meta_kubernetes_service_annotation_bluecompute]
          action: keep
          regex: true  
```

Reference - https://developer.ibm.com/recipes/tutorials/monitoring-websphere-liberty-in-ibm-cloud-private/
