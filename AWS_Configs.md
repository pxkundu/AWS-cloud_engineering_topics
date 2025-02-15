A **real-world AWS cloud project configuration** covering **Infrastructure as Code (IaC)**, **Serverless Architecture**, **CI/CD**, and **Security Best Practices**.  

### 🔹 **Project Overview:**  
This covers an **AWS Cloud project** with:  
- **S3** for static website hosting  
- **Lambda & API Gateway** for backend functions  
- **DynamoDB** for data storage  
- **CI/CD with GitHub Actions**  
- **AWS WAF** for security  
- **Terraform for IaC**

---

## **1️⃣ Terraform Configuration for AWS Infrastructure**
**🚀 Provision S3, API Gateway, Lambda, DynamoDB, and IAM roles using Terraform**  

📌 **File:** `main.tf`  
```hcl
provider "aws" {
  region = "us-east-1"
}

# ✅ S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "website_bucket" {
  bucket = "my-static-website-bucket"
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

# ✅ DynamoDB Table for Data Storage
resource "aws_dynamodb_table" "user_data" {
  name           = "userTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"
  
  attribute {
    name = "userId"
    type = "S"
  }
}

# ✅ IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# ✅ Lambda Function for API Backend
resource "aws_lambda_function" "api_function" {
  function_name    = "UserAPI"
  role            = aws_iam_role.lambda_role.arn
  handler         = "app.lambda_handler"
  runtime         = "python3.8"
  filename        = "lambda_function.zip"
}

# ✅ API Gateway for HTTP Requests
resource "aws_api_gateway_rest_api" "user_api" {
  name        = "UserAPI"
  description = "API Gateway for User Data"
}

# ✅ Deploy API Gateway Stage
resource "aws_api_gateway_stage" "dev" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  deployment_id = aws_api_gateway_deployment.dev.id
}
```

🔹 **Deploy Terraform**
```bash
terraform init
terraform apply -auto-approve
```

---

## **2️⃣ AWS Lambda Function for Backend API**
📌 **File:** `app.py`  
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

🔹 **Deploy Lambda Function**
```bash
zip lambda_function.zip app.py
aws lambda update-function-code --function-name UserAPI --zip-file fileb://lambda_function.zip
```

---

## **3️⃣ API Gateway Configuration**
📌 **File:** `apigateway.json`  
```json
{
  "swagger": "2.0",
  "info": {
    "title": "User API",
    "version": "1.0"
  },
  "paths": {
    "/user": {
      "post": {
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:UserAPI/invocations",
          "httpMethod": "POST",
          "type": "aws_proxy"
        }
      },
      "get": {
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:UserAPI/invocations",
          "httpMethod": "GET",
          "type": "aws_proxy"
        }
      }
    }
  }
}
```
🔹 **Deploy API Gateway Configuration**
```bash
aws apigateway import-rest-api --body file://apigateway.json
```

---

## **4️⃣ CI/CD Pipeline with GitHub Actions**
📌 **File:** `.github/workflows/deploy.yml`  
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

🔹 **Benefit:** Automatically deploys the **Lambda function** when code is pushed to `main`.

---

## **5️⃣ Secure API with AWS WAF**
✅ **Best Practice:** Enable **AWS WAF** to protect API Gateway from malicious traffic.  

```bash
aws wafv2 create-web-acl --name "APIWAF" --scope REGIONAL --default-action Allow \
    --visibility-config CloudWatchMetricsEnabled=true
```

---

## **6️⃣ Cost Optimization: Enable DynamoDB Auto Scaling**
```bash
aws application-autoscaling register-scalable-target \
    --service-namespace dynamodb \
    --resource-id table/userTable \
    --scalable-dimension dynamodb:table:ReadCapacityUnits \
    --min-capacity 5 \
    --max-capacity 50
```
🔹 **Benefit:** **Optimizes cost** by automatically adjusting **DynamoDB throughput**.

---

## **7️⃣ Monitor System with AWS CloudWatch**
🔹 **Enable logging for API Gateway**  
```bash
aws apigateway update-stage --rest-api-id my-api-id --stage-name dev \
    --patch-operations op=replace,path=/*/*/loggingLevel,value=INFO
```

🔹 **Set up an alert for high Lambda error rate**
```bash
aws cloudwatch put-metric-alarm --alarm-name "LambdaErrors" \
    --metric-name "Errors" --namespace "AWS/Lambda" --statistic Sum \
    --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold \
    --dimensions Name=FunctionName,Value=UserAPI --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:123456789012:MySNSTopic
```

---

### 🎯 **Conclusion**
This project provides:
✅ **IaC with Terraform**  
✅ **AWS Lambda as a Serverless Backend**  
✅ **DynamoDB as a NoSQL Database**  
✅ **API Gateway for Public APIs**  
✅ **GitHub Actions for CI/CD**  
✅ **AWS WAF for Security**  
✅ **CloudWatch for Monitoring**  

