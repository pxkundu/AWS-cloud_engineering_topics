**20 Cloud Engineering Best Practices for AWS** along with **real-world code examples**:

---

### **1. Use IAM Roles Instead of Hardcoded Credentials**
❌ **Bad Practice:** Storing AWS credentials in code
```python
aws_access_key = "AKIA..."
aws_secret_key = "..."
s3 = boto3.client("s3", aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key)
```
✅ **Best Practice:** Use IAM roles for authentication
```python
import boto3

s3 = boto3.client("s3")  # Automatically uses IAM Role
```

---

### **2. Enable Multi-Factor Authentication (MFA) for AWS Root and IAM Users**
**✅ Best Practice:** Enforce MFA in AWS IAM settings.

```bash
aws iam update-login-profile --user-name AdminUser --password-reset-required
```

---

### **3. Use S3 Lifecycle Policies for Cost Optimization**
✅ **Best Practice:** Move old data to Glacier
```json
{
    "Rules": [
        {
            "ID": "MoveToGlacier",
            "Prefix": "logs/",
            "Status": "Enabled",
            "Transitions": [
                { "Days": 30, "StorageClass": "GLACIER" }
            ]
        }
    ]
}
```
```bash
aws s3api put-bucket-lifecycle-configuration --bucket my-bucket --lifecycle-configuration file://policy.json
```

---

### **4. Encrypt Data at Rest in S3**
✅ **Best Practice:** Enable AES-256 encryption by default
```bash
aws s3api put-bucket-encryption --bucket my-bucket --server-side-encryption-configuration file://encryption.json
```
```json
{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}
```

---

### **5. Enable CloudTrail for Auditing AWS Activities**
✅ **Best Practice:** Enable CloudTrail logging
```bash
aws cloudtrail create-trail --name MyTrail --s3-bucket-name my-trail-logs
aws cloudtrail start-logging --name MyTrail
```

---

### **6. Use Parameter Store for Secrets Management**
✅ **Best Practice:** Store sensitive data securely
```bash
aws ssm put-parameter --name "/app/db-password" --value "securepassword" --type "SecureString"
```
```python
import boto3

ssm = boto3.client("ssm")
password = ssm.get_parameter(Name="/app/db-password", WithDecryption=True)["Parameter"]["Value"]
```

---

### **7. Optimize Lambda with Memory and Timeout Configurations**
✅ **Best Practice:** Adjust Lambda memory and timeout
```bash
aws lambda update-function-configuration --function-name MyLambda --memory-size 512 --timeout 10
```

---

### **8. Use CloudWatch Logs for Monitoring and Debugging**
✅ **Best Practice:** Send Lambda logs to CloudWatch
```python
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Processing event: %s", event)
```

---

### **9. Use Amazon RDS with Automated Backups**
✅ **Best Practice:** Enable automatic backups
```bash
aws rds modify-db-instance --db-instance-identifier mydb --backup-retention-period 7
```

---

### **10. Implement Least Privilege for IAM Users and Roles**
✅ **Best Practice:** Restrict S3 bucket access
```json
{
  "Effect": "Deny",
  "Action": "s3:*",
  "Resource": "*",
  "Condition": {
    "BoolIfExists": {
      "aws:MultiFactorAuthPresent": "false"
    }
  }
}
```

---

### **11. Use Auto Scaling for EC2 Instances**
✅ **Best Practice:** Scale EC2 instances automatically
```bash
aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-asg \
  --launch-template LaunchTemplateName=my-template,Version=1 \
  --min-size 2 --max-size 10 --desired-capacity 2
```

---

### **12. Set Up ALB (Application Load Balancer) for Traffic Distribution**
✅ **Best Practice:** Distribute traffic efficiently
```bash
aws elbv2 create-load-balancer --name my-alb --subnets subnet-123456 subnet-789012
```

---

### **13. Enable EBS Encryption for Security**
✅ **Best Practice:** Encrypt EBS volumes
```bash
aws ec2 create-volume --size 10 --region us-west-2 --availability-zone us-west-2a --volume-type gp2 --encrypted
```

---

### **14. Use VPC Endpoints to Access AWS Services Privately**
✅ **Best Practice:** Avoid public internet access
```bash
aws ec2 create-vpc-endpoint --vpc-id vpc-123abc --service-name com.amazonaws.us-east-1.s3
```

---

### **15. Use Athena for Ad-hoc Querying on S3**
✅ **Best Practice:** Run SQL queries on S3 data
```sql
SELECT * FROM s3_access_logs WHERE status_code = 500;
```

---

### **16. Implement GuardDuty for Threat Detection**
✅ **Best Practice:** Enable GuardDuty
```bash
aws guardduty create-detector --enable
```

---

### **17. Use CloudFormation for Infrastructure as Code (IaC)**
✅ **Best Practice:** Automate AWS deployments
```yaml
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
```

---

### **18. Use AWS WAF to Protect Applications**
✅ **Best Practice:** Prevent DDoS attacks
```bash
aws wafv2 create-web-acl --name "my-waf" --scope REGIONAL
```

---

### **19. Use EventBridge to Trigger Workflows**
✅ **Best Practice:** Automate event-driven workflows
```bash
aws events put-rule --name my-rule --event-pattern '{"source": ["aws.ec2"]}'
```

---

### **20. Use Step Functions for Orchestrating Workflows**
✅ **Best Practice:** Automate processes without servers
```json
{
  "Comment": "Simple workflow",
  "StartAt": "Start",
  "States": {
    "Start": {
      "Type": "Pass",
      "End": true
    }
  }
}
```

---

These best practices will help you build **scalable, secure, and cost-effective** cloud solutions on AWS.