# SaaS Task Manager Backend

## Overview
This folder contains the backend for the SaaS Task Manager, a Node.js/Express API that provides CRUD (Create, Read, Update, Delete) functionality for managing tasks. It uses a JSON file (`tasks.json`) for persistent storage and is Dockerized for easy setup and deployment. This README guides you through setting up and running the backend locally in WSL.

---

## Folder Structure
```
~/saas-task-manager/backend/
├── Dockerfile          # Dockerfile for building the backend image
├── app.js              # Main backend application file (API logic)
├── package.json        # Node.js dependencies and scripts
├── package-lock.json   # Lock file for dependency versions
├── tasks.json          # Persistent storage for tasks (generated at runtime)
└── .gitignore          # Git ignore file for excluding unnecessary files
```

### File Descriptions
- **`Dockerfile`**: Defines a multi-stage build process for the Node.js backend, installing dependencies and setting up the runtime environment with a slim Node.js image.
- **`app.js`**: Implements the Express API with endpoints for task management, handling file I/O for `tasks.json`, and enabling CORS for frontend compatibility.
- **`package.json`**: Specifies dependencies (`express`, `cors`) and the `start` script to launch the API.
- **`package-lock.json`**: Locks dependency versions for consistency across environments.
- **`tasks.json`**: Stores tasks persistently as JSON; initialized as an empty array if not present.
- **`.gitignore`**: Excludes runtime files (e.g., `node_modules/`, `tasks.json`) from version control.

---

## Prerequisites
- **WSL (Ubuntu)**: Ensure you're running WSL 2 with Ubuntu installed.
- **Docker**: Installed and running in WSL (see [Docker Setup](#docker-setup)).
- **Node.js**: Optional for manual local runs outside Docker (version 18+ recommended).

---

## Setup Instructions

### Step 1: Navigate to Backend Folder
```bash
cd ~/saas-task-manager/backend
```

### Step 2: Docker Setup (Recommended)
This uses Docker for consistency with the full project.

#### Install Docker (If Not Already Done)
```bash
sudo apt update
sudo apt install docker.io -y
sudo service docker start
sudo usermod -aG docker $USER
newgrp docker
```
- **Verify**: `docker --version`

#### Build the Docker Image
```bash
docker build -t saas-task-backend .
```
- **`-t saas-task-backend`**: Tags the image.

#### Initialize Persistent Storage
```bash
echo "[]" > tasks.json
chmod 666 tasks.json
```
- Ensures `tasks.json` exists and is writable.

#### Run the Container
```bash
docker run -d -p 5000:5000 -v $(pwd)/tasks.json:/app/tasks.json --name task-backend saas-task-backend
```
- **`-d`**: Runs in background.
- **`-p 5000:5000`**: Maps host port 5000 to container port 5000.
- **`-v`**: Mounts `tasks.json` for persistence.

#### Verify
```bash
docker ps
```
- Look for `task-backend` with `0.0.0.0:5000->5000/tcp`.

---

### Step 3: Manual Setup (Optional, Without Docker)
For development without Docker:
1. **Install Dependencies**:
   ```bash
   npm install
   ```
2. **Initialize `tasks.json`**:
   ```bash
   echo "[]" > tasks.json
   chmod 666 tasks.json
   ```
3. **Run Locally**:
   ```bash
   npm start
   ```
   - Starts the server on `http://localhost:5000`.

---

## API Endpoints
Test these with `curl` or a tool like Postman:

- **GET `/api/tasks`**:
  - Lists all tasks.
  - `curl localhost:5000/api/tasks`
  - Response: `[]` (initially) or array of tasks.

- **POST `/api/tasks`**:
  - Adds a new task.
  - `curl -X POST -H "Content-Type: application/json" -d '{"title":"Test Task"}' localhost:5000/api/tasks`
  - Response: `{ "id": 1, "title": "Test Task", "createdAt": "..." }`

- **PUT `/api/tasks/:id`**:
  - Updates a task by ID.
  - `curl -X PUT -H "Content-Type: application/json" -d '{"title":"Updated Task"}' localhost:5000/api/tasks/1`
  - Response: Updated task object.

- **DELETE `/api/tasks/:id`**:
  - Deletes a task by ID.
  - `curl -X DELETE localhost:5000/api/tasks/1`
  - Response: 204 No Content.

---

## Testing Locally
- **Docker**:
  - After running the container, test endpoints as above.
  - Check logs: `docker logs task-backend`.
- **Manual**:
  - After `npm start`, use the same `curl` commands.

---

## Stopping the Backend
- **Docker**:
  ```bash
  docker stop task-backend
  docker rm task-backend  # Optional: remove container
  ```
- **Manual**:
  - Press `Ctrl+C` in the terminal running `npm start`.

---

## Troubleshooting
- **Port Conflict**:
  - Error: `Bind for 0.0.0.0:5000 failed`.
  - Fix: Check `docker ps` or `sudo netstat -tuln | grep :5000`, stop conflicting processes (e.g., `docker stop <id>`), or use a different port (e.g., `-p 5001:5000`).
- **500 Error**:
  - Check `docker logs task-backend`—likely a `tasks.json` issue.
  - Fix: Ensure `tasks.json` exists and is writable (`chmod 666 tasks.json`).
- **Dependencies Missing**:
  - Run `npm install` if `node_modules/` is absent.

---

## Notes
- **Persistence**: `tasks.json` stores data; it’s mounted via Docker volume for consistency.
- **Integration**: Designed to pair with the frontend at `http://localhost:8080` (see project root README).
- **Best Practices**: Multi-stage Dockerfile optimizes image size; CORS enables frontend access.

---
