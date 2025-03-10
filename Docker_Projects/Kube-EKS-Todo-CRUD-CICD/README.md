# To-Do List CRUD App with Kubernetes and Jenkins

## Overview
This project is a simple **To-Do List application** built with a **Node.js CRUD API** backend and a **ReactJS** frontend. It’s deployed on **Amazon EKS (Kubernetes)** and uses **Jenkins** for CI/CD automation on AWS. Designed for intermediate DevOps engineers, it demonstrates a real-world microservices setup with modern DevOps practices.

- **Purpose**: Learn Kubernetes deployment, AWS cloud integration, and CI/CD workflows.
- **Components**: Node.js API, React frontend, Kubernetes on EKS, Jenkins pipeline.
- **Tools**: AWS CLI, `eksctl`, `kubectl`, Docker, Jenkins, Git.

## Project Structure
```
todo-app/
├── backend/          # Node.js CRUD API
├── frontend/         # ReactJS frontend
├── k8s/             # Kubernetes manifests
├── jenkins/         # Jenkins CI/CD setup
├── .gitignore       # Git ignore file
└── README.md        # This file
```

## What’s This Project About?
- **Backend**: A Node.js API to manage to-do items (Create, Read, Update, Delete) with in-memory storage.
- **Frontend**: A React app to interact with the API via a user-friendly UI.
- **Deployment**: Runs on Amazon EKS with Kubernetes, using an ALB Ingress for routing.
- **CI/CD**: Jenkins automates building Docker images, pushing to ECR, and deploying to EKS.

## Learning Outcomes
By setting up this project, you’ll learn to:
1. **Build a CRUD App**: Create a Node.js API and React frontend from scratch.
2. **Containerize Apps**: Use Docker to package backend and frontend.
3. **Deploy with Kubernetes**: Manage microservices on AWS EKS with manifests and Ingress.
4. **Set Up CI/CD**: Automate builds and deployments with Jenkins on AWS.
5. **Apply DevOps Practices**: Practice modularity, automation, and scalability in a cloud environment.

## Getting Started
1. Clone the repo: `git clone https://github.com/<your-username>/todo-app.git`
2. Follow the steps in each directory to set up and deploy.
3. Test the app via the ALB URL after deployment.

Happy learning! 🚀


---

### Notes
- **Purpose**: Provides a high-level index without overwhelming detail, focusing on what the project is and why it matters.
- **Clarity**: Highlights key components and learning goals for quick understanding.
- **Actionable**: Encourages exploration of the project structure for hands-on learning.
