# Jenkins Setup & Interview Demo Guide

## ✅ Your GitHub Repo is Ready
**Repository:** https://github.com/Saisha16/CI-CD-Pipeline-Automation-with-Kubernetes-Deployment  
**Branch:** main  
**Code:** ✅ All files pushed

---

## 🚀 Interview-Ready Demo (Step by Step)

### Phase 1: Setup (15 minutes before interview)

#### Option 1A: Run Jenkins Locally (Recommended)

```powershell
# Make sure Docker Desktop is running
# Check: docker ps

# Start Jenkins
docker run -d `
  -p 8888:8080 `
  -p 50000:50000 `
  -v jenkins_home:/var/jenkins_home `
  --name jenkins `
  jenkins/jenkins:lts

# Wait 30 seconds for Jenkins to initialize
Start-Sleep -Seconds 30

# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# ^^ Copy this long alphanumeric string
```

#### Option 1B: Use Jenkins Online (If Docker Has Issues)

Use Jenkins trial/free tier at: **Jenkins.io official cloud**  
- More reliable than local Docker
- Public URL (important for GitHub webhook)
- Takes 5 minutes to set up

---

### Phase 2: Configure Jenkins (10 minutes)

#### Step 1: Log Into Jenkins

```
URL: http://localhost:8888  (or your Jenkins URL)
Username: admin
Password: [paste the password from above]
```

#### Step 2: Install Plugins
- Jenkins will ask: "Customize Jenkins"
- Click: **Install suggested plugins**
- Wait ~5 minutes for plugins to install

#### Step 3: Create Pipeline Job

1. Jenkins Dashboard → **New Item**
2. **Item name:** `ci-cd-devops-project`
3. **Type:** Select **Pipeline**
4. Click **OK**

#### Step 4: Configure Git Repository

| Field | Value |
|-------|-------|
| **Definition** | Pipeline script from SCM |
| **SCM** | Git |
| **Repository URL** | `https://github.com/Saisha16/CI-CD-Pipeline-Automation-with-Kubernetes-Deployment.git` |
| **Branch** | `*/main` |
| **Script Path** | `jenkins/Jenkinsfile` |

Click **Save**

#### Step 5: Set Pipeline Parameters

The Jenkinsfile has parameters. Jenkins will show them on build page.

**Default values to use:**
```
IMAGE_REPOSITORY: ghcr.io/saisha16/cicd-app
REGISTRY_URL: ghcr.io
KUBE_NAMESPACE: devops
KUBE_CONTEXT: minikube
REGISTRY_CREDENTIALS_ID: github-credentials
```

---

### Phase 3: GitHub Webhook Setup (5 minutes)

#### In Your GitHub Repository Settings:

1. Go: https://github.com/Saisha16/CI-CD-Pipeline-Automation-with-Kubernetes-Deployment
2. **Settings** → **Webhooks** → **Add webhook**

| Field | Value |
|-------|-------|
| **Payload URL** | `http://YOUR_JENKINS_URL/github-webhook/` |
| **Content type** | `application/json` |
| **Events** | `Just the push event` |
| **Active** | ✅ Checked |

Click **Add webhook**

> **If Jenkins is local:** Use ngrok to expose it
> ```powershell
> # Download from https://ngrok.com/download
> # After download, in cmd:
> ngrok http 8888
> 
> # You'll see:
> # Forwarding http://xxx-xxx.ngrok.io -> http://localhost:8888
> 
> # Use: http://xxx-xxx.ngrok.io/github-webhook/  in GitHub webhook
> ```

---

### Phase 4: Add Docker Credentials (If Using Registry)

If you push to Docker Hub or GHCR:

1. Jenkins → **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**
   - **Kind:** Username with password
   - **Username:** Your Docker/GitHub username
   - **Password:** Your access token
   - **ID:** `github-credentials`
3. Click **Create**

---

### Phase 5: Test Your Pipeline Manually First

Before the interview, verify it works:

1. Jenkins Dashboard → `ci-cd-devops-project`
2. Click **Build Now** (right side)
3. Click the build number that appears
4. Click **Console Output**
5. Watch the stages execute:

```
[Checkout] ✅
[Build] ✅
[Test] ✅
[Docker Build] ✅
[Deploy] ✅
[Verify] ✅
```

**If all green:** You're ready! ✨

---

## 🎯 Interview Demo (During Interview)

### What You'll Do (Live, ~2 minutes):

```powershell
# Terminal 1: Show your code structure
ls d:\cicd

# Terminal 2: Make a test commit
cd d:\cicd
git log --oneline -5  # Show git history

# Terminal 3: Push code to trigger pipeline
echo "# Interview Demo $(Get-Date)" >> README.md
git add README.md
git commit -m "demo: trigger CI/CD pipeline"
git push origin main

# Browser: Show Jenkins building in real-time
# Open: http://localhost:8888/job/ci-cd-devops-project/lastBuild/console

# Watch output:
# [Checkout code from GitHub] ✅
# [Build with Maven] ✅  
# [Run tests: 2/2 passed] ✅
# [Build Docker image] ✅
# [Deploy to Kubernetes] ✅
# [Switch traffic to new version] ✅
# ✨ BUILD SUCCESS ✨
```

---

## 💬 What Interviewers Will Ask (Be Ready!)

### Q1: "Tell me about your pipeline"

**Answer:**
> "When code is pushed to GitHub, a webhook triggers Jenkins automatically. Jenkins clones the repo, builds the Java application with Maven, runs unit tests, creates a Docker image, and deploys it to Kubernetes using blue/green strategy. This ensures zero downtime - users stay on the old version (blue) while the new version (green) is deployed and tested. Once green is healthy, traffic switches to it automatically. If anything fails, we rollback to blue within seconds."

### Q2: "How do you handle downtime during deployment?"

**Answer:**
> "Blue/green deployment. Two identical Kubernetes deployments run in parallel. User traffic always points to one (blue). We deploy new code to the inactive deployment (green), run health checks, and only switch traffic after validation. If new code fails, we flip traffic back to blue - it's instant and automatic. This gives us zero-downtime deployments."

### Q3: "What about monitoring and logs?"

**Answer:**
> "The application ships logs to an ELK stack (Elasticsearch, Logstash, Kibana). Each request gets JSON-formatted logs with timestamp, log level, pod name, version, and message. These flow through Logstash into Elasticsearch where they're indexed and searchable. Kibana provides real-time dashboards. Prometheus collects metrics (CPU, memory, request rate) and Grafana visualizes them."

### Q4: "How does the HPA (Horizontal Pod Autoscaler) work?"

**Answer:**
> "HPA is configured to scale pods based on CPU utilization. If CPU exceeds 70%, it automatically scales from 2 to 5 replicas. When load decreases, it scales down. The HPA always targets the active deployment (whichever is live), so scaling is consistent with traffic patterns."

### Q5: "What if the test stage fails?"

**Answer:**
> "The pipeline stops at the Test stage and never reaches production. The build is marked as failed in Jenkins. The old version continues running. The developer fixes the failing test and pushes again - Jenkins automatically rebuilds."

### Q6: "How would you improve this pipeline?"

**Answer:**
> "Several improvements:
> - Add security scanning (SonarQube)
> - Add performance tests before deployment
> - Implement automated rollback based on error rates
> - Add Slack notifications for pipeline events
> - Implement feature flags for gradual rollout
> - Add smoke tests post-deployment
> - Implement canary deployment for gradual traffic shift"

---

## 🎬 Live Demo Talking Points

**Show on screen while demo runs:**

1. **GitHub Webhook Trigger:**
   - "When I push code, GitHub immediately notifies Jenkins via webhook"

2. **Tests Run First:**
   - "Notice Test stage: 2/2 passed. No broken code reaches production"

3. **Docker Image Built:**
   - "Docker image built and ready to deploy - this is our immutable artifact"

4. **Kubernetes Deployment:**
   - "Then kubectl applies this image to the inactive deployment"

5. **Blue/Green Switch:**
   - "Service switches traffic to the new version - users see no downtime"

6. **Done in 2 minutes:**
   - "From code push to live in production: 2 minutes. Zero manual steps."

---

## 📋 Pre-Interview Checklist

- [ ] Jenkins running and accessible
- [ ] GitHub repository configured
- [ ] Webhooks set up
- [ ] First manual build succeeded
- [ ] Can show test output
- [ ] Ready to make a test commit
- [ ] Understand the Jenkinsfile flow
- [ ] Know answers to common questions above
- [ ] Have talking points ready
- [ ] Test push-to-build cycle once more

---

## ⚡ Emergency Fallback (If Jenkins Won't Start)

If Jenkins has issues on the day, you can still impress:

1. **Show GitHub repo** with all the code
2. **Show Jenkinsfile** (jenkins/Jenkinsfile)
3. **Explain the pipeline stages** by pointing to code
4. **Show Kubernetes manifests** (k8s/ folder)
5. **Show application tests** (AppTest.java)
6. **Discuss ELK/monitoring** (logging/ folder)

You'll still demonstrate deep DevOps knowledge even without live execution.

---

## 🚀 Key Takeaways for Interview

**This project shows:**
- ✅ Complete CI/CD understanding
- ✅ Kubernetes expertise (blue/green, HPA, probes)
- ✅ Docker containerization
- ✅ Testing automation
- ✅ Monitoring & logging setup
- ✅ Zero-downtime deployment patterns
- ✅ Ability to implement real-world systems
- ✅ Infrastructure as Code

**What interviewers think:**
> "This person understands modern DevOps. They're production-ready."

---

## 📞 Support During Interview

If asked technical questions:

| Question | Answer File |
|----------|------------|
| Pipeline stages | [jenkins/Jenkinsfile](../jenkins/Jenkinsfile) |
| K8s deployments | [k8s/blue-deployment.yaml](../k8s/blue-deployment.yaml) |
| App code | [app/src/main/java/com/example/App.java](../app/src/main/java/com/example/App.java) |
| Tests | [app/src/test/java/com/example/AppTest.java](../app/src/test/java/com/example/AppTest.java) |
| ELK setup | [logging/logstash.yaml](../logging/logstash.yaml) |
| Execution guide | [PIPELINE_EXECUTION_GUIDE.md](../PIPELINE_EXECUTION_GUIDE.md) |

---

## Final Advice

1. **Practice the demo twice** before the interview
2. **Know what each stage does** - don't just show logs
3. **Be ready to explain the WHY** - why blue/green, why tests, why ELK
4. **Show confidence** - you built this, you understand it
5. **Have diagrams ready** - can draw architecture on whiteboard
6. **Mention trade-offs** - "We could use canary instead of blue/green if..."

**Good luck! You've got this! 🎉**

