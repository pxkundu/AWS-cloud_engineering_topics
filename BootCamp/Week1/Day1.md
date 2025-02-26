**Week 1, Day 1: AWS Basics Refresher** 

Let's break it down even further to maximize learning about foundational AWS services (EC2, S3, IAM, VPC) while keeping the chaotic, real-world twist engaging. We’ll expand each activity with more granular steps, additional context, and optional stretch goals to ensure participants gain comprehensive knowledge and hands-on experience. The goal is to cover the essentials thoroughly, introduce practical troubleshooting, and leave room for exploration—all within a 4-6 hour window.

---

### Week 1, Day 1: AWS Basics Refresher
- **Duration**: 5-6 hours (adjustable based on pace)
- **Objective**: Master EC2, S3, IAM, and VPC basics, deploy a simple web server, and recover from a simulated "power outage."
- **Tools**: AWS Management Console, AWS CLI, SSH client (e.g., Terminal, PuTTY)
- **Focus Topics**: Compute (EC2), Storage (S3), Identity (IAM), Networking (VPC)

---

### Detailed Breakdown

#### 1. Theory: AWS Basics Overview (1 hour)
**Goal**: Build a strong conceptual foundation for AWS services.
- **Materials**: Slides/video (provided or self-paced), AWS documentation links.
- **Sub-Activities**:
  1. **Introduction to AWS (15 min)**:
     - Watch/listen to a quick overview: What is AWS? Key services (EC2, S3, IAM, VPC).
     - Key points: Regions, Availability Zones (AZs), pay-as-you-go model.
     - Action: Open AWS Console, explore the dashboard, note 2-3 services you recognize.
  2. **EC2 Deep Dive (15 min)**:
     - Learn: Instance types (e.g., t2.micro), AMIs (Amazon Machine Images), key pairs.
     - Example: “t2.micro is free-tier eligible, ideal for small workloads.”
     - Action: Look up `t2.micro` specs in AWS Console (EC2 > Instance Types).
  3. **S3 Basics (10 min)**:
     - Learn: Buckets, objects, public vs. private access.
     - Key takeaway: S3 is object storage, not a file system.
     - Action: Skim the S3 Console; note the “Create Bucket” button.
  4. **IAM Essentials (10 min)**:
     - Learn: Users, roles, policies (JSON permissions).
     - Example: “A role lets EC2 access S3 without hardcoding keys.”
     - Action: Open IAM > Policies, read a predefined policy (e.g., `AmazonS3ReadOnlyAccess`).
  5. **VPC Fundamentals (10 min)**:
     - Learn: Subnets, route tables, Internet Gateways.
     - Key takeaway: VPC isolates your resources; subnets define access.
     - Action: Open VPC Console, note the default VPC’s CIDR (e.g., 172.31.0.0/16).

- **Self-Check (5 min)**:
  - Answer: “What’s the difference between an EC2 instance and an S3 bucket?” Write 1-2 sentences in a notebook or chat.

---

#### 2. Lab: Launch an EC2 Instance in a Custom VPC (2.5-3 hours)
**Goal**: Deploy a web server hands-on, step-by-step, with troubleshooting practice.
- **Pre-Requisites**: AWS account (Free Tier or sandbox), AWS CLI installed (`aws --version` to verify).
- **Sub-Activities**:

1. **Set Up Your Environment (15 min)**:
   - **Step 1**: Log into AWS Console (use a sandbox or personal account).
   - **Step 2**: Pick a region (e.g., us-east-1); note it for consistency.
   - **Step 3**: Generate an SSH key pair:
     - EC2 > Key Pairs > Create Key Pair > Name: “bootcamp-key” > Download `.pem` file.
     - Secure it: `chmod 400 bootcamp-key.pem` (Linux/Mac) or restrict access (Windows).
   - **Step 4**: Install AWS CLI if not done (`pip install awscli`), configure with access keys:
     ```bash
     aws configure
     # Enter Access Key, Secret Key, region (us-east-1), output (json)
     ```

2. **Create a Custom VPC (30 min)**:
   - **Step 1**: Navigate to VPC Dashboard > Create VPC.
     - Name: “BootcampVPC”, CIDR: 10.0.0.0/16 (covers 65,536 IPs).
   - **Step 2**: Create a public subnet:
     - VPC > Subnets > Create Subnet > Name: “PublicSubnet”, CIDR: 10.0.1.0/24 (256 IPs).
     - Assign to “BootcampVPC”.
   - **Step 3**: Add an Internet Gateway:
     - VPC > Internet Gateways > Create > Name: “BootcampIGW” > Attach to “BootcampVPC”.
   - **Step 4**: Update the route table:
     - VPC > Route Tables > Select “BootcampVPC” default > Edit Routes.
     - Add: Destination: 0.0.0.0/0, Target: “BootcampIGW”.
     - Associate with “PublicSubnet”.

3. **Launch an EC2 Instance (45 min)**:
   - **Step 1**: EC2 > Launch Instance.
     - Select Amazon Linux 2 AMI (Free Tier eligible).
     - Instance Type: t2.micro.
     - Network: “BootcampVPC”, Subnet: “PublicSubnet”.
     - Key Pair: “bootcamp-key”.
   - **Step 2**: Configure Security Group:
     - Create new: Name “WebSG”, Rules: SSH (port 22, your IP), HTTP (port 80, 0.0.0.0/0).
   - **Step 3**: Launch and note the public IP (e.g., 54.123.45.67).

4. **Set Up a Web Server (45 min)**:
   - **Step 1**: SSH into the instance:
     ```bash
     ssh -i bootcamp-key.pem ec2-user@<public-ip>
     ```
   - **Step 2**: Install and start Apache:
     ```bash
     sudo yum update -y
     sudo yum install httpd -y
     sudo systemctl start httpd
     sudo systemctl enable httpd
     ```
   - **Step 3**: Create a basic webpage:
     ```bash
     echo "<h1>Welcome to Bootcamp!</h1>" | sudo tee /var/www/html/index.html
     ```
   - **Step 4**: Test in browser: `http://<public-ip>`. If it fails, check Security Group (port 80) and instance status.

5. **Stretch Goal (Optional, 15 min)**:
   - Use AWS CLI to describe your instance:
     ```bash
     aws ec2 describe-instances --filters "Name=tag:Name,Values=BootcampInstance"
     ```
   - Tag your instance: EC2 > Instances > Actions > Add/Edit Tags > Key: “Name”, Value: “BootcampInstance”.

---

#### 3. Chaos Twist: "Power Outage" (1.5-2 hours)
**Goal**: Simulate a failure and teach recovery under pressure.
- **Trigger**: Instructor deletes the subnet or detaches the Internet Gateway (announced mid-lab, e.g., “Region us-east-1 just lost power!”).
- **Sub-Activities**:

1. **Identify the Failure (20 min)**:
   - **Step 1**: Try SSH (`ssh -i bootcamp-key.pem ec2-user@<public-ip>`); note “Connection timed out.”
   - **Step 2**: Check browser (`http://<public-ip>`); confirm it’s down.
   - **Step 3**: Go to VPC Console > Subnets; see if “PublicSubnet” is missing or misconfigured.
   - **Step 4**: Check Route Tables; look for 0.0.0.0/0 pointing to “BootcampIGW”.

2. **Recover the Setup (1 hour)**:
   - **Step 1**: Recreate the subnet if deleted:
     - VPC > Subnets > Create > Name: “PublicSubnet”, CIDR: 10.0.1.0/24, VPC: “BootcampVPC”.
   - **Step 2**: Move the EC2 instance to the new subnet:
     - EC2 > Instances > Actions > Networking > Change Subnet > Select “PublicSubnet”.
   - **Step 3**: Reattach Internet Gateway if detached:
     - VPC > Internet Gateways > Actions > Attach to “BootcampVPC”.
   - **Step 4**: Fix the route table:
     - VPC > Route Tables > Edit Routes > 0.0.0.0/0 → “BootcampIGW”.
     - Associate with “PublicSubnet”.
   - **Step 5**: Test SSH and browser again; ensure the web server is back online.

3. **Document the Fix (15 min)**:
   - Write a brief “incident report” (e.g., in a text file or notebook):
     - What failed? (e.g., “Subnet deleted, lost connectivity.”)
     - Steps taken? (e.g., “Recreated subnet, updated routes.”)
     - Prevention? (e.g., “Use IaC next time.”)

4. **Stretch Goal (Optional, 15 min)**:
   - Simulate a second outage: Stop the EC2 instance (EC2 > Actions > Stop).
   - Restart it (Actions > Start) and verify recovery.

---

#### 4. Wrap-Up: War Room Discussion (30-45 min)
**Goal**: Reflect, share, and reinforce learning.
- **Sub-Activities**:
  1. **Present Your Setup (15 min)**:
     - Show your browser (`http://<public-ip>`) to peers/instructor.
     - Share one lesson (e.g., “Security Groups need HTTP open for web access.”).
  2. **Chaos Debrief (15 min)**:
     - Discuss: What broke during the outage? How did you fix it?
     - Instructor explains the chaos (e.g., “I deleted your subnet to mimic a hardware failure.”).
  3. **Q&A (10 min)**:
     - Ask peers/instructor: “Why did my SSH fail even after fixing the subnet?”
     - Note one tip for Day 2 (e.g., “Check Security Groups first.”).

---

### Maximum Information Packed In
- **EC2**: Instance lifecycle, AMIs, SSH, Security Groups, tagging.
- **VPC**: CIDR blocks, subnets, Internet Gateways, route tables.
- **IAM**: Key pairs, basic permissions (implied via Console access).
- **S3**: Introduced conceptually for context (hands-on on Day 2).
- **Troubleshooting**: Debug connectivity, recover from resource loss.
- **Real-World**: Simulate infra failure, document fixes like an SRE.

---

### Tips for Participants
- **Prepare**: Bookmark AWS docs (e.g., EC2 User Guide) and keep Console open.
- **Track**: Save commands in a `notes.txt` file (e.g., SSH, CLI snippets).
- **Ask**: Use the “mentor hotline” if stuck (e.g., “My Security Group isn’t working!”).

---

### Adjusted Timeline
- **Theory**: 1 hour
- **Lab**: 2.5-3 hours (breaks as needed)
- **Chaos Twist**: 1.5-2 hours
- **Wrap-Up**: 30-45 min
- **Total**: 5-6 hours (flexible; stretch goals optional)

---

This ultra-detailed breakdown ensures participants not only learn the “how” but also the “why” behind AWS basics, with practical steps and chaos to cement the experience. Want to tweak anything—like adding more S3/IAM depth or adjusting the chaos? Let me know!