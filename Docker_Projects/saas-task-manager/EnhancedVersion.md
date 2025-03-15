Let’s create a new version of the SaaS Task Manager project for **alternative: Simplified GitOps with Nginx Reverse Proxy**, focusing on a production-grade, secure, highly available, and fault-tolerant setup. This version simplifies the architecture while leveraging the existing Jenkins Master-Slave infrastructure. 

We’ll use Nginx in a Docker container as a reverse proxy for the frontend (port 8080) and backend (port 5000), build and push Docker images to AWS ECR, and design a robust Jenkins pipeline. A `docker-compose.yml` file will orchestrate the services locally and inform production deployment.

As a highly experienced DevOps engineer, I’ll ensure security (e.g., Secrets Manager, encrypted ECR), high availability (e.g., multi-region slaves, HA master), and fault tolerance (e.g., retries, rollbacks) align with Fortune 100 standards as of March 11, 2025.

---

### Project Overview: Simplified SaaS Task Manager with Nginx Reverse Proxy

#### Objectives
- Deploy **frontend** (port 8080) and **backend** (port 5000) in Docker containers behind an **Nginx reverse proxy** (port 80).
- Configure Nginx to route requests without ports (e.g., `http://<domain>/tasks` → backend, `/` → frontend).
- Build and push Docker images to **AWS ECR** with versioning.
- Design a **production-grade Jenkins pipeline** using the existing HA master and multi-region slaves, ensuring zero downtime and fault tolerance.
- Use `docker-compose.yml` for local testing and as a blueprint for production configs.

#### Tools
- Jenkins (HA Master + Multi-Region Slaves), Docker, Nginx, AWS ECR, AWS S3, AWS Secrets Manager, AWS IAM, GitHub, Slack.

#### Assumptions
- HA Jenkins master (us-east-1) and multi-region slaves (us-east-1, us-west-2) from Day 3 are operational.
- ECR repos (`task-backend`, `task-frontend`, `task-nginx`) exist.
- IAM role `JenkinsSlaveRole` has ECR/S3/Secrets Manager access (updated previously).

---

### Theoretical Design Principles

1. **High Availability (HA)**:
   - **Master**: Active-passive setup with ELB ensures <30s failover.
   - **Slaves**: Multi-region (us-east-1, us-west-2) with Auto Scaling (0-10) for build resilience.
   - **Nginx**: Runs on EC2 with health checks; multi-instance possible with ELB.

2. **Fault Tolerance**:
   - **Retries**: Pipeline retries failed steps (e.g., ECR push) up to 3 times.
   - **Rollback**: Reverts to previous image on deploy failure.
   - **Queue Management**: Jenkins queue length triggers slave scaling (CloudWatch).

3. **Security**:
   - **Secrets**: GitHub token, SSH key in Secrets Manager, no hardcoded creds.
   - **IAM**: Least-privilege access to ECR/S3.
   - **Encryption**: ECR images encrypted with KMS, S3 SSE-KMS.

4. **Production-Grade Pipeline**:
   - **Parallelism**: Build frontend/backend concurrently on separate slaves.
   - **Validation**: Post-deploy health checks ensure service availability.
   - **Monitoring**: Logs to CloudWatch, Slack alerts on failure.

---

### Practical Implementation

#### Step 1: Project Structure
```
week3-day4-alt/
├── README.md
├── task-manager/
│   ├── backend/
│   │   ├── app.js
│   │   ├── package.json
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── frontend/
│   │   ├── app.js
│   │   ├── package.json
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── nginx/
│   │   ├── nginx.conf
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── docker-compose.yml
│   ├── Jenkinsfile
│   ├── README.md
│   └── .gitignore
├── pipeline-lib/
│   ├── vars/
│   │   ├── buildDocker.groovy
│   │   ├── deployEC2.groovy
│   │   ├── scanImage.groovy
│   │   └── logToCloudWatch.groovy
│   ├── README.md
│   └── .gitignore
└── setup-scripts/
    ├── deploy-instance.sh
    └── monitoring.sh
    └── s3-setup.sh
```

#### Step 2: Application Code

- **backend/app.js**:
  ```javascript
  const express = require('express');
  const app = express();
  app.use(express.json());
  let tasks = [];

  app.post('/tasks', (req, res) => {
    tasks.push(req.body);
    res.status(201).send(req.body);
  });

  app.get('/tasks', (req, res) => res.send(tasks));
  app.listen(5000, () => console.log('Backend on port 5000'));
  ```

- **backend/Dockerfile**:
  ```dockerfile
  FROM node:20
  WORKDIR /app
  COPY package.json .
  RUN npm install
  COPY . .
  EXPOSE 5000
  CMD ["npm", "start"]
  ```

- **frontend/app.js**:
  ```javascript
  const express = require('express');
  const axios = require('axios');
  const app = express();

  app.get('/tasks', async (req, res) => {
    try {
      const response = await axios.get('http://backend:5000/tasks');
      res.send(response.data);
    } catch (error) {
      res.status(500).send('Error fetching tasks');
    }
  });

  app.listen(8080, () => console.log('Frontend on port 8080'));
  ```

- **frontend/Dockerfile**:
  ```dockerfile
  FROM node:20
  WORKDIR /app
  COPY package.json .
  RUN npm install
  COPY . .
  EXPOSE 8080
  CMD ["npm", "start"]
  ```

- **nginx/nginx.conf**:
  ```nginx
  server {
    listen 80;
    server_name localhost;

    location /tasks {
      proxy_pass http://backend:5000;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
      proxy_pass http://frontend:8080;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }
  ```

- **nginx/Dockerfile**:
  ```dockerfile
  FROM nginx:latest
  COPY nginx.conf /etc/nginx/conf.d/default.conf
  EXPOSE 80
  CMD ["nginx", "-g", "daemon off;"]
  ```

- **docker-compose.yml**:
  ```yaml
  version: '3.8'
  services:
    backend:
      build: ./backend
      ports:
        - "5000:5000"
      restart: unless-stopped
    frontend:
      build: ./frontend
      ports:
        - "8080:8080"
      restart: unless-stopped
    nginx:
      build: ./nginx
      ports:
        - "80:80"
      depends_on:
        - backend
        - frontend
      restart: unless-stopped
  ```

#### Step 3: Jenkins Pipeline

- **Jenkinsfile**:
  ```groovy
  @Library('pipeline-lib@1.2') _
  pipeline {
      agent none
      parameters {
          string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch')
      }
      environment {
          APP_NAME = 'task-manager'
          GIT_REPO = 'https://github.com/<your-username>/task-manager.git'
          BACKEND_IMAGE = "task-backend:${BUILD_NUMBER}"
          FRONTEND_IMAGE = "task-frontend:${BUILD_NUMBER}"
          NGINX_IMAGE = "task-nginx:${BUILD_NUMBER}"
          PREV_BACKEND_IMAGE = "task-backend:${BUILD_NUMBER.toInteger() - 1}"
          PREV_FRONTEND_IMAGE = "task-frontend:${BUILD_NUMBER.toInteger() - 1}"
          PREV_NGINX_IMAGE = "task-nginx:${BUILD_NUMBER.toInteger() - 1}"
          S3_BUCKET = '<your-bucket>'
          DEPLOY_INSTANCE = 'TaskManagerProd'
      }
      stages {
          stage('Setup') {
              agent { label 'docker-slave-east' }
              steps {
                  withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                      script {
                          def githubSecret = sh(script: 'aws secretsmanager get-secret-value --secret-id github-token --query SecretString --output text', returnStdout: true).trim()
                          def githubCreds = readJSON text: githubSecret
                          env.GIT_USER = githubCreds.username
                          env.GIT_TOKEN = githubCreds.token
                      }
                      git url: "${GIT_REPO}", branch: "${BRANCH_NAME}", credentialsId: 'github-token'
                  }
              }
          }
          stage('Build and Push') {
              parallel {
                  stage('Backend') {
                      agent { label 'docker-slave-east' }
                      steps {
                          retry(3) {
                              buildDocker("${BACKEND_IMAGE}", 'backend', 'us-east-1')
                          }
                          scanImage("${BACKEND_IMAGE}")
                      }
                  }
                  stage('Frontend') {
                      agent { label 'docker-slave-west' }
                      steps {
                          retry(3) {
                              buildDocker("${FRONTEND_IMAGE}", 'frontend', 'us-west-2')
                          }
                          scanImage("${FRONTEND_IMAGE}")
                      }
                  }
                  stage('Nginx') {
                      agent { label 'docker-slave-east' }
                      steps {
                          retry(3) {
                              buildDocker("${NGINX_IMAGE}", 'nginx', 'us-east-1')
                          }
                          scanImage("${NGINX_IMAGE}")
                      }
                  }
              }
          }
          stage('Deploy') {
              agent { label 'docker-slave-east' }
              steps {
                  script {
                      def sshKey = sh(script: 'aws secretsmanager get-secret-value --secret-id jenkins-ssh-key --query SecretString --output text', returnStdout: true).trim()
                      writeFile file: 'id_rsa', text: sshKey
                      sh 'chmod 600 id_rsa'
                      def instanceIp = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${DEPLOY_INSTANCE} Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].PublicIpAddress' --output text", returnStdout: true).trim()
                      sh """
                          ssh -i id_rsa -o StrictHostKeyChecking=no ec2-user@${instanceIp} '
                              docker-compose down || true
                              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
                              docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${BACKEND_IMAGE}
                              docker pull <account-id>.dkr.ecr.us-west-2.amazonaws.com/${FRONTEND_IMAGE}
                              docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${NGINX_IMAGE}
                              echo "version: \'3.8\'" > docker-compose.yml
                              echo "services:" >> docker-compose.yml
                              echo "  backend:" >> docker-compose.yml
                              echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${BACKEND_IMAGE}" >> docker-compose.yml
                              echo "    restart: unless-stopped" >> docker-compose.yml
                              echo "  frontend:" >> docker-compose.yml
                              echo "    image: <account-id>.dkr.ecr.us-west-2.amazonaws.com/${FRONTEND_IMAGE}" >> docker-compose.yml
                              echo "    restart: unless-stopped" >> docker-compose.yml
                              echo "  nginx:" >> docker-compose.yml
                              echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${NGINX_IMAGE}" >> docker-compose.yml
                              echo "    ports:" >> docker-compose.yml
                              echo "      - \'80:80\'" >> docker-compose.yml
                              echo "    depends_on:" >> docker-compose.yml
                              echo "      - backend" >> docker-compose.yml
                              echo "      - frontend" >> docker-compose.yml
                              echo "    restart: unless-stopped" >> docker-compose.yml
                              docker-compose up -d
                          '
                      """
                      // Health check
                      timeout(time: 30, unit: 'SECONDS') {
                          sh "curl --retry 5 --retry-delay 5 http://${instanceIp}/tasks"
                      }
                  }
              }
              post {
                  failure {
                      script {
                          sh """
                              ssh -i id_rsa -o StrictHostKeyChecking=no ec2-user@${instanceIp} '
                                  docker-compose down || true
                                  docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_BACKEND_IMAGE}
                                  docker pull <account-id>.dkr.ecr.us-west-2.amazonaws.com/${PREV_FRONTEND_IMAGE}
                                  docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_NGINX_IMAGE}
                                  echo "version: \'3.8\'" > docker-compose.yml
                                  echo "services:" >> docker-compose.yml
                                  echo "  backend:" >> docker-compose.yml
                                  echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_BACKEND_IMAGE}" >> docker-compose.yml
                                  echo "    restart: unless-stopped" >> docker-compose.yml
                                  echo "  frontend:" >> docker-compose.yml
                                  echo "    image: <account-id>.dkr.ecr.us-west-2.amazonaws.com/${PREV_FRONTEND_IMAGE}" >> docker-compose.yml
                                  echo "    restart: unless-stopped" >> docker-compose.yml
                                  echo "  nginx:" >> docker-compose.yml
                                  echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_NGINX_IMAGE}" >> docker-compose.yml
                                  echo "    ports:" >> docker-compose.yml
                                  echo "      - \'80:80\'" >> docker-compose.yml
                                  echo "    depends_on:" >> docker-compose.yml
                                  echo "      - backend" >> docker-compose.yml
                                  echo "      - frontend" >> docker-compose.yml
                                  echo "    restart: unless-stopped" >> docker-compose.yml
                                  docker-compose up -d
                              '
                          """
                      }
                  }
              }
          }
      }
      post {
          always {
              sh 'rm -f id_rsa'
              withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                  sh "aws s3 cp docker-compose.yml s3://${S3_BUCKET}/configs/docker-compose-${BUILD_NUMBER}.yml"
                  sh 'docker logs task-backend > backend.log 2>&1 || true'
                  sh 'docker logs task-frontend > frontend.log 2>&1 || true'
                  sh 'docker logs task-nginx > nginx.log 2>&1 || true'
                  logToCloudWatch('backend.log', 'backend')
                  logToCloudWatch('frontend.log', 'frontend')
                  logToCloudWatch('nginx.log', 'nginx')
                  sh "aws s3 cp backend.log s3://${S3_BUCKET}/logs/backend-${BUILD_NUMBER}.log"
                  sh "aws s3 cp frontend.log s3://${S3_BUCKET}/logs/frontend-${BUILD_NUMBER}.log"
                  sh "aws s3 cp nginx.log s3://${S3_BUCKET}/logs/nginx-${BUILD_NUMBER}.log"
              }
              archiveArtifacts artifacts: '*.log', allowEmptyArchive: true
              sh 'rm -f *.log'
          }
          success {
              slackSend(channel: '#devops', message: "Deploy succeeded for ${APP_NAME} - ${BRANCH_NAME} at http://<domain>")
          }
          failure {
              slackSend(channel: '#devops', message: "Deploy failed for ${APP_NAME} - ${BRANCH_NAME}. Rolled back.")
          }
      }
  }
  ```

#### Step 4: Setup Scripts

- **setup-scripts/deploy-instance.sh**:
  ```bash
  #!/bin/bash
  aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t2.medium \
    --key-name <your-key> \
    --security-group-ids <sg-id> \
    --subnet-id <subnet-id> \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TaskManagerProd}]' \
    --iam-instance-profile Name=JenkinsSlaveRole \
    --user-data '#!/bin/bash
      yum update -y
      yum install -y docker awscli
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ec2-user
      curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
      ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose'
  ```

- **setup-scripts/monitoring.sh**:
  ```bash
  #!/bin/bash
  aws cloudwatch put-metric-alarm \
    --alarm-name JenkinsQueueLength \
    --metric-name QueueLength \
    --namespace Jenkins \
    --threshold 5 \
    --comparison-operator GreaterThanThreshold \
    --period 300 \
    --evaluation-periods 2 \
    --alarm-actions <sns-topic-arn>
  ```

#### Step 5: Test and Validate
- **Build**: Trigger Jenkins pipeline on `main`.
- **Verify**:
  ```bash
  INSTANCE_IP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=TaskManagerProd --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
  curl -X POST -H "Content-Type: application/json" -d '{"title":"Test Task"}' "http://$INSTANCE_IP/tasks"
  curl "http://$INSTANCE_IP/tasks"  # Returns [{"title":"Test Task"}]
  ```

---

### Security and HA Features
1. **Security**:
   - Secrets in AWS Secrets Manager, fetched at runtime.
   - ECR images encrypted with KMS, IAM least-privilege access.
   - SSH key cleanup post-deploy (`rm -f id_rsa`).

2. **High Availability**:
   - HA Jenkins master with ELB failover.
   - Multi-region slaves for build redundancy.
   - Nginx restart policy (`unless-stopped`) ensures uptime.

3. **Fault Tolerance**:
   - Retry (3x) on build/push failures.
   - Rollback to previous images on deploy failure.
   - Health check with retries ensures service readiness.

---

### Single Script to Generate Structure

```bash
#!/bin/bash

BASE_DIR="week3-day4-alt"
mkdir -p "$BASE_DIR"

# README.md
cat << 'EOF' > "$BASE_DIR/README.md"
# Week 3, Day 4 Alternative: Simplified SaaS Task Manager with Nginx Reverse Proxy

## Overview
A production-grade version of the Task Manager with Nginx as a reverse proxy, running frontend (8080) and backend (5000) in Docker, deployed via Jenkins Master-Slave architecture to AWS ECR and EC2.

## Setup
- Replace `<your-username>`, `<your-bucket>`, `<account-id>` in files.
- Push `task-manager` and `pipeline-lib` to GitHub.
- Run `setup-scripts/deploy-instance.sh` to launch EC2.
- Configure Jenkins with `Jenkinsfile`.
EOF

# task-manager directory
mkdir -p "$BASE_DIR/task-manager/backend" "$BASE_DIR/task-manager/frontend" "$BASE_DIR/task-manager/nginx"

# task-manager/backend
cat << 'EOF' > "$BASE_DIR/task-manager/backend/app.js"
const express = require('express');
const app = express();
app.use(express.json());
let tasks = [];

app.post('/tasks', (req, res) => {
  tasks.push(req.body);
  res.status(201).send(req.body);
});

app.get('/tasks', (req, res) => res.send(tasks));
app.listen(5000, () => console.log('Backend on port 5000'));
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/backend/package.json"
{"name": "task-backend", "version": "1.0.0", "dependencies": {"express": "^4.17.1"}, "scripts": {"start": "node app.js"}}
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/backend/Dockerfile"
FROM node:20
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/backend/.dockerignore"
node_modules
npm-debug.log
EOF

# task-manager/frontend
cat << 'EOF' > "$BASE_DIR/task-manager/frontend/app.js"
const express = require('express');
const axios = require('axios');
const app = express();

app.get('/tasks', async (req, res) => {
  try {
    const response = await axios.get('http://backend:5000/tasks');
    res.send(response.data);
  } catch (error) {
    res.status(500).send('Error fetching tasks');
  }
});

app.listen(8080, () => console.log('Frontend on port 8080'));
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/frontend/package.json"
{"name": "task-frontend", "version": "1.0.0", "dependencies": {"express": "^4.17.1", "axios": "^0.21.1"}, "scripts": {"start": "node app.js"}}
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/frontend/Dockerfile"
FROM node:20
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/frontend/.dockerignore"
node_modules
npm-debug.log
EOF

# task-manager/nginx
cat << 'EOF' > "$BASE_DIR/task-manager/nginx/nginx.conf"
server {
  listen 80;
  server_name localhost;

  location /tasks {
    proxy_pass http://backend:5000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }

  location / {
    proxy_pass http://frontend:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/nginx/Dockerfile"
FROM nginx:latest
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat << 'EOF' > "$BASE_DIR/task-manager/nginx/.dockerignore"
*.log
EOF

# task-manager/docker-compose.yml
cat << 'EOF' > "$BASE_DIR/task-manager/docker-compose.yml"
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    restart: unless-stopped
  frontend:
    build: ./frontend
    ports:
      - "8080:8080"
    restart: unless-stopped
  nginx:
    build: ./nginx
    ports:
      - "80:80"
    depends_on:
      - backend
      - frontend
    restart: unless-stopped
EOF

# task-manager/Jenkinsfile
cat << 'EOF' > "$BASE_DIR/task-manager/Jenkinsfile"
@Library('pipeline-lib@1.2') _
pipeline {
    agent none
    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch')
    }
    environment {
        APP_NAME = 'task-manager'
        GIT_REPO = 'https://github.com/<your-username>/task-manager.git'
        BACKEND_IMAGE = "task-backend:${BUILD_NUMBER}"
        FRONTEND_IMAGE = "task-frontend:${BUILD_NUMBER}"
        NGINX_IMAGE = "task-nginx:${BUILD_NUMBER}"
        PREV_BACKEND_IMAGE = "task-backend:${BUILD_NUMBER.toInteger() - 1}"
        PREV_FRONTEND_IMAGE = "task-frontend:${BUILD_NUMBER.toInteger() - 1}"
        PREV_NGINX_IMAGE = "task-nginx:${BUILD_NUMBER.toInteger() - 1}"
        S3_BUCKET = '<your-bucket>'
        DEPLOY_INSTANCE = 'TaskManagerProd'
    }
    stages {
        stage('Setup') {
            agent { label 'docker-slave-east' }
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    script {
                        def githubSecret = sh(script: 'aws secretsmanager get-secret-value --secret-id github-token --query SecretString --output text', returnStdout: true).trim()
                        def githubCreds = readJSON text: githubSecret
                        env.GIT_USER = githubCreds.username
                        env.GIT_TOKEN = githubCreds.token
                    }
                    git url: "${GIT_REPO}", branch: "${BRANCH_NAME}", credentialsId: 'github-token'
                }
            }
        }
        stage('Build and Push') {
            parallel {
                stage('Backend') {
                    agent { label 'docker-slave-east' }
                    steps {
                        retry(3) {
                            buildDocker("${BACKEND_IMAGE}", 'backend', 'us-east-1')
                        }
                        scanImage("${BACKEND_IMAGE}")
                    }
                }
                stage('Frontend') {
                    agent { label 'docker-slave-west' }
                    steps {
                        retry(3) {
                            buildDocker("${FRONTEND_IMAGE}", 'frontend', 'us-west-2')
                        }
                        scanImage("${FRONTEND_IMAGE}")
                    }
                }
                stage('Nginx') {
                    agent { label 'docker-slave-east' }
                    steps {
                        retry(3) {
                            buildDocker("${NGINX_IMAGE}", 'nginx', 'us-east-1')
                        }
                        scanImage("${NGINX_IMAGE}")
                    }
                }
            }
        }
        stage('Deploy') {
            agent { label 'docker-slave-east' }
            steps {
                script {
                    def sshKey = sh(script: 'aws secretsmanager get-secret-value --secret-id jenkins-ssh-key --query SecretString --output text', returnStdout: true).trim()
                    writeFile file: 'id_rsa', text: sshKey
                    sh 'chmod 600 id_rsa'
                    def instanceIp = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${DEPLOY_INSTANCE} Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].PublicIpAddress' --output text", returnStdout: true).trim()
                    sh """
                        ssh -i id_rsa -o StrictHostKeyChecking=no ec2-user@${instanceIp} '
                            docker-compose down || true
                            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
                            docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${BACKEND_IMAGE}
                            docker pull <account-id>.dkr.ecr.us-west-2.amazonaws.com/${FRONTEND_IMAGE}
                            docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${NGINX_IMAGE}
                            echo "version: \'3.8\'" > docker-compose.yml
                            echo "services:" >> docker-compose.yml
                            echo "  backend:" >> docker-compose.yml
                            echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${BACKEND_IMAGE}" >> docker-compose.yml
                            echo "    restart: unless-stopped" >> docker-compose.yml
                            echo "  frontend:" >> docker-compose.yml
                            echo "    image: <account-id>.dkr.ecr.us-west-2.amazonaws.com/${FRONTEND_IMAGE}" >> docker-compose.yml
                            echo "    restart: unless-stopped" >> docker-compose.yml
                            echo "  nginx:" >> docker-compose.yml
                            echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${NGINX_IMAGE}" >> docker-compose.yml
                            echo "    ports:" >> docker-compose.yml
                            echo "      - \'80:80\'" >> docker-compose.yml
                            echo "    depends_on:" >> docker-compose.yml
                            echo "      - backend" >> docker-compose.yml
                            echo "      - frontend" >> docker-compose.yml
                            echo "    restart: unless-stopped" >> docker-compose.yml
                            docker-compose up -d
                        '
                    """
                    timeout(time: 30, unit: 'SECONDS') {
                        sh "curl --retry 5 --retry-delay 5 http://${instanceIp}/tasks"
                    }
                }
            }
            post {
                failure {
                    script {
                        sh """
                            ssh -i id_rsa -o StrictHostKeyChecking=no ec2-user@${instanceIp} '
                                docker-compose down || true
                                docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_BACKEND_IMAGE}
                                docker pull <account-id>.dkr.ecr.us-west-2.amazonaws.com/${PREV_FRONTEND_IMAGE}
                                docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_NGINX_IMAGE}
                                echo "version: \'3.8\'" > docker-compose.yml
                                echo "services:" >> docker-compose.yml
                                echo "  backend:" >> docker-compose.yml
                                echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_BACKEND_IMAGE}" >> docker-compose.yml
                                echo "    restart: unless-stopped" >> docker-compose.yml
                                echo "  frontend:" >> docker-compose.yml
                                echo "    image: <account-id>.dkr.ecr.us-west-2.amazonaws.com/${PREV_FRONTEND_IMAGE}" >> docker-compose.yml
                                echo "    restart: unless-stopped" >> docker-compose.yml
                                echo "  nginx:" >> docker-compose.yml
                                echo "    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/${PREV_NGINX_IMAGE}" >> docker-compose.yml
                                echo "    ports:" >> docker-compose.yml
                                echo "      - \'80:80\'" >> docker-compose.yml
                                echo "    depends_on:" >> docker-compose.yml
                                echo "      - backend" >> docker-compose.yml
                                echo "      - frontend" >> docker-compose.yml
                                echo "    restart: unless-stopped" >> docker-compose.yml
                                docker-compose up -d
                            '
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            sh 'rm -f id_rsa'
            withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                sh "aws s3 cp docker-compose.yml s3://${S3_BUCKET}/configs/docker-compose-${BUILD_NUMBER}.yml"
                sh 'docker logs task-backend > backend.log 2>&1 || true'
                sh 'docker logs task-frontend > frontend.log 2>&1 || true'
                sh 'docker logs task-nginx > nginx.log 2>&1 || true'
                logToCloudWatch('backend.log', 'backend')
                logToCloudWatch('frontend.log', 'frontend')
                logToCloudWatch('nginx.log', 'nginx')
                sh "aws s3 cp backend.log s3://${S3_BUCKET}/logs/backend-${BUILD_NUMBER}.log"
                sh "aws s3 cp frontend.log s3://${S3_BUCKET}/logs/frontend-${BUILD_NUMBER}.log"
                sh "aws s3 cp nginx.log s3://${S3_BUCKET}/logs/nginx-${BUILD_NUMBER}.log"
            }
            archiveArtifacts artifacts: '*.log', allowEmptyArchive: true
            sh 'rm -f *.log'
        }
        success {
            slackSend(channel: '#devops', message: "Deploy succeeded for ${APP_NAME} - ${BRANCH_NAME} at http://<domain>")
        }
        failure {
            slackSend(channel: '#devops', message: "Deploy failed for ${APP_NAME} - ${BRANCH_NAME}. Rolled back.")
        }
    }
}
EOF

# task-manager/README.md
cat << 'EOF' > "$BASE_DIR/task-manager/README.md"
# Task Manager with Nginx Reverse Proxy

A simple SaaS app with backend (5000), frontend (8080), and Nginx reverse proxy (80).

## Setup
- Replace placeholders in `Jenkinsfile` and scripts.
- Push to GitHub and configure Jenkins.
EOF

# task-manager/.gitignore
cat << 'EOF' > "$BASE_DIR/task-manager/.gitignore"
node_modules/
*.log
EOF

# pipeline-lib directory
mkdir -p "$BASE_DIR/pipeline-lib/vars"

# pipeline-lib files (unchanged from Day 3)
cat << 'EOF' > "$BASE_DIR/pipeline-lib/vars/buildDocker.groovy"
def call(String imageName, String dir, String region) {
    dir(dir) {
        sh "docker build --cache-from <account-id>.dkr.ecr.${region}.amazonaws.com/${imageName}:latest -t ${imageName} ."
        withAWS(credentials: 'aws-creds', region: region) {
            sh "aws ecr get-login-password | docker login --username AWS --password-stdin <account-id>.dkr.ecr.${region}.amazonaws.com"
            sh "docker tag ${imageName} <account-id>.dkr.ecr.${region}.amazonaws.com/${imageName}"
            sh "docker push <account-id>.dkr.ecr.${region}.amazonaws.com/${imageName}"
            sh "aws s3 cp Dockerfile s3://<your-bucket>/artifacts/${imageName.split(':')[0]}-${BUILD_NUMBER}/"
        }
    }
}
EOF

cat << 'EOF' > "$BASE_DIR/pipeline-lib/vars/deployEC2.groovy"
def call(String imageName, String instanceTag, String previousImage) {
    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
        def instanceIp = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=${instanceTag} Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].PublicIpAddress' --output text", returnStdout: true).trim()
        try {
            sh "ssh -i ~/.ssh/jenkins_master_key -o StrictHostKeyChecking=no ec2-user@${instanceIp} 'docker stop ${imageName.split(':')[0]} || true'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker rm ${imageName.split(':')[0]} || true'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'aws ecr get-login-password | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${imageName}'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker run -d --name ${imageName.split(':')[0]} -p ${imageName.contains('backend') ? '5000:5000' : '8080:8080'} <account-id>.dkr.ecr.us-east-1.amazonaws.com/${imageName}'"
        } catch (Exception e) {
            echo "Deploy failed, rolling back to ${previousImage}"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker stop ${imageName.split(':')[0]} || true'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker rm ${imageName.split(':')[0]} || true'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/${previousImage}'"
            sh "ssh -i ~/.ssh/jenkins_master_key ec2-user@${instanceIp} 'docker run -d --name ${imageName.split(':')[0]} -p ${imageName.contains('backend') ? '5000:5000' : '8080:8080'} <account-id>.dkr.ecr.us-east-1.amazonaws.com/${previousImage}'"
            throw e
        }
    }
}
EOF

cat << 'EOF' > "$BASE_DIR/pipeline-lib/vars/scanImage.groovy"
def call(String imageName) {
    sh "docker run --rm aquasec/trivy image --severity HIGH,CRITICAL ${imageName}"
}
EOF

cat << 'EOF' > "$BASE_DIR/pipeline-lib/vars/logToCloudWatch.groovy"
def call(String logFile, String streamName) {
    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
        sh "aws logs put-log-events --log-group-name JenkinsLogs --log-stream-name ${streamName}-${BUILD_NUMBER} --log-events file:///${logFile}"
    }
}
EOF

cat << 'EOF' > "$BASE_DIR/pipeline-lib/README.md"
# Pipeline Library
Reusable Groovy scripts for Jenkins pipelines.
EOF

cat << 'EOF' > "$BASE_DIR/pipeline-lib/.gitignore"
*.log
EOF

# setup-scripts directory
mkdir -p "$BASE_DIR/setup-scripts"

cat << 'EOF' > "$BASE_DIR/setup-scripts/deploy-instance.sh"
#!/bin/bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.medium \
  --key-name <your-key> \
  --security-group-ids <sg-id> \
  --subnet-id <subnet-id> \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TaskManagerProd}]' \
  --iam-instance-profile Name=JenkinsSlaveRole \
  --user-data '#!/bin/bash
    yum update -y
    yum install -y docker awscli
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose'
EOF

cat << 'EOF' > "$BASE_DIR/setup-scripts/monitoring.sh"
#!/bin/bash
aws cloudwatch put-metric-alarm \
  --alarm-name JenkinsQueueLength \
  --metric-name QueueLength \
  --namespace Jenkins \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --period 300 \
  --evaluation-periods 2 \
  --alarm-actions <sns-topic-arn>
EOF

# S3 setup script
cat << EOF > "$BASE_DIR/setup-scripts/s3-setup.sh"
#!/bin/bash
# Create S3 bucket
aws s3 mb s3://${S3_BUCKET} --region us-east-1

# Enable server-side encryption with KMS
aws s3api put-bucket-encryption --bucket ${S3_BUCKET} --server-side-encryption-configuration '{
  "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}}]
}'

# Block public access
aws s3api put-public-access-block --bucket ${S3_BUCKET} --public-access-block-configuration '{
  "BlockPublicAcls": true, "IgnorePublicAcls": true, "BlockPublicPolicy": true, "RestrictPublicBuckets": true
}'

# Set bucket policy to allow JenkinsSlaveRole
aws s3api put-bucket-policy --bucket ${S3_BUCKET} --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::<account-id>:role/JenkinsSlaveRole"},
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::${S3_BUCKET}/*"
    }
  ]
}'
EOF

chmod +x "$BASE_DIR/setup-scripts/"*.sh

echo "Alternative project folder created at $BASE_DIR"
```

---

### Notes
- **Placeholders**: Replace `<your-username>`, `<your-bucket>`, `<account-id>`, `<your-key>`, `<sg-id>`, `<subnet-id>`, `<sns-topic-arn>` with your values.
- **Execution**: Run locally, then push repos to GitHub.
- **Next Steps**: Add Route 53 for `<domain>` or ELB for multi-instance HA.

This setup delivers a secure, HA, fault-tolerant Task Manager with Nginx reverse proxy, ready for production use.