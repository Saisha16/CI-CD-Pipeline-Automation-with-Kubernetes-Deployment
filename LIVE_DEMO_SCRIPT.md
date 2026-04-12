# Live Demonstration Script
## Step-by-Step Guide with Code, Output & Visualizations

This script walks through a complete end-to-end demo of the CI/CD pipeline for interviews or showcases. **Duration: 5-8 minutes** with narration.

---

## Pre-Demo Checklist (5 minutes before)

```powershell
# Terminal 1: Verify everything is running
docker ps                                    # Check Jenkins is running
minikube status                             # Check Kubernetes is running
kubectl get pods -n devops                  # Check app deployments exist
kubectl get svc -n monitoring               # Verify monitoring is installed
```

**Expected Output:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

NAMESPACE     NAME                                      READY   STATUS
devops        app-blue-xxxxxxxxxx-xxxxx                1/1     Running
devops        app-green-xxxxxxxxxx-xxxxx               1/1     Running
elasticsearch-0                                         1/1     Running
logstash-xxxxxxxxxx-xxxxx                              1/1     Running
kibana-xxxxxxxxxx-xxxxx                                1/1     Running
```

---

## Demo Flow

### **PHASE 1: Show Code Structure (1 minute)**

**Narration:** "This is a Spring Boot microservice with a complete DevOps delivery pipeline. Let me show you the codebase."

#### Step 1.1: Open GitHub Repository
```
🔗 https://github.com/Saisha16/CI-CD-Pipeline-Automation-with-Kubernetes-Deployment
```

**What to point out:**
- **app/** → Application source code
- **jenkins/Jenkinsfile** → Automated pipeline definition
- **k8s/** → Kubernetes deployment manifests (blue/green switch)
- **logging/** → ELK stack configuration
- **monitoring/** → Prometheus & Grafana setup
- **README.md** → Full architecture diagram

#### Step 1.2: Show Application Code
```powershell
# Show the REST endpoints
code app/src/main/java/com/example/App.java
```

**Key code to highlight:**
```java
@RestController
public class App {
    private static final Logger logger = LoggerFactory.getLogger(App.class);

    @GetMapping("/")
    public String home() {
        logger.info("Home endpoint called");
        return "Application is running!";
    }

    @GetMapping("/health")
    public String health() {
        logger.info("Health check called");
        return "OK";
    }
}
```

**Narration:** "The app has two endpoints: `/` for status and `/health` for Kubernetes probes."

#### Step 1.3: Show Application Tests
```powershell
# Show test coverage
code app/src/test/java/com/example/AppTest.java
```

**Key code to highlight:**
```java
@SpringBootTest
@AutoConfigureMockMvc
public class AppTest {
    @Autowired
    private MockMvc mvc;

    @Test
    public void homeEndpointReturnsApplicationStatus() throws Exception {
        mvc.perform(get("/"))
            .andExpect(status().isOk());
    }

    @Test
    public void healthEndpointReturnsOk() throws Exception {
        mvc.perform(get("/health"))
            .andExpect(status().isOk());
    }
}
```

**Narration:** "Tests automatically run in the pipeline before deployment."

---

### **PHASE 2: Trigger the Pipeline (1 minute)**

**Narration:** "Now I'll make a small code change and push it to GitHub. Jenkins automatically detects the change and runs the entire pipeline."

#### Step 2.1: Make a Test Commit
```powershell
cd d:\cicd

# Make a minor change (update timestamp in README or a comment)
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path README.md -Value "`n<!-- Last demo: $date -->"

# Push to GitHub
git add README.md
git commit -m "demo: trigger pipeline for live demonstration"
git push origin main
```

**Expected Output:**
```
[main 9a1b2c3] demo: trigger pipeline for live demonstration
 1 file changed, 2 insertions(+)
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression: (3/3), done.
Writing objects: 100% (3/3), 1.15 KiB | 598.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0)
remote: Resolving deltas: 100% (2/2), completed with 2 local objects
To https://github.com/Saisha16/CI-CD-Pipeline-Automation-with-Kubernetes-Deployment.git
   dc56f90..9a1b2c3  main -> main
```

**Narration:** "GitHub webhook automatically notifies Jenkins of the push. Let's watch the pipeline execute."

#### Step 2.2: Open Jenkins Console
```
🔗 http://localhost:8888
    Username: admin
    Password: [from docker logs Jenkins]
    Job: ci-cd-devops-project
```

**Visual Checkpoint:** Refresh Jenkins and watch stages flow:
- ✅ Checkout (gray → blue)
- ✅ Build (running...) 
- ✅ Test (running...)
- ✅ Docker Build (running...)
- ✅ Docker Push (running...)

---

### **PHASE 3: Watch Pipeline Execution (2-3 minutes)**

**Narration:** "Each stage of the pipeline runs automatically. Let's watch the key stages in detail."

#### Step 3.1: Build Stage
```
Jenkins Console Output:
```
[INFO] Copying 1 file to /var/jenkins_home/workspace/.../target
[INFO] Building jar: /var/jenkins_home/workspace/.../target/cicd-app-1.0.jar
[INFO] BUILD SUCCESS [0.123 s]
```

**Narration:** "Maven compiles the code, runs dependencies through the classpath, and packages it as a runnable JAR."

#### Step 3.2: Test Stage
```
Jenkins Console Output:
```
[INFO] Running com.example.AppTest
[INFO] Tests run: 2, Failures: 0, Skipped: 0, Time: 2.340s
[INFO] BUILD SUCCESS
```

**Narration:** "Two automated tests verify the endpoints work before we deploy. If tests fail, the pipeline stops here."

#### Step 3.3: Docker Build Stage
```
Jenkins Console Output:
```
Step 1/4 : FROM eclipse-temurin:17-jre
Step 2/4 : WORKDIR /app
Step 3/4 : COPY target/cicd-app-1.0.jar app.jar
Step 4/4 : ENTRYPOINT ["java", "-jar", "app.jar"]
Successfully built image: ghcr.io/saisha16/cicd-app:build-123
```

**Narration:** "The JAR is packaged into a Docker image with a minimal JRE base. The image is now ready to run anywhere."

#### Step 3.4: Docker Push Stage
```
Jenkins Console Output:
```
Pushing ghcr.io/saisha16/cicd-app:build-123
The push refers to repository [ghcr.io]
layer sha256:a1b2c3d4... Pushed 100%
Digest: sha256:abcd1234567890...
Status: Image successfully pushed
```

**Narration:** "The image is pushed to GitHub Container Registry. Kubernetes will pull this image when deploying."

#### Step 3.5: Watch in Real-Time (Open Jenkins console in browser)
```
🔗 http://localhost:8888/job/ci-cd-devops-project/lastBuild/console
```

**What to show on screen:**
```
[Pipeline] Start of Pipeline
  [Pipeline] checkout
    Cloning repository...
    Checking out Revision 9a1b2c3d...
  [Pipeline] Build
    [INFO] Building cicd-app 1.0
    [INFO] BUILD SUCCESS [8.523s]
  [Pipeline] Test
    [INFO] Running tests...
    [INFO] Tests run: 2, Failures: 0 [2.104s]
  [Pipeline] Docker Build & Push
    Building image...
    Pushing to registry...
    ✓ Pushed ghcr.io/saisha16/cicd-app:build-123
  [Pipeline] Determine Target Color
    Current active: blue
    Target deployment: green
  [Pipeline] Deploy
    Deploying to green deployment...
    Waiting for rollout...
    ✓ Green deployment ready
  [Pipeline] Switch Traffic
    Switching service selector: blue → green
    ✓ Traffic switched
  [Pipeline] Verify
    Active deployment: green
    Image: ghcr.io/saisha16/cicd-app:build-123
✓ Pipeline completed successfully [25.340s]
```

---

### **PHASE 4: Verify Deployment in Kubernetes (1 minute)**

**Narration:** "The pipeline deployed the new version to Kubernetes. Let's verify it's running."

#### Step 4.1: Check Deployment Status
```powershell
# Terminal 2: Watch Kubernetes deployment live
kubectl get pods -n devops -w
```

**Expected Output:**
```
NAME                                      READY   STATUS            RESTARTS   AGE
app-blue-xxxxxxxxxx-xxxxx                 1/1     Running           0          5h
app-green-xxxxxxxxxx-xxxxx                1/1     Running           0          2m
elasticsearch-0                           1/1     Running           0          3h
logstash-xxxxxxxxxx-xxxxx                 1/1     Running           0          3h
kibana-xxxxxxxxxx-xxxxx                   1/1     Running           0          3h
```

**Narration:** "Both blue and green are running. The service automatically routed traffic to the new green version after it passed health checks."

#### Step 4.2: Check Service Routing
```powershell
kubectl get svc app -n devops -o jsonpath='{.spec.selector}'
```

**Expected Output:**
```
{"app":"cicd-app","version":"green"}
```

**Narration:** "The service selector is pointing to `green` now. If the deployment fails, we can switch back to `blue` instantly."

#### Step 4.3: Test the Running Application
```powershell
# Port-forward the service
kubectl port-forward -n devops svc/app 8080:80

# In another terminal:
curl http://localhost:8080/
curl http://localhost:8080/health
```

**Expected Output:**
```
Application is running!

OK
```

**Narration:** "The application is responding to requests. The health endpoint is checked every 5 seconds by Kubernetes."

---

### **PHASE 5: Show Centralized Logging (1 minute)**

**Narration:** "The application logs are automatically shipped to Elasticsearch and visualized in Kibana. Let's see the logs from the deployment we just did."

#### Step 5.1: Open Kibana Dashboard
```powershell
# Port-forward Kibana
kubectl port-forward -n devops svc/kibana 5601:5601
```

```
🔗 http://localhost:5601
```

**Visual Checkpoint:**
1. **Create Index Pattern** (if first time)
   - Index name: `cicd-app-*`
   - Time field: `@timestamp`

2. **View Recent Logs**
   - Click **Discover** → Search logs
   - Filter: `kubernetes.pod_name: "app-green*"`
   - See recent entries:

```json
{
  "@timestamp": "2026-04-12T10:45:32.123Z",
  "message": "Health check called",
  "level": "INFO",
  "logger_name": "com.example.App",
  "kubernetes": {
    "pod_name": "app-green-xxxxxxxxxx-xxxxx",
    "namespace": "devops",
    "container_name": "app"
  }
}
```

**Narration:** "Every log message includes metadata about which pod it came from, the timestamp, and the log level. All logs are searchable and filterable in real-time."

#### Step 5.2: Show Log Volume During Deployment
```
Kibana Query: 
  kubernetes.pod_name: "app-green*" AND level: "INFO"
  Time range: Last 5 minutes
```

**Expected Result:**
```
Health check called         [10:45:32] app-green-abc123-def45
Home endpoint called        [10:45:35] app-green-abc123-def45
Health check called         [10:45:37] app-green-abc123-def45
...
(repeated every 5 seconds for readiness probes)
```

**Narration:** "The readiness probes are checking the health endpoint every 5 seconds. This ensures Kubernetes only routes traffic to healthy pods."

---

### **PHASE 6: Show Metrics & Monitoring (Optional, 1 minute)**

**Narration:** "Let's also look at real-time metrics collected by Prometheus and displayed in Grafana."

#### Step 6.1: Access Grafana
```powershell
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

```
🔗 http://localhost:3000
    Username: admin
    Password: prom-operator
```

#### Step 6.2: View Application Metrics Dashboard
```
Dashboards → Kubernetes Pods
  Filter by namespace: devops
  Select pod: app-green-*
```

**Visual Metrics to Show:**
- **CPU Usage:** Initial spike during startup, then stabilizes
- **Memory Usage:** Typical Java heap usage (~256Mi)
- **Network In/Out:** Shows traffic during health checks
- **HTTP Request Rate:** GET / and GET /health endpoints

**Narration:** "Grafana pulls metrics from Prometheus, which scrapes the application's `/actuator/prometheus` endpoint. You can set alerts on these metrics to notify teams of issues."

---

## Summary Visualization

### Blue → Green Transition Timeline

```
T=0s    Commit pushed to GitHub
        ↓
        Jenkins webhook triggered
        ↓
T=8s    Build & Test complete ✓
        ↓
T=15s   Docker image built & pushed ✓
        ↓
T=20s   Green deployment starts rolling out
        ↓
        Readiness probe checks /health
        ↓
T=23s   Green deployment ready (2 health checks passed)
        ↓
T=24s   Service selector: blue → green
        ↓
T=25s   ✓ NEW VERSION IS LIVE
        
        Old traffic still drains from blue
        Blue remains available for instant rollback
        
T=35s   All connections drained from blue
        ✓ BLUE remains running as backup
```

### Data Flow During Demo

```
Developer's Push
      ↓
GitHub Webhook
      ↓
Jenkins CI/CD
      ├→ Build (mvn)
      ├→ Test (JUnit)
      ├→ Docker Build & Push
      └→ Kubernetes Deploy
           ├→ Deploy Green
           ├→ Health Check
           └→ Switch Traffic
           
After Deployment:
      ├→ App Logs → Logstash → Elasticsearch → Kibana
      ├→ App Metrics → Prometheus → Grafana
      └→ Health Probes → Kubernetes → Auto-restart if needed
```

---

## Interview Talking Points

### "Why Blue-Green?"
> "Blue-green deployment eliminates downtime. The old version keeps serving while we deploy the new version separately. After health checks pass, we switch traffic instantly. If something fails, we revert immediately without redeploying."

### "How Do Tests Prevent Issues?"
> "Tests run before ANY Docker build or deployment. If a test fails, the pipeline stops immediately and the team is notified. We catch bugs in CI, not in production."

### "What Happens When Something Fails?"
> "The Jenkins post-failure block detects issues and automatically rolls back the service selector to the previously-active version. The new version stays deployed for investigation."

### "How Do You Monitor This?"
> "Three layers: (1) Kubernetes health probes check every 5 seconds, (2) Prometheus collects metrics for alerting, (3) ELK stack aggregates logs for debugging. If a pod restarts repeatedly, we see it in Prometheus. If there are errors, they're searchable in Kibana."

### "What About Scale?"
> "The HPA watches CPU usage and automatically scales from 2 to 5 pods when load increases. It targets the active deployment (whichever color is live), so scaling happens transparently."

---

## Troubleshooting During Demo

| Issue | Fix |
|-------|-----|
| Jenkins not triggering | Check GitHub webhook in repo Settings → Webhooks |
| Tests failing | Run `mvn test` locally to debug before pushing |
| Pods not becoming ready | Check `kubectl logs app-green-xxx -n devops` |
| Kibana showing no logs | Verify `SPRING_PROFILES_ACTIVE=kubernetes` env var in deployment |
| Slow pipeline (>60s) | Normal on first run (Docker pulls). Subsequent builds are cached (~15s) |
| Docker push fails | Verify registry credentials in Jenkins → Credentials → Add credentials |
| Grafana dashboard blank | Wait 1-2 minutes for Prometheus to scrape metrics |

---

## Demo Commands Cheat Sheet

```powershell
# Pre-demo verification (run once, then keep running)
kubectl get pods -n devops -w

# Make a change and trigger pipeline
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path README.md -Value "`n<!-- Demo: $date -->"
git add README.md; git commit -m "demo: trigger"; git push origin main

# Watch Jenkins
open http://localhost:8888/job/ci-cd-devops-project/lastBuild/console

# Test the app
kubectl port-forward -n devops svc/app 8080:80
# Then: curl http://localhost:8080/

# View logs
kubectl port-forward -n devops svc/kibana 5601:5601
# Then: open http://localhost:5601

# View metrics
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Then: open http://localhost:3000
```

---

## Time Budget

- **Pre-demo setup**: 5 minutes
- **Phase 1 (Code)**: 1 minute
- **Phase 2 (Trigger)**: 1 minute
- **Phase 3 (Pipeline)**: 2-3 minutes ← Let Jenkins run while you narrate
- **Phase 4 (Kubernetes)**: 1 minute
- **Phase 5 (Kibana Logs)**: 1 minute
- **Phase 6 (Grafana Metrics)**: 1 minute (optional)
- **Q&A**: 2-3 minutes

**Total: 5-10 minutes for a complete demo**

---

## Success Criteria

✅ Jenkins pipeline completes all stages (Checkout, Build, Test, Docker, Deploy, Switch)
✅ Kubernetes shows both deployments running (blue + green)
✅ Service selector points to active color
✅ `curl http://localhost:8080/` returns "Application is running!"
✅ Kibana shows recent logs from the active pod
✅ Grafana shows metrics for the active pod
✅ You can explain why each component exists (design decisions clear)

