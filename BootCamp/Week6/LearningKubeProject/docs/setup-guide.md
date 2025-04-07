# Setup Guide
1. **Launch EC2 Instances**:
   - AMI: Amazon Linux 2023
   - Instance type: t2.medium (2 vCPU, 4 GiB RAM)
   - 1 master, 1 worker
   - Attach IAM role with EC2 permissions

2. **Configure Security Groups** (see `config/aws-security-group.txt`):
   - Master: 6443, 2379-2380, 10250-10252
   - Worker: 10250, 30000-32767
   - All: SSH (22), ICMP

3. **SSH into Instances**:
   - `ssh -i <key.pem> ec2-user@<instance-ip>`

4. **Run Scripts**:
   - Master: `sudo ./master_setup.sh`
   - Worker: `sudo ./worker_setup.sh`, then run the `kubeadm join` command from master.

5. **Deploy Application**:
   - On master: `kubectl apply -f manifests/nginx-deployment.yaml`
   - Expose: `kubectl apply -f manifests/nginx-service.yaml`
