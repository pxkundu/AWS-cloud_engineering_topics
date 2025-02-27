# Cronjob Automation in WSL: Comprehensive Documentation

## Table of Contents
1. [Introduction](#1-introduction)
2. [Setting Up Cron in WSL](#2-setting-up-cron-in-wsl)
3. [Basic Cronjob Operations](#3-basic-cronjob-operations)
   - [Running a Text File Every 5 Minutes](#31-running-a-text-file-every-5-minutes)
   - [Logging Date/Time Every Friday at 10:00 AM](#32-logging-datetime-every-friday-at-1000-am)
   - [Updating a Text File Every 5 Minutes for Today Only](#33-updating-a-text-file-every-5-minutes-for-today-only)
   - [Deleting All Cronjobs](#34-deleting-all-cronjobs)
4. [AWS Integration with Cronjobs](#4-aws-integration-with-cronjobs)
   - [Creating an EC2 Instance with MySQL and HTML Page](#41-creating-an-ec2-instance-with-mysql-and-html-page)
   - [Starting/Stopping EC2 on Workdays](#42-startingstopping-ec2-on-workdays)
5. [Real-World Use Cases for Fortune 100 Companies](#5-real-world-use-cases-for-fortune-100-companies)
6. [Best Practices and Troubleshooting](#6-best-practices-and-troubleshooting)
7. [Conclusion](#7-conclusion)

---

## 1. Introduction
Cronjobs are a powerful way to schedule repetitive tasks in Linux environments like Windows Subsystem for Linux (WSL). This documentation covers cronjob setup, AWS integration, and practical examples based on your queries. All paths are relative to your WSL home directory: `/home/artha_undu`.

---

## 2. Setting Up Cron in WSL
WSL doesn’t run cron by default, so you must install and start it manually. To automate this on WSL startup:

### Commands
```bash
# Install cron
sudo apt update
sudo apt install cron

# Start cron manually
sudo service cron start

# Create a startup script for persistence
echo '#!/bin/bash
sudo service cron start
' > /home/artha_undu/.wsl_startup.sh

# Make it executable
chmod +x /home/artha_undu/.wsl_startup.sh

# Add to ~/.bashrc for automatic execution on WSL start
echo "~/home/artha_undu/.wsl_startup.sh" >> /home/artha_undu/.bashrc
```

### Notes
- Restart WSL (`wsl --shutdown` from Windows CMD) to test persistence.
- Check cron status: `sudo service cron status`.

---

## 3. Basic Cronjob Operations

### 3.1 Running a Text File Every 5 Minutes
**Objective**: Execute a script every 5 minutes.

**Script**: `/home/artha_undu/script.txt`
```bash
#!/bin/bash
echo "Task executed at $(date)" >> /home/artha_undu/log.txt
```

**Commands**
```bash
chmod +x /home/artha_undu/script.txt
(crontab -l 2>/dev/null; echo "*/5 * * * * /bin/bash /home/artha_undu/script.txt") | crontab -
crontab -l
```

**Cron Expression**: `*/5 * * * *` (every 5 minutes).

---

### 3.2 Logging Date/Time Every Friday at 10:00 AM
**Objective**: Log the current date and time to a file every Friday at 10:00 AM.

**Script**: `/home/artha_undu/log_datetime.sh`
```bash
#!/bin/bash
date >> /home/artha_undu/datetime.log
```

**Commands**
```bash
chmod +x /home/artha_undu/log_datetime.sh
(crontab -l 2>/dev/null; echo "0 10 * * 5 /bin/bash /home/artha_undu/log_datetime.sh") | crontab -
crontab -l
```

**Cron Expression**: `0 10 * * 5` (10:00 AM every Friday; 5 = Friday).

---

### 3.3 Updating a Text File Every 5 Minutes for Today Only
**Objective**: Append date/time to a file every 5 minutes, but only on February 27, 2025.

**Script**: `/home/artha_undu/update_text.sh`
```bash
#!/bin/bash
if [ "$(date +%Y-%m-%d)" = "2025-02-27" ]; then
    echo "$(date)" >> /home/artha_undu/myfile.txt
fi
```

**Commands**
```bash
chmod +x /home/artha_undu/update_text.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /bin/bash /home/artha_undu/update_text.sh") | crontab -
crontab -l
```

**Cron Expression**: `*/5 * * * *` (every 5 minutes, with script logic limiting to today).

---

### 3.4 Deleting All Cronjobs
**Objective**: Remove all cronjobs for the current user.

**Commands**
```bash
crontab -r
crontab -l  # Should return "no crontab for artha_undu"
```

**Note**: This only affects your user’s cronjobs, not system-wide ones.

---

## 4. AWS Integration with Cronjobs

### 4.1 Creating an EC2 Instance with MySQL and HTML Page
**Objective**: Launch a free-tier EC2 instance, install MySQL and Apache, and display date/time on an HTML page.

**Script**: `/home/artha_undu/setup_ec2.sh`
```bash
#!/bin/bash
KEY_NAME="artha-key"
SECURITY_GROUP="artha-sg"
AMI_ID="ami-0c55b159cbfafe1f0"  # Update for your region
INSTANCE_TYPE="t2.micro"
HTML_FILE="/var/www/html/index.html"
SUBNET_ID="subnet-xxxxxxxx"    # Replace with your subnet ID

aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem

aws ec2 create-security-group --group-name $SECURITY_GROUP --description "SG for EC2"
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP --protocol tcp --port 80 --cidr 0.0.0.0/0

USER_DATA=$(cat << 'EOF' | base64
#!/bin/bash
yum update -y
yum install -y httpd mysql-server
systemctl start httpd mysqld
systemctl enable httpd mysqld
echo "<html><body><h1>Current Date and Time: $(date)</h1></body></html>" > $HTML_FILE
EOF
)

INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-groups $SECURITY_GROUP --subnet-id $SUBNET_ID --user-data "$USER_DATA" --query 'Instances[0].InstanceId' --output text)
echo $INSTANCE_ID > /home/artha_undu/instance_id.txt
```

**Commands**
```bash
chmod +x /home/artha_undu/setup_ec2.sh
./home/artha_undu/setup_ec2.sh
```

---

### 4.2 Starting/Stopping EC2 on Workdays
**Objective**: Start the EC2 instance at 9 AM and stop it at 5 PM, Monday-Friday.

**Start Script**: `/home/artha_undu/start_ec2.sh`
```bash
#!/bin/bash
INSTANCE_ID=$(cat /home/artha_undu/instance_id.txt)
aws ec2 start-instances --instance-ids $INSTANCE_ID
```

**Stop Script**: `/home/artha_undu/stop_ec2.sh`
```bash
#!/bin/bash
INSTANCE_ID=$(cat /home/artha_undu/instance_id.txt)
aws ec2 stop-instances --instance-ids $INSTANCE_ID
```

**Commands**
```bash
chmod +x /home/artha_undu/start_ec2.sh /home/artha_undu/stop_ec2.sh
(crontab -l 2>/dev/null; echo "0 9 * * 1-5 /bin/bash /home/artha_undu/start_ec2.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 17 * * 1-5 /bin/bash /home/artha_undu/stop_ec2.sh") | crontab -
crontab -l
```

**Cron Expressions**:
- `0 9 * * 1-5`: 9:00 AM, Monday-Friday.
- `0 17 * * 1-5`: 5:00 PM, Monday-Friday.

---

## 5. Real-World Use Cases for Fortune 100 Companies
These examples reflect automation needs in large enterprises.

### 5.1 Daily Database Backup
**Script**: `/home/artha_undu/backup_db.sh`
```bash
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="company_db"
BACKUP_DIR="/home/artha_undu/backups"
mysqldump -u root -p'password' $DB_NAME > $BACKUP_DIR/$DB_NAME_$TIMESTAMP.sql
aws s3 cp $BACKUP_DIR/$DB_NAME_$TIMESTAMP.sql s3://company-backups/
```
**Cron**: `0 2 * * *`

### 5.2 System Health Monitoring
**Script**: `/home/artha_undu/check_health.sh`
```bash
#!/bin/bash
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if [ $DISK_USAGE -gt 80 ]; then
    echo "Disk usage at $DISK_USAGE% on $(date)" | mail -s "ALERT" admin@company.com
fi
```
**Cron**: `0 * * * *`

### 5.3 Inventory Sync
**Script**: `/home/artha_undu/sync_inventory.sh`
```bash
#!/bin/bash
curl -o /home/artha_undu/inventory.json "https://api.company.com/inventory"
mysql -u root -p'password' company_db < /home/artha_undu/update_inventory.sql
aws s3 sync /home/artha_undu/inventory.json s3://inventory-sync/
```
**Cron**: `*/15 * * * *`

### 5.4 Financial Reporting
**Script**: `/home/artha_undu/generate_report.sh`
```bash
#!/bin/bash
REPORT_FILE="/home/artha_undu/daily_report_$(date +%Y%m%d).csv"
echo "Date,Revenue" > $REPORT_FILE
mysql -u root -p'password' -e "SELECT DATE(NOW()), SUM(revenue) FROM sales" company_db >> $REPORT_FILE
aws s3 cp $REPORT_FILE s3://company-reports/
```
**Cron**: `0 6 * * *`

### 5.5 Log Rotation
**Script**: `/home/artha_undu/rotate_logs.sh`
```bash
#!/bin/bash
LOG_DIR="/var/log/company_app"
find $LOG_DIR -name "*.log" -mtime +7 -exec rm {} \;
tar -czf $LOG_DIR/archive_$(date +%Y%m%d).tar.gz $LOG_DIR/*.log
aws s3 mv $LOG_DIR/archive_$(date +%Y%m%d).tar.gz s3://log-archives/
```
**Cron**: `0 0 * * 0`

---

## 6. Best Practices and Troubleshooting

### Best Practices
- **Script Permissions**: Always `chmod +x` scripts.
- **Full Paths**: Use absolute paths (e.g., `/bin/bash`) in cronjobs.
- **Logging**: Redirect output (`>> /path/to/log 2>&1`) for debugging.
- **AWS Credentials**: Store securely as env variables (e.g., via `set-aws-keys.sh`).
- **Cleanup**: Remove unused cronjobs and AWS resources to avoid costs.

### Troubleshooting
- **Cron Not Running**: `sudo service cron status`.
- **Job Not Executing**: Check syntax with `crontab -l` and logs.
- **AWS Errors**: Verify credentials (`aws sts get-caller-identity`) and permissions.
- **WSL Restart**: Use `wsl --shutdown` to reset environment.

---

## 7. Conclusion
This documentation provides a robust foundation for cronjob automation in WSL, from basic scheduling to AWS-integrated tasks and enterprise use cases. Save scripts in `/home/artha_undu/`, adjust paths/credentials as needed, and leverage this guide for scalable automation projects.

--- 
