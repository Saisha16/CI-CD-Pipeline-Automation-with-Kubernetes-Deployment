# Quick Start: Run Your First CI/CD Pipeline

## ✅ Pre-Flight Checklist

### Prerequisites (Already Done)
- [x] Java 17 installed
- [x] Maven installed  
- [x] Docker installed
- [x] kubectl installed
- [x] Minikube installed
- [x] Code with tests ✅
- [x] Blue/green deployments ✅
- [x] ELK stack (Elasticsearch/Logstash/Kibana) ✅
- [x] Probes & HPA configured ✅

---

## 🚀 Option A: Minimal Demo (Skip Jenkins for now)

If you just want to see the app running with real logs in Kibana:

```powershell
# 1. Build the Docker image locally
cd d:\cicd
docker build -f app/Dockerfile -t cicd-app:v1 app

# 2. Start minikube
minikube start --driver=docker

# 3. Load image into minikube
minikube image load cicd-app:v1

# 4. Deploy to Kubernetes (this includes ELK stack)
.\scripts\deploy-k8s.ps1 -ImageRepository "cicd-app" -ImageTag "v1"

# 5. Verify deployment
kubectl get pods -n devops
kubectl get svc -n devops

# 6. Access the running app
kubectl port-forward -n devops svc/app-service 8080:80
# In browser: http://localhost:8080/health

# 7. Access logs in Kibana
kubectl port-forward -n devops svc/kibana 5601:5601
# In browser: http://localhost:5601
# Create index pattern: cicd-app-*
# Click Discover and watch live logs
```

**What you'll see:**
- ✅ App responding on port 8080
- ✅ Logs appearing in Kibana in real-time
- ✅ Blue/green deployment switching when you redeploy
- ✅ Pod scaling via HPA

**Time: 10 minutes**

---

## 🔥 Option B: Full CI/CD Pipeline with Jenkins (Recommended)

### Step 1: Setup GitHub Repository

```powershell
# Initialize git locally
cd d:\cicd
git add .
git commit -m "Initial project setup"

# Add remote (replace with your GitHub repo)
git remote add origin https://github.com/YOUR_USERNAME/cicd-project.git
git branch -M main
git push -u origin main
```

### Step 2: Run Jenkins Locally (in Docker)

```powershell
# Start Jenkins in a Docker container
docker run -d `
  -p 8888:8080 `
  -p 50000:50000 `
  -v jenkins_home:/var/jenkins_home `
  --name jenkins `
  jenkins/jenkins:lts

# Wait 30 seconds for Jenkins to start, then get the initial password
Start-Sleep -Seconds 30
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Open Jenkins: http://localhost:8888
# Use the password above to log in
# Follow setup wizard → Install suggested plugins
```

### Step 3: Configure Docker Hub Credentials in Jenkins

1. Jenkins Dashboard → **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**
   - Kind: **Username with password**
   - Username: Your Docker Hub username
   - Password: Your Docker Hub access token (from hub.docker.com/settings/security)
   - ID: `dockerhub-credentials`
3. Click **Create**

### Step 4: Create the Pipeline Job in Jenkins

1. Jenkins Dashboard → **New Item**
2. **Item name:** `ci-cd-devops-project`
3. **Type:** Select **Pipeline**
4. Click **OK**

#### Configure Pipeline:

**General Tab:**
- ✅ Enable `GitHub project`
- Project URL: `https://github.com/YOUR_USERNAME/cicd-project`

**Build Triggers:**
- ✅ Check `GitHub hook trigger for GITScm polling`

**Pipeline Section:**
- **Definition:** `Pipeline script from SCM`
- **SCM:** `Git`
  - Repository URL: `https://github.com/YOUR_USERNAME/cicd-project.git`
  - Credentials: (select your GitHub credentials or create new)
  - Branch: `*/main`
  - Script Path: `jenkins/Jenkinsfile`

Click **Save**

### Step 5: Setup GitHub Webhook

In your GitHub repository:

1. Settings → **Webhooks** → **Add webhook**
2. **Payload URL:** `http://YOUR_IP:8888/github-webhook/`
   - If running locally: `http://localhost:8888/github-webhook/`
   - If remote: `http://your-jenkins-server:8888/github-webhook/`
3. **Content type:** `application/json`
4. **Which events?** `Just the push event`
5. Click **Add webhook**

> **Note:** If Jenkins is on your local machine, you need ngrok or localtunnel to expose it to GitHub:
> ```powershell
> # Install ngrok: https://ngrok.com/download
> ngrok http 8888
> # Use the URL from ngrok output in your GitHub webhook
> ```

### Step 6: Update Jenkins Pipeline Parameters

1. Jenkins Dashboard → `ci-cd-devops-project` → **Configure**
2. Scroll to **Pipeline Parameters** section
3. Set defaults:
   - `IMAGE_REPOSITORY`: `docker.io/YOUR_DOCKERHUB_USERNAME/cicd-app`
   - `REGISTRY_URL`: `docker.io`
   - `REGISTRY_CREDENTIALS_ID`: `dockerhub-credentials`
   - `KUBE_NAMESPACE`: `devops`
   - `KUBE_CONTEXT`: `minikube`
4. Click **Save**

### Step 7: Trigger Your First Pipeline

#### Option A: Manual Trigger
- Go to `ci-cd-devops-project`
- Click **Build Now**
- Watch the stages execute in real-time

#### Option B: Automatic Trigger (via GitHub push)

```powershell
# Make a change
echo "# Updated $(Get-Date)" >> README.md

# Commit and push
git add .
git commit -m "test: trigger jenkins pipeline"
git push origin main

# GitHub webhook sends notification to Jenkins
# Jenkins automatically starts the build!
# Watch it in: http://localhost:8888/job/ci-cd-devops-project/lastBuild/console
```

---

## 📊 Monitor the Pipeline Execution

### Jenkins Console
```
http://localhost:8888/job/ci-cd-devops-project/[BUILD_NUMBER]/console
```

Watch stages execute:
```
[Checkout] ✅ 5 sec
[Build] ✅ 15 sec
[Test] ✅ 8 sec (2 tests passed)
[Determine Target Color] ✅ 2 sec
[Docker Build] ✅ 20 sec
[Docker Push] ✅ 15 sec
[Render Manifests] ✅ 3 sec
[Deploy] ✅ 30 sec
[Switch Traffic] ✅ 5 sec
[Verify] ✅ 5 sec
```

### Watch Kubernetes Deployment

```powershell
# In another terminal, watch pods being created
kubectl get pods -n devops -w

# Watch services
kubectl get svc -n devops

# Watch HPA scaling
kubectl get hpa -n devops -w
```

### View Application Logs in Real-Time

```powershell
# Port-forward Kibana
kubectl port-forward -n devops svc/kibana 5601:5601

# Open http://localhost:5601
# Create index pattern: cicd-app-*
# Go to Discover → filter by your app logs
# Watch new logs appear as requests come in
```

### Make Requests to Generate Logs

```powershell
# Get the app service URL
kubectl service app-service -n devops --url

# Or use port-forward
kubectl port-forward -n devops svc/app-service 8080:80

# Make requests
Invoke-WebRequest http://localhost:8080/
Invoke-WebRequest http://localhost:8080/health
Invoke-WebRequest http://localhost:8080/actuator/prometheus

# Watch logs appear in Kibana instantly!
```

---

## 🔄 Test Blue/Green Deployment

### Trigger a New Deployment

```powershell
# Make a code change
echo "# New feature" >> README.md

# Commit and push (or manually trigger with "Build Now")
git add .
git commit -m "feature: add new functionality"
git push origin main

# Watch Jenkins pipeline:
# - If BLUE is active, it deploys to GREEN
# - Tests new GREEN
# - Switches traffic to GREEN
# - OLD BLUE becomes fallback for rollback
```

### Check Which Version is Live

```powershell
kubectl -n devops get svc app-service -o jsonpath='{.spec.selector.version}'
# Output: green  (or blue)

# See both deployments
kubectl -n devops get deploy -o wide
# Shows both app-blue and app-green running

# Make request and check logs
kubectl logs -n devops -l app=cicd --tail=20
```

---

## 🚨 Test Rollback

### Scenario: Deployment Fails

```powershell
# The pipeline will automatically rollback in these cases:
# 1. Test fails (stage 3)
# 2. Deployment fails (stage 8)
# 3. Ready replicas don't reach target (stage 8)

# Result:
# ✅ Service traffic returns to active color
# ✅ HPA targets active deployment
# ✅ Failed deployment stays for debugging
# ✅ Zero downtime
```

### Manual Rollback (if needed)

```powershell
# Determine current active color
$active = kubectl -n devops get svc app-service -o jsonpath='{.spec.selector.version}'

# If active is green, rollback to blue
if ($active -eq 'green') {
    kubectl -n devops patch service app-service -p '{"spec":{"selector":{"version":"blue"}}}'
    kubectl -n devops patch hpa app-hpa -p '{"spec":{"scaleTargetRef":{"name":"app-blue"}}}'
}

# Verify
kubectl -n devops get svc app-service -o jsonpath='{.spec.selector.version}'
```

---

## 📈 Monitor Performance

### Prometheus Metrics

```powershell
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open: http://localhost:9090

# Query examples:
# up{job="kubernetes-pods"} → Overall health
# rate(http_requests_total[5m]) → Request rate
# container_memory_usage_bytes{pod=~"app-.*"} → Memory per pod
```

### Grafana Dashboard

```powershell
# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open: http://localhost:3000
# Default creds: admin / prom-operator

# Pre-built dashboards available for:
# - Pod CPU/Memory
# - Network I/O
# - Prometheus targets
```

---

## 🐛 Troubleshooting

### Jenkins can't connect to Docker
```powershell
docker ps  # Verify Docker is running
# If Jenkins container can't see host Docker
docker exec jenkins docker ps  # Should work
```

### GitHub webhook not triggering Jenkins
```powershell
# Check GitHub Settings → Webhooks → Recent Deliveries
# Verify payload URL is reachable
# If local Jenkins: use ngrok to expose it
```

### Pods not reaching ready state
```powershell
kubectl describe pod APP_POD_NAME -n devops
kubectl logs APP_POD_NAME -n devops

# Check readiness probe:
kubectl get pod APP_POD_NAME -n devops -o yaml | grep -A 20 readinessProbe
```

### Logs not appearing in Kibana
```powershell
# Verify Logstash is running
kubectl get pod -n devops -l app=logstash
kubectl logs -n devops -l app=logstash --tail=50

# Check Elasticsearch
kubectl get pod -n devops -l app=elasticsearch
curl http://localhost:9200/_cat/indices  # Check indices
```

---

## ✨ What You'll See

After following these steps:

### ✅ Jenkins Console Output
```
Successfully logged in to docker.io
Docker build: 157 MB image created
Docker push: 100% uploaded
Kubernetes: 2/2 pods ready
Service: Traffic switched to green
Health check: Passed
🎉 Build #145 complete in 2m 15s
```

### ✅ Kubernetes Logs
```
$ kubectl logs -n devops -l version=green --tail=20
2026-04-12 20:28:45 INFO com.example.App - Starting App v1.0
2026-04-12 20:28:46 INFO o.s.b.w.e.tomcat.TomcatWebServer - Tomcat started on port 8080
2026-04-12 20:28:47 INFO com.example.App - Home endpoint requested
2026-04-12 20:28:48 INFO com.example.App - Health endpoint requested
```

### ✅ Kibana Dashboard
```
Logs from cicd-app-2026.04.12 (live feed)
@timestamp: 2026-04-12T20:28:47Z
level: INFO
message: Home endpoint requested
pod: app-green-5b8d9f4c2a
version: green
```

---

## 🎯 Summary Timeline

| Step | Time | What Happens |
|------|------|--------------|
| You push code | T+0 | GitHub webhook notifies Jenkins |
| Jenkins triggered | T+5s | Pipeline starts, checks out code |
| Build & Test | T+30s | Maven builds JAR, runs 2 tests ✅ |
| Docker image | T+60s | Image built and pushed to Docker Hub |
| Deployment | T+90s | New version deployed to Kubernetes |
| Traffic switch | T+120s | Requests routed to new version |
| Logs visible | T+120s | App logs flowing to Kibana |
| **Total time** | **~2 min** | New code live in production |

---

## Next: What to Do

1. **Choose your path:**
   - ✅ Quick demo (Option A): 10 min, see app + logs
   - ✅ Full pipeline (Option B): 30 min, see Jenkins + automation

2. **Pick one and start!**

3. **Push a test commit** and watch it all happen

4. **Celebrate** when your pipeline works! 🎉

