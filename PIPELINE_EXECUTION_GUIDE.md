# CI/CD Pipeline Execution Guide

## What Happens When You Push Code

Here's the exact sequence of events that occurs when you commit and push to GitHub:

```
Developer: git push origin main
          ↓
GitHub: Runs webhook → POST http://jenkins:8080/github-webhook/
          ↓
Jenkins: Detects push trigger (githubPush() in Jenkinsfile)
          ↓
Jenkins: Starts "ci-cd-devops-project" pipeline build
```

---

## Pipeline Stages (In Order)

### **Stage 1: Checkout** ✅
**What it does:** Git clone your repository into the Jenkins workspace
```
[Jenkins Build Log]
Checking out repository from GitHub...
Cloning into workspace...
Branch: main
```

---

### **Stage 2: Build** 🔨
**What it does:** Compile Java code, create JAR file (tests are skipped here for speed)
```
[Jenkins Build Log]
mvn -f app/pom.xml clean package -DskipTests

[INFO] Scanning for projects...
[INFO] Building cicd-app 1.0
[INFO] --- compiler:3.11.0:compile (default-compile) @ cicd-app ---
[INFO] Compiling 1 source file
[INFO] --- jar:3.3.0:jar (default-jar) @ cicd-app ---
[INFO] Building jar: target/cicd-app-1.0.jar
[INFO] BUILD SUCCESS
```

**Output:** `app/target/cicd-app-1.0.jar`

---

### **Stage 3: Test** 🧪
**What it does:** Run JUnit tests - validates endpoints and health checks before proceeding
```
[Jenkins Build Log]
mvn -f app/pom.xml test

[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.AppTest

[INFO] Running com.example.AppTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0

✅ homeEndpointReturnsApplicationStatus - PASSED
✅ healthEndpointReturnsOk - PASSED

[INFO] BUILD SUCCESS
```

**If this fails:** Pipeline STOPS here. You fix the tests and push again.

---

### **Stage 4: Determine Target Color** 🔵🟢
**What it does:** Detects which deployment is currently live, then targets the inactive one
```
[Jenkins Build Log]
kubectl -n devops get svc app-service -o jsonpath='{.spec.selector.version}'

Current active color: blue
Target color: green  ← New version will go here

env.ACTIVE_COLOR = "blue"
env.TARGET_COLOR = "green"
```

---

### **Stage 5: Docker Build** 🐳
**What it does:** Creates a Docker image from the JAR and pushes to registry
```
[Jenkins Build Log]
docker build -f app/Dockerfile -t ghcr.io/your-org/cicd-app:42 app

[+] Building 15.2s (5/5) FINISHED
 => [internal] load build definition               0.1s
 => [internal] load .dockerignore                  0.0s
 => [internal] load metadata               8.3s
 => [base] FROM eclipse-temurin:17-jre    4.2s
 => COPY target/cicd-app-1.0.jar app.jar            0.1s
 => exporting to image                              2.5s

Successfully built image: ghcr.io/your-org/cicd-app:42
```

**Output:** Docker image ready to push (~150 MB)

---

### **Stage 6: Docker Push** 📤
**What it does:** Authenticates to Docker registry and pushes the image
```
[Jenkins Build Log]
docker login ghcr.io
docker push ghcr.io/your-org/cicd-app:42

The push refers to repository [ghcr.io/your-org/cicd-app]
42e1234d56f7: Pushed
a8f9c3d2e1b6: Pushed
4f1e2d3c4b5a: Pushed

Latest: digest sha256:abc123... size 157MB
Image successfully pushed to registry ✅
```

**Registry now has:** `ghcr.io/your-org/cicd-app:42` (accessible to Kubernetes)

---

### **Stage 7: Render Manifests** 📝
**What it does:** Replace placeholders in Kubernetes YAML files with actual values
```
[Jenkins Build Log]
Processing k8s/*.yaml and logging/*.yaml...

Replacements made:
- __KUBE_NAMESPACE__ → devops
- __IMAGE_REPOSITORY__ → ghcr.io/your-org/cicd-app
- __IMAGE_TAG__ → 42
- __TARGET_COLOR__ → green

Generated files in .rendered-k8s/:
✅ namespace.yaml
✅ service.yaml
✅ green-deployment.yaml  ← Will target THIS
✅ blue-deployment.yaml   ← Keep as fallback
✅ hpa.yaml
✅ elasticsearch.yaml
✅ logstash.yaml
✅ kibana.yaml
```

---

### **Stage 8: Deploy Inactive Color** 🚀
**What it does:** Deploy new version to the inactive deployment (green), validate health, wait for readiness
```
[Jenkins Build Log]
kubectl apply -f namespace.yaml
kubectl apply -f elasticsearch.yaml
kubectl apply -f logstash.yaml
kubectl apply -f kibana.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
kubectl apply -f green-deployment.yaml

[Jenkins monitors rollout...]
deployment/app-green rolled out
Waiting for 2 replicas to be ready...

pod/app-green-5b8d9f4c2a - RUNNING ✅
pod/app-green-7c3e2d1b9a - RUNNING ✅

Health check: curl http://app-green:8080/health → 200 OK ✅
Readiness probe: PASSED ✅
```

**At this point:**
- Green deployment is running with new code
- Blue deployment still serves all user traffic
- No downtime yet

---

### **Stage 9: Switch Traffic** 🔄
**What it does:** Update service selector to point to the new version (blue/green switch happens instantly)
```
[Jenkins Build Log]
kubectl -n devops patch service app-service \
  -p '{"spec":{"selector":{"version":"green"}}}'

service/app-service patched

Result:
✅ All traffic NOW goes to green deployment
❌ Blue deployment is idle (ready for rollback if needed)
```

**User impact:** ~100ms connection interruption (existing connections drop, new requests go to green)

---

### **Stage 10: Verify Deployment Evidence** 📊
**What it does:** Print proof of the deployment for Jenkins logs
```
[Jenkins Build Log]
Current service selector version: green

Current deployment images:
NAME                  IMAGE
app-green            ghcr.io/your-org/cicd-app:42  ← LIVE
app-blue             ghcr.io/your-org/cicd-app:41  ← FALLBACK

✅ Pipeline completed successfully!
```

---

## What Users See During Deployment

### Timeline:
```
T+0s:   User visits app.example.com
        → Request goes to blue (v1.0)

T+10s:  You push code to GitHub
        → Jenkins starts build

T+45s:  Jenkins finishes build, tests pass

T+120s: Docker image pushed, deployment starts to green (v2.0)
        → Blue still handles traffic
        → Green starts up with readiness probes

T+150s: Green is ready
        → Service switches to green instantly
        → User's next request → green (v2.0)

T+200s: If green fails
        → Automatic rollback patches service back to blue
        → User traffic returns to v1.0 within seconds
```

---

## Logs Flow Through the System

### **Where Logs Go:**

```
Application (App.java)
    ↓ [INFO] Home endpoint requested
    ↓ [INFO] Health endpoint requested
    ↓
logback-spring.xml (with kubernetes profile active)
    ↓
Logstash (TCP port 5000)
    ├→ Elasticsearch (stores indexed logs)
    │   └→ index: cicd-app-2026.04.12
    │
    └→ stdout (debug output)

Access logs in Kibana Dashboard:
    1. Port-forward: kubectl port-forward svc/kibana 5601:5601
    2. Open: http://localhost:5601
    3. Create index pattern: cicd-app-*
    4. View logs instantly as app serves requests
```

### **Example Log Entry in Kibana:**
```json
{
  "@timestamp": "2026-04-12T20:28:39.562Z",
  "message": "Home endpoint requested",
  "level": "INFO",
  "logger_name": "com.example.App",
  "version": "green",
  "pod": "app-green-5b8d9f4c2a",
  "namespace": "devops"
}
```

---

## Monitoring During Deployment

### **Prometheus Metrics (auto-exposed):**
- CPU usage per pod
- Memory usage per pod
- HTTP request count
- HTTP error rate
- JVM metrics

### **Access Prometheus:**
```powershell
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Then: http://localhost:9090
```

### **Access Grafana Dashboard:**
```powershell
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Then: http://localhost:3000
# Default: admin / prom-operator
```

---

## Rollback Scenario

If the test stage fails or deployment fails:

```
Pipeline Failure
    ↓
[Post Block] - Automatic Rollback
    ↓
kubectl patch service app-service -p '{"spec":{"selector":{"version":"blue"}}}'
kubectl patch hpa app-hpa -p '{"spec":{"scaleTargetRef":{"name":"app-blue"}}}'
    ↓
✅ Traffic returns to blue (old version)
✅ Green deployment stays for debugging
✅ Zero downtime
```

---

## Full Deployment Timeline Example

```
Push: git commit -m "add new feature"
      git push origin main

Jenkins logs:
20:28:00 - Webhook triggered by GitHub
20:28:05 - Checkout code
20:28:15 - Build JAR (Maven compile)
20:28:25 - Run tests: 2/2 passed ✅
20:28:35 - Determine target color: green
20:28:45 - Docker build: ghcr.io/org/app:145
20:29:05 - Docker push: uploaded 157MB
20:29:15 - Render K8s manifests
20:29:25 - Deploy to green in devops namespace
20:29:45 - Wait for readiness: 2/2 pods ready ✅
20:30:00 - Switch traffic to green
20:30:05 - Verify: green is live ✅

Total Time: ~2 minutes from push to live in production
User Downtime: 0 (blue/green handles it)
Rollback: 5 seconds (patch service selector back to blue)
```

---

## Key Takeaways

✅ **Automated:** One push triggers everything  
✅ **Tested:** Code validation before deployment  
✅ **Safe:** Blue/green prevents outages  
✅ **Fast:** ~2 min from push to live  
✅ **Observable:** Logs visible in Kibana instantly  
✅ **Recoverable:** Rollback in seconds  
✅ **Scalable:** HPA adjusts pods based on load  

---

## Next Steps

1. **Push test code** to GitHub
2. **Configure Jenkins webhook** to listen for pushes
3. **Set Docker Hub credentials** in Jenkins
4. **Create Jenkins pipeline job** pointing to your repo
5. **Watch the magic happen** as you push code!

