# AWS Infrastructure as Code — Complete Reference

## AWS-Native IaC Tools

### 1. AWS CloudFormation
The original AWS-native IaC service. Declarative JSON/YAML templates that describe your stack.

- **Type:** Declarative, Cloud-native
- **Language:** JSON / YAML
- **State Management:** Managed by AWS (no state file needed)
- **Best For:** Pure AWS shops, tight AWS service integration

```yaml
# cloudformation/s3-bucket.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Simple S3 bucket with versioning

Parameters:
  BucketName:
    Type: String
    Description: Name of the S3 bucket

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref BucketName
      VersioningConfiguration:
        Status: Enabled
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256

Outputs:
  BucketArn:
    Value: !GetAtt MyBucket.Arn
    Export:
      Name: !Sub "${AWS::StackName}-BucketArn"
```

**References:**
- [CloudFormation Docs](https://docs.aws.amazon.com/cloudformation/)
- [CloudFormation Templates GitHub](https://github.com/awslabs/aws-cloudformation-templates)
- [cfn-lint](https://github.com/aws-cloudformation/cfn-lint)

---

### 2. AWS CDK (Cloud Development Kit)
Define cloud infrastructure using familiar programming languages. Synthesizes to CloudFormation.

- **Type:** Imperative/Declarative hybrid
- **Language:** TypeScript, Python, Java, Go, C#
- **State Management:** Via CloudFormation underneath
- **Best For:** Developers who prefer code over YAML

```typescript
// cdk/lib/s3-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export class S3Stack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    new s3.Bucket(this, 'MyBucket', {
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
  }
}
```

**References:**
- [AWS CDK Docs](https://docs.aws.amazon.com/cdk/v2/guide/home.html)
- [CDK GitHub](https://github.com/aws/aws-cdk)
- [CDK Patterns](https://cdkpatterns.com/)
- [Construct Hub](https://constructs.dev/)

---

### 3. AWS SAM (Serverless Application Model)
CloudFormation extension for serverless workloads. Simplifies Lambda, API Gateway, DynamoDB definitions.

- **Type:** Declarative, Cloud-native
- **Language:** YAML
- **Best For:** Serverless-first architectures

```yaml
# sam/template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Globals:
  Function:
    Runtime: nodejs18.x
    Timeout: 30
    Environment:
      Variables:
        TABLE_NAME: !Ref TaskTable

Resources:
  TaskFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: src/handler.main
      Events:
        Api:
          Type: Api
          Properties:
            Path: /tasks
            Method: GET

  TaskTable:
    Type: AWS::Serverless::SimpleTable
    Properties:
      PrimaryKey:
        Name: id
        Type: String
```

**References:**
- [SAM Docs](https://docs.aws.amazon.com/serverless-application-model/)
- [SAM GitHub](https://github.com/aws/serverless-application-model)
- [SAM CLI](https://github.com/aws/aws-sam-cli)

---

## Multi-Cloud / Third-Party IaC Tools on AWS

### 4. Terraform (HashiCorp)
The industry standard for multi-cloud IaC. HCL-based, provider ecosystem of 3000+.

- **Type:** Declarative
- **Language:** HCL (HashiCorp Configuration Language)
- **State Management:** Local file or remote (S3 + DynamoDB, Terraform Cloud)
- **Best For:** Multi-cloud, team environments, mature module ecosystem

```hcl
# terraform/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "my-tfstate-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = var.common_tags
}
```

**References:**
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Terragrunt](https://github.com/gruntwork-io/terragrunt)
- [Gruntwork IaC Library](https://github.com/gruntwork-io)

---

### 5. Pulumi
IaC using real programming languages. No DSL — use Python, TypeScript, Go, Java.

- **Type:** Imperative/Declarative
- **Language:** Python, TypeScript, Go, Java, C#
- **State Management:** Pulumi Cloud or self-hosted
- **Best For:** Teams wanting full language power (loops, conditionals, abstractions)

```python
# pulumi/__main__.py
import pulumi
import pulumi_aws as aws

config = pulumi.Config()
env = config.require("env")

bucket = aws.s3.Bucket(
    f"{env}-app-bucket",
    versioning=aws.s3.BucketVersioningArgs(enabled=True),
    server_side_encryption_configuration=aws.s3.BucketServerSideEncryptionConfigurationArgs(
        rule=aws.s3.BucketServerSideEncryptionConfigurationRuleArgs(
            apply_server_side_encryption_by_default=aws.s3.BucketServerSideEncryptionConfigurationRuleApplyServerSideEncryptionByDefaultArgs(
                sse_algorithm="AES256"
            )
        )
    ),
)

pulumi.export("bucket_name", bucket.id)
pulumi.export("bucket_arn", bucket.arn)
```

**References:**
- [Pulumi Docs](https://www.pulumi.com/docs/)
- [Pulumi GitHub](https://github.com/pulumi/pulumi)
- [Pulumi Examples](https://github.com/pulumi/examples)
- [Pulumi Registry](https://www.pulumi.com/registry/)

---

### 6. Ansible
Agentless configuration management and provisioning. Great for post-provisioning config.

- **Type:** Imperative (procedural)
- **Language:** YAML (Playbooks)
- **Best For:** Configuration management, app deployment, hybrid environments

```yaml
# ansible/playbooks/ec2-setup.yml
---
- name: Provision and configure EC2
  hosts: localhost
  gather_facts: false
  vars:
    instance_type: t3.medium
    ami_id: ami-0c55b159cbfafe1f0
    region: us-east-1

  tasks:
    - name: Launch EC2 instance
      amazon.aws.ec2_instance:
        name: "app-server"
        instance_type: "{{ instance_type }}"
        image_id: "{{ ami_id }}"
        region: "{{ region }}"
        vpc_subnet_id: "{{ subnet_id }}"
        security_groups: ["{{ sg_id }}"]
        tags:
          Environment: production
      register: ec2

    - name: Wait for SSH
      wait_for:
        host: "{{ ec2.instances[0].public_ip_address }}"
        port: 22
        timeout: 300
```

**References:**
- [Ansible AWS Guide](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [Ansible Galaxy AWS](https://galaxy.ansible.com/amazon/aws)
- [Ansible GitHub](https://github.com/ansible/ansible)

---

### 7. Crossplane
Kubernetes-native IaC. Manage cloud resources as Kubernetes CRDs.

- **Type:** Declarative (Kubernetes-native)
- **Language:** YAML (Kubernetes manifests)
- **Best For:** Platform engineering teams running on Kubernetes

```yaml
# crossplane/s3-bucket.yaml
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-app-bucket
spec:
  forProvider:
    region: us-east-1
    tags:
      Environment: production
  providerConfigRef:
    name: aws-provider
```

**References:**
- [Crossplane Docs](https://docs.crossplane.io/)
- [Crossplane GitHub](https://github.com/crossplane/crossplane)
- [Upbound Marketplace](https://marketplace.upbound.io/)

---

### 8. OpenTofu
Open-source fork of Terraform (post BSL license change). Drop-in replacement.

- **References:**
- [OpenTofu GitHub](https://github.com/opentofu/opentofu)
- [OpenTofu Docs](https://opentofu.org/docs/)

---

## IaC Tool Comparison Matrix

| Tool | Language | State Mgmt | Multi-cloud | Learning Curve | Best Use Case |
|------|----------|------------|-------------|----------------|---------------|
| CloudFormation | YAML/JSON | AWS-managed | No | Medium | AWS-only teams |
| CDK | TS/Python/Go | Via CFN | No | Medium | Developer-first |
| SAM | YAML | Via CFN | No | Low | Serverless |
| Terraform | HCL | S3+DynamoDB | Yes | Medium | Industry standard |
| Pulumi | Any language | Pulumi Cloud | Yes | Low-Medium | Dev teams |
| Ansible | YAML | Stateless | Yes | Low | Config mgmt |
| Crossplane | YAML | Kubernetes | Yes | High | Platform Eng |
| OpenTofu | HCL | S3+DynamoDB | Yes | Medium | Terraform OSS alt |

---

## Learning Resources

### Beginner
- [AWS CloudFormation Getting Started](https://docs.aws.amazon.com/cloudformation/index.html)
- [Terraform AWS Tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- [AWS CDK Workshop](https://cdkworkshop.com/)

### Intermediate
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS CDK Best Practices](https://docs.aws.amazon.com/cdk/v2/guide/best-practices.html)
- [Gruntwork Terragrunt Guide](https://terragrunt.gruntwork.io/docs/)

### Advanced
- [Terraform Enterprise Patterns](https://developer.hashicorp.com/terraform/cloud-docs)
- [CDK Advanced Workshop](https://catalog.workshops.aws/cdkworkshop/en-US)
- [Crossplane Composition Guide](https://docs.crossplane.io/latest/concepts/compositions/)

### Community
- [r/Terraform](https://www.reddit.com/r/Terraform/)
- [AWS re:Post](https://repost.aws/)
- [CNCF Slack #crossplane](https://slack.cncf.io/)
- [HashiCorp Discuss](https://discuss.hashicorp.com/)
