# Docker Learning Handbook

## Table of Contents
1. [Introduction to Docker](#1-introduction-to-docker)
   - [What is Docker?](#what-is-docker)
   - [Why Use Docker?](#why-use-docker)
   - [Key Concepts](#key-concepts)
2. [Getting Started](#2-getting-started)
   - [Installing Docker in WSL](#installing-docker-in-wsl)
   - [Verifying Installation](#verifying-installation)
3. [Essential Docker Commands](#3-essential-docker-commands)
   - [Image Management](#image-management)
   - [Container Management](#container-management)
   - [Building Images](#building-images)
   - [Networking and Ports](#networking-and-ports)
4. [Dockerfile Basics](#4-dockerfile-basics)
   - [Creating a Dockerfile](#creating-a-dockerfile)
   - [Common Instructions](#common-instructions)
5. [Organizing Docker Projects](#5-organizing-docker-projects)
   - [Using a Common Directory](#using-a-common-directory)
   - [Best Practices for Files](#best-practices-for-files)
6. [Docker Hub Integration](#6-docker-hub-integration)
   - [Pushing Images](#pushing-images)
   - [Pulling Images](#pulling-images)
7. [Day-to-Day Use Cases](#7-day-to-day-use-cases)
   - [Running a Web Server](#running-a-web-server)
   - [Testing Software](#testing-software)
   - [Development Environments](#development-environments)
8. [Best Practices](#8-best-practices)
   - [Image Optimization](#image-optimization)
   - [Container Management](#container-management-best-practices)
   - [Security Tips](#security-tips)
9. [Troubleshooting](#9-troubleshooting)
   - [Common Issues and Fixes](#common-issues-and-fixes)
10. [Resources](#10-resources)
    - [Official Docs and Tools](#official-docs-and-tools)
    - [Learning Materials](#learning-materials)

---

## 1. Introduction to Docker

### What is Docker?
Docker is a tool that lets you package applications (code, dependencies, configs—everything) into lightweight, portable *containers*. Think of containers as mini virtual machines, but leaner—they share the host’s OS kernel, so they start fast and use fewer resources. It’s a game-changer for DevOps because it ensures your app runs the same way everywhere: dev laptops, test servers, production clusters.

Docker is a platform that uses **containerization** to package applications and their dependencies into portable units called **containers**. Containers run consistently across different systems (e.g., your laptop, a server, or the cloud).

- **Beginner Analogy**: Think of a container as a lunchbox—everything you need (food, utensils) is packed inside, ready to go anywhere.

- **Conceptual Analogy**: Think of Docker as a shipping container for software. Just as a physical container standardizes transport across ships, trucks, and trains, Docker standardizes app deployment across dev, test, and prod.
- **Under the Hood**: Docker uses Linux kernel features like namespaces (isolation) and cgroups (resource limits) to create containers.

### Why Use Docker?
- **Consistency**: Eliminates “works on my machine” issues.
- **Portability**: Run the same container on a laptop, server, or cloud.
- **Efficiency**: Containers share the host kernel, using less CPU/memory than VMs.
- **Scalability**: Easy to replicate and deploy (think microservices).
- **DevOps Fit**: Streamlines CI/CD pipelines, testing, and deployment.

### Key Concepts
- **Image**: A read-only template (e.g., `ubuntu:20.04`) used to create containers. Built from a `Dockerfile`.
- **Container**: A runnable instance of an image. Isolated but shares the host OS kernel.
- **Dockerfile**: A script with instructions to build an image (e.g., install software, copy files).
- **Registry**: A storage hub for images (e.g., Docker Hub).
- **Volume**: Persistent storage for containers (data survives container restarts).
- **Network**: How containers communicate with each other or the outside world.

---

## 2. Getting Started

### Installing Docker in WSL (Windows Subsystem for Linux)
Assuming you’re on WSL (common for Linux learners on Windows), here’s how to set up Docker:

1. **Update WSL**:
   ```
   sudo apt update && sudo apt upgrade -y
   ```
2. **Install Docker**:
   ```
   sudo apt install docker.io -y
   ```
3. **Start Docker Service**:
   ```
   sudo service docker start
   ```
4. **Add User to Docker Group** (avoid `sudo` for every command):
   ```
   sudo usermod -aG docker $USER
   ```
   Log out and back in.
5. **Optional: Docker Desktop for WSL**:
   - Install Docker Desktop on Windows, enable WSL 2 integration in Settings > Resources > WSL Integration.

### Verifying Installation
- Check version:
  ```
  docker --version
  ```
- Test with a simple container:
  ```
  docker run hello-world
  ```
  If you see a “Hello from Docker!” message, it’s working.

---

## 3. Essential Docker Commands

### Image Management
- `docker pull <image>`: Download an image (e.g., `docker pull nginx`).
- `docker images`: List local images.
- `docker rmi <image>`: Remove an image (e.g., `docker rmi nginx`).

### Container Management
- `docker run <image>`: Start a container (e.g., `docker run ubuntu`).
- `docker run -it <image>`: Run interactively with a terminal.
- `docker ps`: List running containers.
- `docker ps -a`: List all containers (running or stopped).
- `docker stop <container_id>`: Stop a container (get ID from `ps`).
- `docker rm <container_id>`: Delete a stopped container.
- `docker exec -it <container_id> bash`: Jump into a running container’s shell.

### Building Images
- `docker build -t <name:tag> .`: Build an image from a `Dockerfile` (e.g., `docker build -t myapp:1.0 .`).
- `docker tag <source> <target>`: Tag an image (e.g., `docker tag myapp:1.0 myapp:latest`).

### Networking and Ports
- `docker run -p <host_port>:<container_port>`: Map ports (e.g., `docker run -p 8080:80 nginx`).
- `docker network ls`: List networks.
- `docker network create <name>`: Create a custom network.

---

## 4. Dockerfile Basics

### Creating a Dockerfile
A `Dockerfile` is a recipe for your image. Here’s a simple one for your healthcheck script:
```
FROM ubuntu:20.04
WORKDIR /app
COPY check.sh .
RUN chmod +x check.sh
CMD ["./check.sh"]
```

- Save as `Dockerfile` (no extension).

### Common Instructions
- **FROM**: Base image (e.g., `FROM python:3.9`).
- **WORKDIR**: Sets working directory inside the container.
- **COPY**: Copies files from host to container (e.g., `COPY script.sh /app/`).
- **RUN**: Executes commands during build (e.g., `RUN apt update`).
- **CMD**: Default command when the container runs (e.g., `CMD ["python", "app.py"]`).
- **EXPOSE**: Documents ports (e.g., `EXPOSE 80`).
- **ENV**: Sets environment variables (e.g., `ENV PATH=/app:$PATH`).

Build it: `docker build -t healthcheck:1.0 .`

---

## 5. Organizing Docker Projects

### Using a Common Directory
- Create a project folder (e.g., `~/docker-projects/healthcheck`).
- Structure:
  ```
  healthcheck/
  ├── Dockerfile
  ├── check.sh
  └── README.md
  ```
- Build and run from there.

### Best Practices for Files
- Keep `Dockerfile` and app files together.
- Use `.dockerignore` (like `.gitignore`) to exclude junk:
  ```
  *.log
  __pycache__
  ```
- Version control with Git.

---

## 6. Docker Hub Integration

### Pushing Images
1. Log inward Login: `docker login`
2. Tag your image: `docker tag healthcheck:1.0 myusername/healthcheck:1.0`
3. Push: `docker push myusername/healthcheck:1.0`

### Pulling Images
- `docker pull myusername/healthcheck:1.0`
- Use public images: `docker pull nginx`.

---

## 7. Day-to-Day Use Cases

### Running a Web Server
- `docker run -d -p 8080:80 nginx`: Run NGINX, access at `localhost:8080`.

### Testing Software
- Test your script in a clean env:
  ```
  docker run -it healthcheck:1.0
  ```

### Development Environments
- Use a Python dev container:
  ```
  docker run -it -v $(pwd):/app python:3.9 bash
  ```

---

## 8. Best Practices

### Image Optimization
- Use small base images (e.g., `alpine` variants).
- Minimize layers: Combine `RUN` commands with `&&`.
- Clean up: `RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/*`.

### Container Management Best Practices
- Name containers: `docker run --name myapp ...`.
- Remove unused containers/images: `docker system prune`.

### Security Tips
- Don’t run as root: Add `USER appuser` in `Dockerfile`.
- Update images regularly: `docker pull <image>`.

---

## 9. Troubleshooting

### Common Issues and Fixes
- **“Port already in use”**: Check with `ss -tulnp`, stop conflicting process.
- **“No space left on device”**: `docker system prune -a`.
- **Permission denied**: Ensure Docker daemon is running (`sudo service docker start`).

---

## 10. Resources

### Official Docs and Tools
- [Docker Docs](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)

### Learning Materials
- Docker’s “Get Started” tutorial: [docker.com/get-started](https://www.docker.com/get-started/)
- Book: *“Docker in Action”* by Jeff Nickoloff.

### Official Docs and Tools
- **[Docker Docs](https://docs.docker.com/)**: Command reference, tutorials.
- **[Docker Hub](https://hub.docker.com/)**: Explore images.
- **[Docker Desktop](https://www.docker.com/products/docker-desktop)**: GUI for Windows (optional).

### Learning Materials
- **Books**: “Docker Deep Dive” by Nigel Poulton.
- **Courses**: FreeCodeCamp’s Docker Tutorial (YouTube).
- **Cheat Sheet**: [Docker Cheat Sheet](https://github.com/wsargent/docker-cheat-sheet).

---

## Conclusion
This handbook covers Docker from setup to daily use, with commands and practices for beginners. Start with `docker run hello-world`, experiment with Dockerfiles, and organize projects with shared resources.

---

## Just pure Docker goodness.


