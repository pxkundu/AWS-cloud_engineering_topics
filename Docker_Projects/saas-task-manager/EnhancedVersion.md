Let’s simplify the **Week 3, Day 4 Alternative: Simplified SaaS Task Manager with Nginx Reverse Proxy** by streamlining the deployment pipeline into a single `Jenkinsfile` and managing server-side configuration directly via a `docker-compose.yml` file. 

This version eliminates the need for separate setup scripts and external pipeline library dependencies, focusing on a minimal, production-grade setup using the existing Jenkins Master-Slave architecture, AWS ECR, S3, and Docker Compose on an EC2 instance. 

The S3 bucket configuration is included inline for simplicity, and security/high availability/fault tolerance are maintained as of March 11, 2025.

---

### Simplified Project Overview

#### Objectives
- Deploy **frontend** (port 8080) and **backend** (port 5000) behind an **Nginx reverse proxy** (port 80) using Docker Compose.
- Build and push Docker images to **AWS ECR** directly in the `Jenkinsfile`.
- Use a single `Jenkinsfile` for the entire pipeline (build, push, deploy).
- Configure server-side setup with a `docker-compose.yml` file, uploaded to S3 and applied on EC2.
- Integrate an S3 bucket for logs and configs with simplified setup.

#### Tools
- Jenkins (HA Master + Multi-Region Slaves), Docker, Nginx, AWS ECR, AWS S3, AWS Secrets Manager, GitHub.

#### Assumptions
- HA Jenkins master (us-east-1) and slaves (us-east-1, us-west-2) are operational.
- ECR repos (`task-backend`, `task-frontend`, `task-nginx`) and S3 bucket (`<your-bucket>`) will be created if not present.
- IAM role `JenkinsSlaveRole` has ECR/S3/Secrets Manager permissions.

---

### Simplified Project Structure
```
week3-day4-simple/
├── README.md
├── backend/
│   ├── app.js
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
├── frontend/
│   ├── app.js
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
├── nginx/
│   ├── nginx.conf
│   ├── Dockerfile
│   └── .dockerignore
├── docker-compose.yml
├── Jenkinsfile
└── .gitignore
```

---

### Single Script to Generate Simplified Structure

Below is a simplified Bash script (`setup_week3_day4_simple.sh`) that creates the project folder, populates files with code, and includes S3 bucket setup directly in the `Jenkinsfile`. This script assumes you replace placeholders before running.

```bash
#!/bin/bash

# Script to create simplified Week 3, Day 4 project folder with single Jenkinsfile and Docker Compose

BASE_DIR="week3-day4-simple"
S3_BUCKET="<your-bucket>"  # Replace with your bucket name (e.g., task-manager-prod-2025)
mkdir -p "$BASE_DIR"

# README.md
cat << 'EOF' > "$BASE_DIR/README.md"
# Week 3, Day 4 Simplified: SaaS Task Manager with Nginx Reverse Proxy

## Overview
A simplified, production-grade Task Manager with Nginx reverse proxy, deployed via a single Jenkinsfile and Docker Compose. Uses AWS ECR for images and S3 for logs/configs.

## Setup
- Replace `<your-username>`, `<your-bucket>`, `<account-id>` in `Jenkinsfile`.
- Push to GitHub and configure Jenkins with `Jenkinsfile`.
- Ensure EC2 instance `TaskManagerProd` is running with Docker and Docker Compose installed.
EOF

# backend directory
mkdir -p "$BASE_DIR/backend"

cat << 'EOF' > "$BASE_DIR/backend/app.js"
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

cat << 'EOF' > "$BASE_DIR/backend/package.json"
{"name": "task-backend", "version": "1.0.0", "dependencies": {"express": "^4.17.1"}, "scripts": {"start": "node app.js"}}
EOF

cat << 'EOF' > "$BASE_DIR/backend/Dockerfile"
FROM node:20
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
EOF

cat << 'EOF' > "$BASE_DIR/backend/.dockerignore"
node_modules
npm-debug.log
EOF

# frontend directory
mkdir -p "$BASE_DIR/frontend"

cat << 'EOF' > "$BASE_DIR/frontend/app.js"
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

cat << 'EOF' > "$BASE_DIR/frontend/package.json"
{"name": "task-frontend", "version": "1.0.0", "dependencies": {"express": "^4.17.1", "axios": "^0.21.1"}, "scripts": {"start": "node app.js"}}
EOF

cat << 'EOF' > "$BASE_DIR/frontend/Dockerfile"
FROM node:20
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
EOF

cat << 'EOF' > "$BASE_DIR/frontend/.dockerignore"
node_modules
npm-debug.log
EOF

# nginx directory
mkdir -p "$BASE_DIR/nginx"

cat << 'EOF' > "$BASE_DIR/nginx/nginx.conf"
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

cat << 'EOF' > "$BASE_DIR/nginx/Dockerfile"
FROM nginx:latest
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat << 'EOF' > "$BASE_DIR/nginx/.dockerignore"
*.log
EOF

# docker-compose.yml
cat << 'EOF' > "$BASE_DIR/docker-compose.yml"
version: '3.8'
services:
  backend:
    image: "<account-id>.dkr.ecr.us-east-1.amazonaws.com/task-backend:<BUILD_NUMBER>"
    restart: unless-stopped
  frontend:
    image: "<account-id>.dkr.ecr.us-west-2.amazonaws.com/task-frontend:<BUILD_NUMBER>"
    restart: unless-stopped
  nginx:
    image: "<account-id>.dkr.ecr.us-east-1.amazonaws.com/task-nginx:<BUILD_NUMBER>"
    ports:
      - "80:80"
    depends_on:
      - backend
      - frontend
    restart: unless-stopped
EOF

# Jenkinsfile
cat << EOF > "$BASE_DIR/Jenkinsfile"
pipeline {
    agent none
    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch')
    }
    environment {
        APP_NAME = 'task-manager'
        GIT_REPO = 'https://github.com/<your-username>/task-manager.git'
        S3_BUCKET = '${S3_BUCKET}'
        DEPLOY_INSTANCE = 'TaskManagerProd'
        AWS_REGION = 'us-east-1'
    }
    stages {
        stage('Setup S3 Bucket') {
            agent { label 'docker-slave-east' }
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    sh """
                        aws s3 mb s3://\${S3_BUCKET} --region \${AWS_REGION} || echo "Bucket already exists"
                        aws s3api put-bucket-encryption --bucket \${S3_BUCKET} --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}}]}'
                        aws s3api put-public-access-block --bucket \${S3_BUCKET} --public-access-block-configuration '{"BlockPublicAcls": true, "IgnorePublicAcls": true, "BlockPublicPolicy": true, "RestrictPublicBuckets": true}'
                        aws s3api put-bucket-policy --bucket \${S3_BUCKET} --policy '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::<account-id>:role/JenkinsSlaveRole"}, "Action": ["s3:PutObject", "s3:GetObject"], "Resource": "arn:aws:s3:::\${S3_BUCKET}/*"}]}'
                    """
                }
            }
        }
        stage('Checkout and Build') {
            parallel {
                stage('Backend') {
                    agent { label 'docker-slave-east' }
                    steps {
                        withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                            script {
                                def githubSecret = sh(script: 'aws secretsmanager get-secret-value --secret-id github-token --query SecretString --output text', returnStdout: true).trim()
                                def githubCreds = readJSON text: githubSecret
                                env.GIT_USER = githubCreds.username
                                env.GIT_TOKEN = githubCreds.token
                            }
                            git url: "\${GIT_REPO}", branch: "\${BRANCH_NAME}", credentialsId: 'github-token'
                            sh "docker build -t task-backend:\${BUILD_NUMBER} backend/"
                            sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com"
                            sh "docker tag task-backend:\${BUILD_NUMBER} <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-backend:\${BUILD_NUMBER}"
                            retry(3) {
                                sh "docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-backend:\${BUILD_NUMBER}"
                            }
                        }
                    }
                }
                stage('Frontend') {
                    agent { label 'docker-slave-west' }
                    steps {
                        withAWS(credentials: 'aws-creds', region: 'us-west-2') {
                            git url: "\${GIT_REPO}", branch: "\${BRANCH_NAME}", credentialsId: 'github-token'
                            sh "docker build -t task-frontend:\${BUILD_NUMBER} frontend/"
                            sh "aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com"
                            sh "docker tag task-frontend:\${BUILD_NUMBER} <account-id>.dkr.ecr.us-west-2.amazonaws.com/task-frontend:\${BUILD_NUMBER}"
                            retry(3) {
                                sh "docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/task-frontend:\${BUILD_NUMBER}"
                            }
                        }
                    }
                }
                stage('Nginx') {
                    agent { label 'docker-slave-east' }
                    steps {
                        withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                            git url: "\${GIT_REPO}", branch: "\${BRANCH_NAME}", credentialsId: 'github-token'
                            sh "docker build -t task-nginx:\${BUILD_NUMBER} nginx/"
                            sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com"
                            sh "docker tag task-nginx:\${BUILD_NUMBER} <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-nginx:\${BUILD_NUMBER}"
                            retry(3) {
                                sh "docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-nginx:\${BUILD_NUMBER}"
                            }
                        }
                    }
                }
            }
        }
        stage('Deploy') {
            agent { label 'docker-slave-east' }
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    script {
                        def sshKey = sh(script: 'aws secretsmanager get-secret-value --secret-id jenkins-ssh-key --query SecretString --output text', returnStdout: true).trim()
                        writeFile file: 'id_rsa', text: sshKey
                        sh 'chmod 600 id_rsa'
                        def instanceIp = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=\${DEPLOY_INSTANCE} Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].PublicIpAddress' --output text", returnStdout: true).trim()
                        sh "sed -i 's/<BUILD_NUMBER>/\${BUILD_NUMBER}/g' docker-compose.yml"
                        sh """
                            ssh -i id_rsa -o StrictHostKeyChecking=no ec2-user@\${instanceIp} '
                                docker-compose down || true
                                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
                                aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
                            '
                            scp -i id_rsa docker-compose.yml ec2-user@\${instanceIp}:/home/ec2-user/docker-compose.yml
                            ssh -i id_rsa ec2-user@\${instanceIp} '
                                docker-compose up -d
                            '
                            aws s3 cp docker-compose.yml s3://\${S3_BUCKET}/configs/docker-compose-\${BUILD_NUMBER}.yml --sse aws:kms
                        """
                        timeout(time: 30, unit: 'SECONDS') {
                            sh "curl --retry 5 --retry-delay 5 http://\${instanceIp}/tasks"
                        }
                    }
                }
            }
            post {
                failure {
                    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                        script {
                            def instanceIp = sh(script: "aws ec2 describe-instances --filters Name=tag:Name,Values=\${DEPLOY_INSTANCE} Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].PublicIpAddress' --output text", returnStdout: true).trim()
                            sh "sed -i 's/\${BUILD_NUMBER}/\${BUILD_NUMBER.toInteger() - 1}/g' docker-compose.yml"
                            sh """
                                ssh -i id_rsa ec2-user@\${instanceIp} '
                                    docker-compose down || true
                                '
                                scp -i id_rsa docker-compose.yml ec2-user@\${instanceIp}:/home/ec2-user/docker-compose.yml
                                ssh -i id_rsa ec2-user@\${instanceIp} '
                                    docker-compose up -d
                                '
                                aws s3 cp docker-compose.yml s3://\${S3_BUCKET}/configs/docker-compose-\${BUILD_NUMBER}-rollback.yml --sse aws:kms
                            """
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                sh 'docker logs task-backend > backend.log 2>&1 || true'
                sh 'docker logs task-frontend > frontend.log 2>&1 || true'
                sh 'docker logs task-nginx > nginx.log 2>&1 || true'
                sh "aws s3 cp backend.log s3://\${S3_BUCKET}/logs/backend-\${BUILD_NUMBER}.log --sse aws:kms || true"
                sh "aws s3 cp frontend.log s3://\${S3_BUCKET}/logs/frontend-\${BUILD_NUMBER}.log --sse aws:kms || true"
                sh "aws s3 cp nginx.log s3://\${S3_BUCKET}/logs/nginx-\${BUILD_NUMBER}.log --sse aws:kms || true"
            }
            sh 'rm -f id_rsa *.log'
        }
        success {
            echo "Deploy succeeded for \${APP_NAME} - \${BRANCH_NAME}"
        }
        failure {
            echo "Deploy failed for \${APP_NAME} - \${BRANCH_NAME}. Rolled back."
        }
    }
}
EOF

# .gitignore
cat << 'EOF' > "$BASE_DIR/.gitignore"
node_modules/
*.log
id_rsa
EOF

echo "Simplified Week 3, Day 4 project folder created at $BASE_DIR"
```

---

### Key Simplifications
1. **Single Jenkinsfile**:
   - Combines S3 setup, build, push, and deploy stages.
   - Removes dependency on `pipeline-lib` by embedding build/push logic.
   - Uses parallel stages for backend, frontend, and Nginx builds.

2. **Docker Compose for Server-Side Config**:
   - `docker-compose.yml` defines all services with ECR image placeholders (`<BUILD_NUMBER>`).
   - Jenkins updates the file with the build number and uploads it to S3/EC2.

3. **S3 Configuration**:
   - Inline in `Jenkinsfile` under `Setup S3 Bucket` stage.
   - Creates bucket, enables SSE-KMS, blocks public access, and sets policy for `JenkinsSlaveRole`.

4. **Security/HA/Fault Tolerance**:
   - **Security**: Secrets from AWS Secrets Manager, S3 encryption, IAM role access.
   - **HA**: Multi-region slaves (us-east-1, us-west-2), S3 durability.
   - **Fault Tolerance**: Retry (3x) on ECR push, rollback on deploy failure, health check with retries.

---

### Execution Steps
1. **Replace Placeholders**: Update `<your-username>`, `<your-bucket>`, `<account-id>` in `Jenkinsfile` and `docker-compose.yml`.
2. **Run Script**: `chmod +x setup_week3_day4_simple.sh && ./setup_week3_day4_simple.sh`.
3. **Push to GitHub**: Push `week3-day4-simple` to a GitHub repo.
4. **EC2 Setup**: Ensure `TaskManagerProd` EC2 instance has Docker and Docker Compose installed (e.g., via Day 3 user data).
5. **Jenkins Config**: Add the `Jenkinsfile` to a multi-branch pipeline and trigger a build.

---

### Validation
```bash
INSTANCE_IP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=TaskManagerProd --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
curl -X POST -H "Content-Type: application/json" -d '{"title":"Simple Task"}' "http://$INSTANCE_IP/tasks"
curl "http://$INSTANCE_IP/tasks"  # Returns [{"title":"Simple Task"}]
aws s3 ls s3://<your-bucket>/logs/  # Lists backend-<BUILD_NUMBER>.log, etc.
```

---

### Notes
- **EC2 Pre-requisite**: The `TaskManagerProd` instance must have Docker and Docker Compose installed (e.g., via `yum install docker` and `curl -L ...` for Docker Compose).
- **Limitations**: No external pipeline library or separate setup scripts; assumes manual EC2 setup.
- **Enhancements**: Add Route 53 for a domain or ELB for multi-instance HA if needed.

