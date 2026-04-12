# Monitoring Setup Notes

## What Is Included

- Prometheus and Grafana via `kube-prometheus-stack` Helm chart.
- A `PodMonitor` for the CI/CD app at `monitoring/podmonitor-cicd-app.yaml`.
- Spring Boot actuator + Prometheus metrics endpoint at `/actuator/prometheus`.

## Install Monitoring Stack

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/prometheus-values.yaml
```

## Apply App PodMonitor

```powershell
kubectl --context minikube apply -f monitoring/podmonitor-cicd-app.yaml
```

## Verify Prometheus Is Scraping App Metrics

```powershell
kubectl --context minikube -n monitoring get podmonitor
kubectl --context minikube -n devops get pods -l app=cicd
```

In Prometheus targets page, verify a target for the app endpoint:

- `/actuator/prometheus`
- namespace `devops`

## Open Grafana (Minikube)

```powershell
kubectl --context minikube -n monitoring port-forward service/monitoring-grafana 3000:80
```

Open: http://localhost:3000

Fetch admin password:

```powershell
kubectl --context minikube -n monitoring get secret monitoring-grafana -o jsonpath='{.data.admin-password}'
```

Decode password:

```powershell
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('<PASTE_BASE64_PASSWORD>'))
```

## Useful Starter Dashboards

- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Networking / Namespace (Pods)
- JVM (Micrometer) dashboard for Spring Boot metrics

## App Metrics Endpoint Check

If app is running locally:

```powershell
Invoke-WebRequest -Uri 'http://localhost:8080/actuator/prometheus' -UseBasicParsing | Select-Object -ExpandProperty StatusCode
```

Expected status code: `200`
