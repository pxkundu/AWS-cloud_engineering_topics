Let’s create a simple **Node.js CRUD API** with a **ReactJS frontend**, deploy it on **Kubernetes** using **Amazon EKS**, and set up a **Jenkins CI/CD pipeline** on AWS. 

This implementation is tailored for an intermediate-level DevOps engineer, keeping it clean, optimized, and educational with clear steps, best practices, and real-world relevance as of March 07, 2025. 

We’ll use a basic "To-Do List" app as the use case, aligning with DevOps principles like automation, scalability, and observability.

---

### Project Overview: To-Do List CRUD App
- **Objective**: Build a CRUD (Create, Read, Update, Delete) app for managing to-do items, deployed on EKS with Jenkins CI/CD.
- **Components**:
  - **Backend**: Node.js API with in-memory storage (for simplicity).
  - **Frontend**: ReactJS app for user interaction.
  - **Deployment**: Kubernetes on AWS EKS.
  - **CI/CD**: Jenkins on an EC2 instance.
- **Tools**: Node.js, ReactJS, Docker, AWS CLI, `eksctl`, `kubectl`, Jenkins, Git.

---

### Project Structure
Here’s the clean, modular structure optimized for learning:

```
todo-app/
├── backend/                   # Node.js CRUD API
│   ├── src/
│   │   ├── index.js          # API logic
│   │   └── todos.js          # In-memory store
│   ├── Dockerfile            # Docker config
│   ├── package.json          # Dependencies
│   └── .dockerignore         # Ignore files
├── frontend/                  # ReactJS frontend
│   ├── src/
│   │   ├── App.js           # Main component
│   │   ├── index.js         # Entry point
│   │   └── TodoList.js      # CRUD UI
│   ├── public/
│   │   └── index.html       # HTML template
│   ├── Dockerfile            # Docker config
│   ├── package.json          # Dependencies
│   ├── nginx.conf            # Nginx config
│   └── .dockerignore         # Ignore files
├── k8s/                       # Kubernetes manifests
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml          # ALB Ingress
├── jenkins/                   # Jenkins CI/CD
│   ├── Dockerfile            # Jenkins image
│   ├── Jenkinsfile           # Pipeline script
│   └── ec2-user-data.sh      # EC2 setup script
├── .gitignore                # Git ignore
└── README.md                 # Project docs
```

---

### Step-by-Step Implementation

#### Step 1: Set Up Development Environment
- **Goal**: Install tools and scaffold the project.
- **Commands**:
  ```bash
  # Install AWS CLI
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  aws --version

  # Install eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin
  eksctl version

  # Install kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client

  # Install Docker
  sudo yum install docker -y
  sudo systemctl start docker
  sudo usermod -aG docker ec2-user
  docker --version

  # Install Node.js
  curl -sL https://rpm.nodesource.com/setup_20.x | sudo bash -
  sudo yum install -y nodejs
  node -v

  # Scaffold Project
  mkdir -p todo-app/{backend/src,frontend/src,frontend/public,k8s,jenkins}
  cd todo-app
  git init
  echo "node_modules/
  *.zip
  *.log" > .gitignore
  git remote add origin https://github.com/<your-username>/todo-app.git
  ```

---

#### Step 2: Build Node.js CRUD API
- **Goal**: Create a simple REST API for to-do items.
- **Implementation**:
  ```bash
  cd backend
  npm init -y
  npm install express uuid
  nano src/todos.js
  ```
  - **Content** (`src/todos.js`):
    ```javascript
    const { v4: uuidv4 } = require('uuid');

    let todos = [];

    const getTodos = () => todos;
    const getTodo = (id) => todos.find(todo => todo.id === id);
    const createTodo = (title) => {
      const todo = { id: uuidv4(), title, completed: false };
      todos.push(todo);
      return todo;
    };
    const updateTodo = (id, updates) => {
      const todo = todos.find(t => t.id === id);
      if (!todo) return null;
      Object.assign(todo, updates);
      return todo;
    };
    const deleteTodo = (id) => {
      const index = todos.findIndex(t => t.id === id);
      if (index === -1) return null;
      return todos.splice(index, 1)[0];
    };

    module.exports = { getTodos, getTodo, createTodo, updateTodo, deleteTodo };
    ```
  ```bash
  nano src/index.js
  ```
  - **Content** (`src/index.js`):
    ```javascript
    const express = require('express');
    const { getTodos, getTodo, createTodo, updateTodo, deleteTodo } = require('./todos');

    const app = express();
    const port = process.env.PORT || 3000;

    app.use(express.json());

    app.get('/api/todos', (req, res) => res.json(getTodos()));
    app.get('/api/todos/:id', (req, res) => {
      const todo = getTodo(req.params.id);
      res.json(todo || { error: 'Todo not found' });
    });
    app.post('/api/todos', (req, res) => {
      const todo = createTodo(req.body.title);
      res.status(201).json(todo);
    });
    app.put('/api/todos/:id', (req, res) => {
      const todo = updateTodo(req.params.id, req.body);
      res.json(todo || { error: 'Todo not found' });
    });
    app.delete('/api/todos/:id', (req, res) => {
      const todo = deleteTodo(req.params.id);
      res.json(todo || { error: 'Todo not found' });
    });

    app.listen(port, () => console.log(`API running on port ${port}`));
    ```
  ```bash
  nano Dockerfile
  ```
  - **Content** (`Dockerfile`):
    ```dockerfile
    FROM node:20-alpine
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci --production
    COPY src/ ./src/
    EXPOSE 3000
    CMD ["node", "src/index.js"]
    ```
  ```bash
  echo "node_modules
  *.log" > .dockerignore
  docker build -t todo-api .
  docker run -p 3000:3000 todo-api  # Test locally
  ```

---

#### Step 3: Build ReactJS Frontend
- **Goal**: Create a UI to interact with the API.
- **Implementation**:
  ```bash
  cd ../frontend
  npx create-react-app .
  npm install axios
  nano src/TodoList.js
  ```
  - **Content** (`src/TodoList.js`):
    ```javascript
    import React, { useState, useEffect } from 'react';
    import axios from 'axios';

    const TodoList = () => {
      const [todos, setTodos] = useState([]);
      const [title, setTitle] = useState('');

      useEffect(() => {
        axios.get('/api/todos').then(res => setTodos(res.data));
      }, []);

      const addTodo = () => {
        axios.post('/api/todos', { title }).then(res => setTodos([...todos, res.data]));
        setTitle('');
      };

      const toggleTodo = (id, completed) => {
        axios.put(`/api/todos/${id}`, { completed: !completed }).then(res => {
          setTodos(todos.map(t => (t.id === id ? res.data : t)));
        });
      };

      const deleteTodo = (id) => {
        axios.delete(`/api/todos/${id}`).then(() => {
          setTodos(todos.filter(t => t.id !== id));
        });
      };

      return (
        <div>
          <h1>To-Do List</h1>
          <input value={title} onChange={e => setTitle(e.target.value)} />
          <button onClick={addTodo}>Add</button>
          <ul>
            {todos.map(todo => (
              <li key={todo.id}>
                <input
                  type="checkbox"
                  checked={todo.completed}
                  onChange={() => toggleTodo(todo.id, todo.completed)}
                />
                {todo.title}
                <button onClick={() => deleteTodo(todo.id)}>Delete</button>
              </li>
            ))}
          </ul>
        </div>
      );
    };

    export default TodoList;
    ```
  ```bash
  nano src/App.js
  ```
  - **Content** (`src/App.js`):
    ```javascript
    import React from 'react';
    import TodoList from './TodoList';

    function App() {
      return (
        <div className="App">
          <TodoList />
        </div>
      );
    }

    export default App;
    ```
  ```bash
  nano Dockerfile
  ```
  - **Content** (`Dockerfile`):
    ```dockerfile
    FROM node:20-alpine AS builder
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci
    COPY . .
    RUN npm run build

    FROM nginx:alpine
    COPY --from=builder /app/build /usr/share/nginx/html
    COPY nginx.conf /etc/nginx/conf.d/default.conf
    EXPOSE 80
    CMD ["nginx", "-g", "daemon off;"]
    ```
  ```bash
  nano nginx.conf
  ```
  - **Content** (`nginx.conf`):
    ```nginx
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }
        location /api/ {
            proxy_pass http://backend-service:3000/;
            proxy_set_header Host $host;
        }
    }
    ```
  ```bash
  echo "node_modules
  build
  *.log" > .dockerignore
  docker build -t todo-frontend .
  docker run -p 80:80 todo-frontend  # Test locally
  ```

---

#### Step 4: Push Images to Amazon ECR
- **Goal**: Store images securely in AWS.
- **Commands**:
  ```bash
  aws ecr create-repository --repository-name todo-api --region us-east-1
  aws ecr create-repository --repository-name todo-frontend --region us-east-1
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
  docker tag todo-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/todo-api:latest
  docker tag todo-frontend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/todo-frontend:latest
  docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/todo-api:latest
  docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/todo-frontend:latest
  ```

---

#### Step 5: Create EKS Cluster
- **Goal**: Set up a lightweight EKS cluster for learning.
- **Commands**:
  ```bash
  eksctl create cluster \
    --name TodoCluster \
    --region us-east-1 \
    --nodegroup-name workers \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3 \
    --managed
  kubectl get nodes  # Verify
  ```

---

#### Step 6: Install AWS Load Balancer Controller
- **Goal**: Enable ALB for Ingress routing.
- **Commands**:
  ```bash
  eksctl utils associate-iam-oidc-provider --cluster TodoCluster --approve
  aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://<(curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json)
  eksctl create iamserviceaccount \
    --cluster TodoCluster \
    --namespace kube-system \
    --name aws-load-balancer-controller \
    --attach-policy-arn arn:aws:iam::<account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve
  helm repo add eks https://aws.github.io/eks-charts
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --namespace kube-system \
    --set clusterName=TodoCluster \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
  ```

---

#### Step 7: Deploy to Kubernetes
- **Goal**: Deploy backend and frontend with Kubernetes manifests.
- **Implementation**:
  ```bash
  cd k8s
  nano backend-deployment.yaml
  ```
  - **Content**:
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: backend
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: backend
      template:
        metadata:
          labels:
            app: backend
        spec:
          containers:
          - name: backend
            image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/todo-api:latest
            ports:
            - containerPort: 3000
            resources:
              limits:
                cpu: "250m"
                memory: "256Mi"
              requests:
                cpu: "100m"
                memory: "128Mi"
    ```
  ```bash
  nano backend-service.yaml
  ```
  - **Content**:
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: backend-service
    spec:
      selector:
        app: backend
      ports:
      - port: 3000
        targetPort: 3000
    ```
  ```bash
  nano frontend-deployment.yaml
  ```
  - **Content**:
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: frontend
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: frontend
      template:
        metadata:
          labels:
            app: frontend
        spec:
          containers:
          - name: frontend
            image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/todo-frontend:latest
            ports:
            - containerPort: 80
            resources:
              limits:
                cpu: "250m"
                memory: "256Mi"
              requests:
                cpu: "100m"
                memory: "128Mi"
    ```
  ```bash
  nano frontend-service.yaml
  ```
  - **Content**:
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: frontend-service
    spec:
      selector:
        app: frontend
      ports:
      - port: 80
        targetPort: 80
    ```
  ```bash
  nano ingress.yaml
  ```
  - **Content**:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: todo-ingress
      annotations:
        kubernetes.io/ingress.class: alb
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
    spec:
      rules:
      - http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 3000
    ```
  - **Deploy**:
    ```bash
    kubectl apply -f .
    kubectl get ingress todo-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'  # Get ALB URL
    ```

---

#### Step 8: Set Up Jenkins CI/CD
- **Goal**: Automate build and deployment with Jenkins.
- **Implementation**:
  1. **Launch Jenkins EC2**:
     ```bash
     cd ../jenkins
     nano ec2-user-data.sh
     ```
     - **Content**:
       ```bash
       #!/bin/bash
       yum update -y
       yum install -y docker
       systemctl start docker
       usermod -aG docker ec2-user
       curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
       chmod +x /usr/local/bin/docker-compose
       yum install -y java-11-openjdk
       wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
       rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
       yum install -y jenkins
       systemctl start jenkins
       systemctl enable jenkins
       ```
     - **Launch** (in AWS Console or CLI):
       ```bash
       aws ec2 run-instances \
         --image-id ami-0c55b159cbfafe1f0 \
         --instance-type t2.medium \
         --key-name <your-key> \
         --security-group-ids <sg-id> \
         --subnet-id <subnet-id> \
         --user-data file://ec2-user-data.sh \
         --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Jenkins}]'
       ```
     - Access Jenkins at `http://<ec2-public-ip>:8080`, get initial password: `ssh ec2-user@<ip> "cat /var/lib/jenkins/secrets/initialAdminPassword"`.

  2. **Configure Jenkins**:
     - Install plugins: Docker, AWS Credentials, Pipeline.
     - Add AWS credentials in Jenkins (ID: `aws-creds`).

  3. **Create Jenkinsfile**:
     ```bash
     nano Jenkinsfile
     ```
     - **Content**:
       ```groovy
       pipeline {
           agent any
           environment {
               AWS_REGION = 'us-east-1'
               ECR_REGISTRY = '<account-id>.dkr.ecr.us-east-1.amazonaws.com'
           }
           stages {
               stage('Checkout') {
                   steps {
                       git 'https://github.com/<your-username>/todo-app.git'
                   }
               }
               stage('Build and Push Backend') {
                   steps {
                       script {
                           docker.withRegistry("https://${ECR_REGISTRY}", 'aws-creds') {
                               def backendImage = docker.build("${ECR_REGISTRY}/todo-api:${env.BUILD_NUMBER}", './backend')
                               backendImage.push()
                               backendImage.push('latest')
                           }
                       }
                   }
               }
               stage('Build and Push Frontend') {
                   steps {
                       script {
                           docker.withRegistry("https://${ECR_REGISTRY}", 'aws-creds') {
                               def frontendImage = docker.build("${ECR_REGISTRY}/todo-frontend:${env.BUILD_NUMBER}", './frontend')
                               frontendImage.push()
                               frontendImage.push('latest')
                           }
                       }
                   }
               }
               stage('Deploy to EKS') {
                   steps {
                       sh '''
                           aws eks update-kubeconfig --region ${AWS_REGION} --name TodoCluster
                           kubectl set image deployment/backend backend=${ECR_REGISTRY}/todo-api:${BUILD_NUMBER}
                           kubectl set image deployment/frontend frontend=${ECR_REGISTRY}/todo-frontend:${BUILD_NUMBER}
                           kubectl rollout status deployment/backend
                           kubectl rollout status deployment/frontend
                       '''
                   }
               }
           }
       }
       ```
  4. **Create Pipeline**:
     - New Item > Pipeline > SCM: Git (repo URL), Script Path: `jenkins/Jenkinsfile`.
     - Build Now to test.

---

#### Step 9: Test and Validate
- **Goal**: Verify the app works end-to-end.
- **Commands**:
  ```bash
  ALB_DNS=$(kubectl get ingress todo-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  curl "http://$ALB_DNS/api/todos"  # Should return []
  curl -X POST "http://$ALB_DNS/api/todos" -H "Content-Type: application/json" -d '{"title":"Learn Kubernetes"}'
  curl "http://$ALB_DNS/api/todos"  # Should return the todo
  ```
  - Visit `http://$ALB_DNS` in a browser to use the UI.

---

### Best Practices
- **Modularity**: Separate backend and frontend for independent scaling.
- **Resource Limits**: Set CPU/memory to prevent overconsumption.
- **CI/CD**: Jenkins automates builds and deployments.
- **Observability**: Add `kubectl logs` or CloudWatch (future step).
- **Security**: Use AWS IAM roles, not hardcoded creds.

### Tips and Tricks
- **Debugging**: `kubectl describe pod <name>` for issues.
- **Rollback**: `kubectl rollout undo deployment/backend`.
- **Jenkins**: Save pipeline logs in S3: `aws s3 cp . s3://<bucket>`.
- **Cleanup**: `eksctl delete cluster --name TodoCluster`.

---

### Learning Outcomes
- Built a CRUD app with Node.js and React.
- Deployed to Kubernetes on EKS with Ingress.
- Automated CI/CD with Jenkins, mimicking real-world workflows.
