# 🚀 AWS Cloud Project - Serverless API with Terraform, Lambda & API Gateway

This project provides an **AWS Cloud-based serverless application** with the following components:

- **S3** for static website hosting
- **AWS Lambda** for backend API logic
- **API Gateway** for HTTP endpoints
- **DynamoDB** for NoSQL storage
- **CI/CD** using GitHub Actions
- **AWS WAF** for security
- **Infrastructure as Code (IaC) with Terraform**
- **CloudWatch for monitoring & alerts**

## 📌 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Infrastructure Deployment with Terraform](#infrastructure-deployment-with-terraform)
- [AWS Lambda API Function](#aws-lambda-api-function)
- [Deploy API Gateway](#deploy-api-gateway)
- [CI/CD Pipeline with GitHub Actions](#cicd-pipeline-with-github-actions)
- [Security with AWS WAF](#security-with-aws-waf)
- [Monitoring with CloudWatch](#monitoring-with-cloudwatch)
- [Cost Optimization](#cost-optimization)
- [Contributing](#contributing)
- [License](#license)

---

## 📌 Architecture Overview

![AWS Cloud Architecture](https://your-diagram-url.com)

This architecture follows AWS **best practices** for serverless applications by leveraging **AWS Lambda, API Gateway, and DynamoDB**, and it automates infrastructure deployment using **Terraform**.

---

## ✅ Prerequisites

Ensure you have the following installed:
- AWS CLI (`aws configure` with valid credentials)
- Terraform (`brew install terraform` or `choco install terraform`)
- GitHub Repository with Secrets (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for CI/CD)

---

## 🚀 Infrastructure Deployment with Terraform

### **1. Initialize Terraform**
```bash
terraform init
```

### **2. Deploy AWS Resources**
```bash
terraform apply -auto-approve
```
This creates:
- S3 Bucket (`my-static-website-bucket`)
- DynamoDB Table (`userTable`)
- API Gateway (`UserAPI`)
- Lambda Function (`UserAPI`)

---

## 🏗️ AWS Lambda API Function

### **Lambda Function Code** (`app.py`)
```python
import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("userTable")

def lambda_handler(event, context):
    if event["httpMethod"] == "POST":
        data = json.loads(event["body"])
        user_id = data["userId"]
        table.put_item(Item={"userId": user_id, "name": data["name"]})
        return {"statusCode": 201, "body": json.dumps({"message": "User added"})}
    elif event["httpMethod"] == "GET":
        user_id = event["queryStringParameters"]["userId"]
        response = table.get_item(Key={"userId": user_id})
        return {"statusCode": 200, "body": json.dumps(response.get("Item", {}))}
    else:
        return {"statusCode": 400, "body": json.dumps({"message": "Invalid request"})}
```

### **Deploy Lambda Function**
```bash
zip lambda_function.zip app.py
aws lambda update-function-code --function-name UserAPI --zip-file fileb://lambda_function.zip
```

---

## 🌍 Deploy API Gateway
```bash
aws apigateway import-rest-api --body file://apigateway.json
```

---

## ⚙️ CI/CD Pipeline with GitHub Actions

### **GitHub Actions Workflow** (`.github/workflows/deploy.yml`)
```yaml
name: Deploy AWS Lambda
on:
  push:
    branches:
      - main
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Set up AWS CLI
        run: |
          sudo apt-get update
          sudo apt-get install -y awscli
          aws configure set aws_access_key_id ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws configure set aws_secret_access_key ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws configure set region us-east-1
      - name: Deploy Lambda
        run: |
          zip lambda_function.zip app.py
          aws lambda update-function-code --function-name UserAPI --zip-file fileb://lambda_function.zip
```

---

## 🔒 Security with AWS WAF
Enable **AWS WAF** for API Gateway:
```bash
aws wafv2 create-web-acl --name "APIWAF" --scope REGIONAL --default-action Allow \
    --visibility-config CloudWatchMetricsEnabled=true
```

---

## 📊 Monitoring with AWS CloudWatch
Enable **CloudWatch Logging** for API Gateway:
```bash
aws apigateway update-stage --rest-api-id my-api-id --stage-name dev \
    --patch-operations op=replace,path=/*/*/loggingLevel,value=INFO
```

Set up an **alert for Lambda errors**:
```bash
aws cloudwatch put-metric-alarm --alarm-name "LambdaErrors" \
    --metric-name "Errors" --namespace "AWS/Lambda" --statistic Sum \
    --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold \
    --dimensions Name=FunctionName,Value=UserAPI --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:123456789012:MySNSTopic
```

---

## 💰 Cost Optimization
Enable **DynamoDB Auto Scaling**:
```bash
aws application-autoscaling register-scalable-target \
    --service-namespace dynamodb \
    --resource-id table/userTable \
    --scalable-dimension dynamodb:table:ReadCapacityUnits \
    --min-capacity 5 \
    --max-capacity 50
```

---

## 🤝 Contributing
Pull requests are welcome! Feel free to contribute to improve this project.

---

## 📜 License
This project is open-source and licensed under the **MIT License**.

