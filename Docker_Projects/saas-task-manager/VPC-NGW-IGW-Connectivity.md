
# SaaS Task Manager AWS Deployment in public and private subnets having internet access via NGW + IGW

## Overview
This README documents the tasks completed today to set up a VPC with public and private subnets, deploy a bastion host in the public subnet, and configure a private EC2 instance with internet access via a NAT Gateway. 

The setup uses AWS CLI in WSL and integrates Docker for containerized services, reflecting a typical SaaS architecture with secure access and network isolation. 

The tasks include creating an EC2 instance, installing Docker, building a Docker image, running containers, and testing internet connectivity from the private instance.

---

## Tasks Completed Today
1. **Created EC2 Instance in Custom VPC with Public IP**
   - Set up a VPC (`10.0.0.0/16`), public subnet (`10.0.1.0/24`), and launched an EC2 with a public IP.
2. **Installed Docker on Public EC2**
   - Configured Docker on the public EC2 instance.
3. **Created Docker Image and Containers**
   - Built a Node.js/Express backend image and ran two containers on different ports (5000, 5001).
4. **Accessed Containers via Public IP**
   - Tested container endpoints externally.
5. **Created Public and Private Subnets**
   - Added a private subnet (`10.0.2.0/24`) alongside the public subnet.
6. **Set Up Bastion Host**
   - Deployed a bastion EC2 in the public subnet for secure access.
7. **Configured Private EC2 with NAT Gateway**
   - Launched a private EC2 and enabled internet access via NAT Gateway.
8. **Tested Internet Access from Private Instance**
   - Verified connectivity through the bastion.

---

## Project Folder Structure
Since most tasks were executed via AWS CLI and SSH, the local structure is minimal, with key files on EC2 instances:

### Local WSL Structure
```
~/saas-task-manager/
├── artha-key.pem       # SSH key for EC2 access
└── README.md           # This file
```

### Bastion EC2 Structure (Public Subnet)
```
~/ (ec2-user home)
├── artha-key.pem       # Copied SSH key for private EC2 access
└── backend/            # Docker backend files
    ├── Dockerfile      # Docker image definition for backend
    ├── app.js          # Node.js/Express API
    └── package.json    # Node.js dependencies and scripts
```

### Private EC2 Structure (Private Subnet)
```
~/ (ec2-user home)
└── (Minimal setup, Docker installed)
```

### File Descriptions
- **`artha-key.pem`**: SSH private key for accessing EC2 instances.
- **`backend/Dockerfile`**: Defines a Node.js image with Express for the backend API.
- **`backend/app.js`**: Implements a simple task API (GET/POST endpoints).
- **`backend/package.json`**: Lists dependencies (`express`) and start script.

---

## Prerequisites
- **WSL (Ubuntu)**: WSL 2 with Ubuntu installed.
- **AWS CLI**: Configured (`aws configure` with access key, secret key, `us-east-1`).
- **SSH Key**: `artha-key.pem` in `~/`.
- **Docker**: Installed locally (optional for image prep) and on EC2.

---

## Setup Instructions

### Step 1: Create VPC and Subnets
1. **VPC**:
   ```bash
   VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region us-east-1 --query 'Vpc.VpcId' --output text)
   aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=saas-vpc --region us-east-1
   ```
2. **Public Subnet**:
   ```bash
   PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --region us-east-1 --query 'Subnet.SubnetId' --output text)
   aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch --region us-east-1
   ```
3. **Private Subnet**:
   ```bash
   PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --region us-east-1 --query 'Subnet.SubnetId' --output text)
   ```
4. **Internet Gateway**:
   ```bash
   IGW_ID=$(aws ec2 create-internet-gateway --region us-east-1 --query 'InternetGateway.InternetGatewayId' --output text)
   aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region us-east-1
   ```

### Step 2: Set Up Route Tables
1. **Public Route Table**:
   ```bash
   PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region us-east-1 --query 'RouteTable.RouteTableId' --output text)
   aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region us-east-1
   aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET_ID --region us-east-1
   ```
2. **Private Route Table**:
   ```bash
   PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region us-east-1 --query 'RouteTable.RouteTableId' --output text)
   aws ec2 associate-route-table --route-table-id $PRIVATE_RT_ID --subnet-id $PRIVATE_SUBNET_ID --region us-east-1
   ```

### Step 3: Deploy Bastion Host
1. **Security Group**:
   ```bash
   BASTION_SG_ID=$(aws ec2 create-security-group --group-name bastion-sg --description "Bastion Host SG" --vpc-id $VPC_ID --region us-east-1 --query 'GroupId' --output text)
   aws ec2 authorize-security-group-ingress --group-id $BASTION_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-east-1
   aws ec2 authorize-security-group-ingress --group-id $BASTION_SG_ID --protocol tcp --port 5000 --cidr 0.0.0.0/0 --region us-east-1
   aws ec2 authorize-security-group-ingress --group-id $BASTION_SG_ID --protocol tcp --port 5001 --cidr 0.0.0.0/0 --region us-east-1
   ```
2. **Launch Bastion**:
   ```bash
   BASTION_INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0ebfd94a888d1b672 --instance-type t2.micro --key-name artha-key --security-group-ids $BASTION_SG_ID --subnet-id $PUBLIC_SUBNET_ID --associate-public-ip-address --region us-east-1 --query 'Instances[0].InstanceId' --output text)
   BASTION_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $BASTION_INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region us-east-1)
   ```

### Step 4: Install Docker and Run Containers on Bastion
1. **SSH into Bastion**:
   ```bash
   ssh -i ~/artha-key.pem ec2-user@$BASTION_PUBLIC_IP
   ```
2. **Install Docker** (inside EC2):
   ```bash
   sudo yum update -y
   sudo yum install docker -y
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo groupadd docker
   sudo usermod -aG docker ec2-user
   exit
   ssh -i ~/artha-key.pem ec2-user@$BASTION_PUBLIC_IP
   ```
3. **Create and Run Containers** (inside EC2):
   ```bash
   mkdir ~/backend
   cd ~/backend
   echo "const express = require('express'); const app = express(); app.use(express.json()); let tasks = []; app.get('/api/tasks', (req, res) => res.json(tasks)); app.post('/api/tasks', (req, res) => { const task = req.body; tasks.push(task); res.status(201).json(task); }); app.listen(5000, () => console.log('Server on port 5000'));" > app.js
   echo "FROM node:18-slim WORKDIR /app COPY package*.json ./ RUN npm install express COPY . . EXPOSE 5000 CMD [\"node\", \"app.js\"]" > Dockerfile
   echo '{\"name\": \"saas-backend\", \"version\": \"1.0.0\", \"main\": \"app.js\", \"scripts\": {\"start\": \"node app.js\"}, \"dependencies\": {\"express\": \"^4.18.2\"}}' > package.json
   docker build -t saas-task-backend .
   docker run -d -p 5000:5000 --name backend1 saas-task-backend
   docker run -d -p 5001:5000 --name backend2 saas-task-backend
   ```

### Step 5: Configure Private EC2 with NAT Gateway
1. **NAT Gateway**:
   ```bash
   EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --region us-east-1 --query 'AllocationId' --output text)
   NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET_ID --allocation-id $EIP_ALLOC_ID --region us-east-1 --query 'NatGateway.NatGatewayId' --output text)
   aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID --region us-east-1
   aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID --region us-east-1
   ```
2. **Private Security Group**:
   ```bash
   PRIVATE_SG_ID=$(aws ec2 create-security-group --group-name private-sg --description "Private EC2 SG" --vpc-id $VPC_ID --region us-east-1 --query 'GroupId' --output text)
   aws ec2 authorize-security-group-ingress --group-id $PRIVATE_SG_ID --protocol tcp --port 22 --source-group $BASTION_SG_ID --region us-east-1
   ```
3. **Launch Private EC2**:
   ```bash
   PRIVATE_INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0ebfd94a888d1b672 --instance-type t2.micro --key-name artha-key --security-group-ids $PRIVATE_SG_ID --subnet-id $PRIVATE_SUBNET_ID --region us-east-1 --query 'Instances[0].InstanceId' --output text)
   PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $PRIVATE_INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --region us-east-1)
   ```

### Step 6: Test Internet Access from Private EC2
1. **SSH to Private EC2 via Bastion**:
   ```bash
   ssh -i ~/artha-key.pem -A -J ec2-user@$BASTION_PUBLIC_IP ec2-user@$PRIVATE_IP
   ```
2. **Test Internet** (inside private EC2):
   ```bash
   ping -c 4 google.com
   curl -I https://www.google.com
   ```

---

## Running Locally
- **Bastion Containers**: Access via `$BASTION_PUBLIC_IP:5000` and `$BASTION_PUBLIC_IP:5001`.
- **Private EC2**: SSH via bastion; internet works through NAT Gateway.

---

## Troubleshooting
- **Docker Install Fails**: Use `yum install docker` if `amazon-linux-extras` fails; ensure `systemctl`.
- **SSH Fails**: Verify key permissions (`chmod 400 ~/artha-key.pem`), security groups.
- **No Internet in Private EC2**: Check NAT Gateway state (`available`), private route table (`0.0.0.0/0` to `$NAT_GW_ID`).

---

## Pushing Images to Docker Hub
1. **Tag Images** (on bastion):
   ```bash
   docker tag saas-task-backend yourusername/saas-task-backend:latest
   ```
2. **Login**:
   ```bash
   docker login
   ```
3. **Push**:
   ```bash
   docker push yourusername/saas-task-backend:latest
   ```

---

## Notes
- **Bastion**: Public EC2 for SSH tunneling and container hosting.
- **Private EC2**: Isolated with NAT Gateway for internet, accessible via bastion.
- **Docker**: Runs backend API on bastion; can be added to private EC2.

---
