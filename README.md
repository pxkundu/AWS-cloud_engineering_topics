# 🚀 AWS Cloud Engineering Best Practices with Code Examples

This repository contains **20 AWS Cloud Engineering Best Practices** along with real-world **code examples** to help engineers build **secure, scalable, and cost-effective** solutions on AWS.

## 📌 Table of Contents

1. [IAM Security Best Practices](#1-use-iam-roles-instead-of-hardcoded-credentials)
2. [S3 Storage Optimization](#2-use-s3-lifecycle-policies-for-cost-optimization)
3. [Data Encryption](#3-encrypt-data-at-rest-in-s3)
4. [Logging and Monitoring](#4-enable-cloudtrail-for-auditing-aws-activities)
5. [Secrets Management](#5-use-parameter-store-for-secrets-management)
6. [Lambda Optimization](#6-optimize-lambda-with-memory-and-timeout-configurations)
7. [CloudWatch Logging](#7-use-cloudwatch-logs-for-monitoring-and-debugging)
8. [Database Management](#8-use-amazon-rds-with-automated-backups)
9. [IAM Least Privilege](#9-implement-least-privilege-for-iam-users-and-roles)
10. [Auto Scaling](#10-use-auto-scaling-for-ec2-instances)
11. [Load Balancing](#11-set-up-alb-application-load-balancer-for-traffic-distribution)
12. [EBS Encryption](#12-enable-ebs-encryption-for-security)
13. [VPC Endpoints](#13-use-vpc-endpoints-to-access-aws-services-privately)
14. [Athena Querying](#14-use-athena-for-ad-hoc-querying-on-s3)
15. [Threat Detection](#15-implement-guardduty-for-threat-detection)
16. [Infrastructure as Code](#16-use-cloudformation-for-infrastructure-as-code-iac)
17. [DDoS Protection](#17-use-aws-waf-to-protect-applications)
18. [Event-Driven Automation](#18-use-eventbridge-to-trigger-workflows)
19. [Workflow Orchestration](#19-use-step-functions-for-orchestrating-workflows)
20. [General AWS Best Practices](#20-general-best-practices)

---

## 🔐 1. Use IAM Roles Instead of Hardcoded Credentials

❌ **Bad Practice: Storing AWS credentials in code**
```python
aws_access_key = "AKIA..."
aws_secret_key = "..."
s3 = boto3.client("s3", aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key)
```

✅ **Best Practice: Use IAM Roles for authentication**
```python
import boto3

s3 = boto3.client("s3")  # Uses IAM Role automatically
```

---

## 📦 2. Use S3 Lifecycle Policies for Cost Optimization

✅ **Best Practice: Move old data to Glacier**
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

## 🔐 3. Encrypt Data at Rest in S3

✅ **Best Practice: Enable AES-256 encryption by default**
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

## 🔎 4. Enable CloudTrail for Auditing AWS Activities

✅ **Best Practice: Enable CloudTrail logging**
```bash
aws cloudtrail create-trail --name MyTrail --s3-bucket-name my-trail-logs
aws cloudtrail start-logging --name MyTrail
```

---

## 🔑 5. Use Parameter Store for Secrets Management

✅ **Best Practice: Store sensitive data securely**
```bash
aws ssm put-parameter --name "/app/db-password" --value "securepassword" --type "SecureString"
```
```python
import boto3

ssm = boto3.client("ssm")
password = ssm.get_parameter(Name="/app/db-password", WithDecryption=True)["Parameter"]["Value"]
```

---

## ⚡ 6. Optimize Lambda with Memory and Timeout Configurations

✅ **Best Practice: Adjust Lambda memory and timeout**
```bash
aws lambda update-function-configuration --function-name MyLambda --memory-size 512 --timeout 10
```

---

## 📊 7. Use CloudWatch Logs for Monitoring and Debugging

✅ **Best Practice: Send Lambda logs to CloudWatch**
```python
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Processing event: %s", event)
```

---

## 🗄️ 8. Use Amazon RDS with Automated Backups

✅ **Best Practice: Enable automatic backups**
```bash
aws rds modify-db-instance --db-instance-identifier mydb --backup-retention-period 7
```

---

## 🔒 9. Implement Least Privilege for IAM Users and Roles

✅ **Best Practice: Restrict S3 bucket access**
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

## 🔄 10. Use Auto Scaling for EC2 Instances

✅ **Best Practice: Scale EC2 instances automatically**
```bash
aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-asg \
  --launch-template LaunchTemplateName=my-template,Version=1 \
  --min-size 2 --max-size 10 --desired-capacity 2
```

---

## 🌍 20. General Best Practices

✅ **Follow these additional AWS best practices:**
- **Enable AWS Shield for DDoS protection**
- **Use AWS Organizations for centralized governance**
- **Implement AWS Config for compliance monitoring**
- **Regularly rotate IAM credentials**
- **Monitor cost usage with AWS Budgets**
- **Automate backups for EC2 & RDS**

---

## 📜 License

This repository follows an open-source **MIT License**. Feel free to contribute or modify the examples.

## 🤝 Contributing

Have a new best practice to add? Feel free to submit a **pull request**!

---

## 🚀 Author

📌 **Maintained by:** Partha Sarathi Kundu
📧 **Contact:** [LinkedIn](https://www.linkedin.com/in/partha-sarathi-kundu/) 
🔗 **Website:** [kundu.xyz](https://www.kundu.xyz)

