# SaaS Task Manager - Dockerized Project

## Overview
This project is a simple SaaS Task Manager application built with a **React.js frontend** and a **Node.js/Express backend**, containerized using Docker. It allows users to create, read, update, and delete tasks via a web interface, with data stored persistently in a JSON file. This README guides you through setting it up locally in WSL and running it on your system.

---

## Project Folder Structure
```
~/saas-task-manager/
├── backend/                # Backend Node.js/Express API
│   ├── Dockerfile          # Dockerfile for building the backend image
│   ├── app.js              # Main backend application file (API logic)
│   ├── package.json        # Node.js dependencies and scripts
│   ├── package-lock.json   # Lock file for dependency versions
│   └── tasks.json          # Persistent storage for tasks (generated at runtime)
├── frontend/               # Frontend React.js application
│   ├── Dockerfile          # Dockerfile for building the frontend image
│   ├── package.json        # React dependencies and scripts
│   ├── package-lock.json   # Lock file for dependency versions
│   ├── public/             # Public assets (e.g., index.html, favicon)
│   └── src/                # React source files (App.js, App.css, etc.)
└── docker-compose.yml      # Docker Compose configuration for multi-container setup
```

### File Descriptions
- **`backend/Dockerfile`**: Defines the multi-stage build process for the Node.js backend, installing dependencies and setting up the runtime environment.
- **`backend/app.js`**: Implements the Express API with CRUD endpoints (`GET /api/tasks`, `POST /api/tasks`, `PUT /api/tasks/:id`, `DELETE /api/tasks/:id`) and file-based storage.
- **`backend/package.json`**: Lists dependencies (`express`, `cors`) and the `start` script.
- **`backend/tasks.json`**: Stores tasks persistently; initialized as an empty array (`[]`) if not present.
- **`frontend/Dockerfile`**: Uses a multi-stage build to compile the React app and serve it with Nginx.
- **`frontend/package.json`**: Specifies React dependencies (e.g., `axios`) and build scripts.
- **`frontend/src/App.js`**: Core React component for displaying and managing tasks via API calls.
- **`docker-compose.yml`**: Configures the backend and frontend services, mapping ports and volumes.

---

## Prerequisites
- **WSL (Ubuntu)**: Ensure you're running WSL 2 with Ubuntu installed.
- **Docker**: Installed and running in WSL.
- **Docker Compose**: Installed for multi-container management.
- **Node.js**: Optional (for manual setup outside Docker, not required with Docker).

---

## Setup Instructions

### Step 1: Clone or Create the Project Directory
1. If cloning from a repository:
   ```bash
   git clone <repository-url> ~/saas-task-manager
   cd ~/saas-task-manager
   ```
2. If starting fresh, create the directory:
   ```bash
   mkdir ~/saas-task-manager
   cd ~/saas-task-manager
   ```
   - Note: Copy the project files (`backend/`, `frontend/`, `docker-compose.yml`) into this directory.

---

### Step 2: Install Docker and Docker Compose (If Not Already Installed)
1. **Install Docker**:
   ```bash
   sudo apt update
   sudo apt install docker.io -y
   sudo service docker start
   sudo usermod -aG docker $USER
   newgrp docker
   ```
2. **Install Docker Compose**:
   ```bash
   sudo apt install docker-compose -y
   ```
3. **Verify**:
   ```bash
   docker --version
   docker-compose --version
   ```

---

### Step 3: Prepare Persistent Storage
The backend uses `tasks.json` for data persistence:
1. **Initialize the file**:
   ```bash
   echo "[]" > ~/saas-task-manager/backend/tasks.json
   chmod 666 ~/saas-task-manager/backend/tasks.json  # Ensure write access
   ```

---

### Step 4: Build and Run the Application
1. **Navigate to Project Root**:
   ```bash
   cd ~/saas-task-manager
   ```
2. **Build and Start Containers**:
   ```bash
   docker-compose up -d --build
   ```
   - `--build`: Builds fresh images from Dockerfiles.
   - `-d`: Runs in detached mode (background).
3. **Verify Running Containers**:
   ```bash
   docker ps -a
   ```
   - **Expected Output**:
     ```
     CONTAINER ID   IMAGE                    PORTS                  NAMES
     <id>           saas-task-manager_frontend   0.0.0.0:8080->80/tcp   saas-task-manager_frontend_1
     <id>           saas-task-manager_backend    0.0.0.0:5000->5000/tcp saas-task-manager_backend_1
     ```

---

### Step 5: Test the Application
1. **Backend API**:
   - List tasks:
     ```bash
     curl localhost:5000/api/tasks
     ```
     - Expected: `[]` (empty array initially).
   - Add a task:
     ```bash
     curl -X POST -H "Content-Type: application/json" -d '{"title":"Test Task"}' localhost:5000/api/tasks
     ```
2. **Frontend UI**:
   - Open your browser at `http://localhost:8080`.
   - Add a task via the input field—verify it appears in the list.
   - Edit or delete tasks using the buttons (if implemented in `App.js`).

---

## Running Locally
- **Access**: The app runs on `http://localhost:8080` (frontend) and `http://localhost:5000` (backend API).
- **Stopping**: To stop the containers:
  ```bash
  docker-compose down
  ```
  - Add `-v` to remove volumes: `docker-compose down -v`.

---

## Troubleshooting
- **Port Conflict**:
  - Error: `Bind for 0.0.0.0:5000 failed`.
  - Fix: Check running containers (`docker ps`), stop conflicting ones (e.g., `docker stop <id>`), or change ports in `docker-compose.yml` (e.g., `"5001:5000"`).
- **500 Error**:
  - Check logs: `docker logs saas-task-manager_backend_1`.
  - Ensure `tasks.json` exists and is writable (`chmod 666 backend/tasks.json`).
- **Frontend Not Loading**:
  - Verify `docker ps` shows both services; rebuild with `docker-compose up -d --build`.

---

## Pushing Images to Docker Hub

### Prerequisites
- Docker Hub account (e.g., username `yourusername`).

### Steps
1. **Tag Images**:
   - Backend:
     ```bash
     docker tag saas-task-manager_backend yourusername/saas-task-backend:latest
     ```
   - Frontend:
     ```bash
     docker tag saas-task-manager_frontend yourusername/saas-task-frontend:latest
     ```
   - Replace `yourusername` with your Docker Hub username.

2. **Log In to Docker Hub**:
   ```bash
   docker login
   ```
   - Enter your username and password.

3. **Push Images**:
   - Backend:
     ```bash
     docker push yourusername/saas-task-backend:latest
     ```
   - Frontend:
     ```bash
     docker push yourusername/saas-task-frontend:latest
     ```

4. **Verify**:
   - Visit `hub.docker.com/u/yourusername` to see `saas-task-backend` and `saas-task-frontend`.

---

## Notes
- **Development**: Use `docker-compose.yml` for local dev; extend with a database (e.g., MongoDB) for production.
- **Best Practices**: Multi-stage Dockerfiles optimize image size; volumes ensure data persistence.

Enjoy setting up and exploring your SaaS Task Manager!

---

Get the images here: https://hub.docker.com/repositories/pxkundu