# GCP Infrastructure as Code — Complete Reference

## GCP-Native IaC Tools

### 1. Google Cloud Deployment Manager
GCP's native IaC service. YAML/Python/Jinja2 templates that describe GCP resources.

- **Type:** Declarative, Cloud-native
- **Language:** YAML, Python, Jinja2
- **State Management:** GCP-managed
- **Best For:** GCP-only teams, tight GCP service integration (though Terraform is now preferred by Google itself)

```yaml
# deployment-manager/storage.yaml
resources:
  - name: my-app-bucket
    type: storage.v1.bucket
    properties:
      location: US
      storageClass: STANDARD
      versioning:
        enabled: true
      iamConfiguration:
        uniformBucketLevelAccess:
          enabled: true
      encryption:
        defaultKmsKeyName: projects/my-project/locations/us/keyRings/my-ring/cryptoKeys/my-key
```

**References:**
- [Deployment Manager Docs](https://cloud.google.com/deployment-manager/docs)
- [Deployment Manager Samples](https://github.com/GoogleCloudPlatform/deploymentmanager-samples)

---

### 2. Config Connector (KCC)
Kubernetes-native way to manage GCP resources as Kubernetes CRDs. Part of GKE.

- **Type:** Declarative (Kubernetes-native)
- **Language:** YAML (Kubernetes manifests)
- **State Management:** Kubernetes etcd
- **Best For:** GKE-centric platform teams

```yaml
# config-connector/storage-bucket.yaml
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: my-app-bucket
  namespace: config-control
  annotations:
    cnrm.cloud.google.com/project-id: my-gcp-project
spec:
  location: US
  uniformBucketLevelAccess: true
  versioning:
    enabled: true
  lifecycleRule:
    - action:
        type: Delete
      condition:
        age: 365
```

**References:**
- [Config Connector Docs](https://cloud.google.com/config-connector/docs/overview)
- [Config Connector GitHub](https://github.com/GoogleCloudPlatform/k8s-config-connector)
- [Config Connector Samples](https://github.com/GoogleCloudPlatform/k8s-config-connector/tree/master/samples)

---

### 3. Config Controller
Managed Config Connector + Policy Controller + ArgoCD/Flux on a managed GKE cluster. Google's GitOps platform.

- **Type:** GitOps, Declarative
- **Best For:** Enterprise GCP platform engineering

```bash
# Create Config Controller instance
gcloud anthos config controller create my-controller \
  --location=us-central1 \
  --full-management
```

**References:**
- [Config Controller Docs](https://cloud.google.com/anthos-config-management/docs/concepts/config-controller-overview)

---

## Multi-Cloud / Third-Party IaC Tools on GCP

### 4. Terraform on GCP
Most widely used IaC for GCP. Google maintains official modules.

- **Type:** Declarative
- **Language:** HCL
- **State Management:** GCS bucket + optional locking
- **Best For:** Multi-cloud, team environments, Google-recommended for production

```hcl
# terraform/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "my-tfstate-bucket"
    prefix = "prod/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "9.0.0"

  project_id   = var.project_id
  network_name = "${var.project}-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "app-subnet"
      subnet_ip             = "10.0.1.0/24"
      subnet_region         = var.region
      subnet_private_access = true
    },
    {
      subnet_name           = "data-subnet"
      subnet_ip             = "10.0.2.0/24"
      subnet_region         = var.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    app-subnet = [
      { range_name = "pods", ip_cidr_range = "10.1.0.0/16" },
      { range_name = "services", ip_cidr_range = "10.2.0.0/20" }
    ]
  }
}
```

**References:**
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Terraform Modules](https://github.com/terraform-google-modules)
- [GCP Terraform Blueprints](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai)

---

### 5. Pulumi on GCP

```python
# pulumi/__main__.py
import pulumi
import pulumi_gcp as gcp

config = pulumi.Config()
project = config.require("project")
region = config.get("region") or "us-central1"

# VPC Network
network = gcp.compute.Network("app-network",
    project=project,
    auto_create_subnetworks=False,
    description="Application VPC network"
)

subnet = gcp.compute.Subnetwork("app-subnet",
    project=project,
    region=region,
    network=network.id,
    ip_cidr_range="10.0.1.0/24",
    private_ip_google_access=True,
    secondary_ip_ranges=[
        gcp.compute.SubnetworkSecondaryIpRangeArgs(
            range_name="pods",
            ip_cidr_range="10.1.0.0/16"
        ),
        gcp.compute.SubnetworkSecondaryIpRangeArgs(
            range_name="services",
            ip_cidr_range="10.2.0.0/20"
        )
    ]
)

pulumi.export("network_name", network.name)
pulumi.export("subnet_name", subnet.name)
```

**References:**
- [Pulumi GCP Provider](https://www.pulumi.com/registry/packages/gcp/)
- [Pulumi GCP Examples](https://github.com/pulumi/examples/tree/master/gcp-py-gke)

---

### 6. Ansible on GCP

```yaml
# ansible/playbooks/gce-instance.yml
---
- name: Provision GCE instance
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Create GCE instance
      google.cloud.gcp_compute_instance:
        name: app-server
        machine_type: n2-standard-4
        zone: us-central1-a
        project: "{{ gcp_project }}"
        auth_kind: serviceaccount
        service_account_file: "{{ sa_key_file }}"
        disks:
          - auto_delete: true
            boot: true
            initialize_params:
              source_image: projects/debian-cloud/global/images/family/debian-12
              disk_size_gb: 50
              disk_type: pd-ssd
        network_interfaces:
          - network: "{{ network_selflink }}"
            subnetwork: "{{ subnet_selflink }}"
            access_configs: []  # No external IP
        metadata:
          startup-script: |
            #!/bin/bash
            apt-get update && apt-get install -y docker.io
        tags:
          items: [app-server, http-server]
```

**References:**
- [Ansible GCP Collection](https://github.com/ansible-collections/google.cloud)
- [Ansible GCP Docs](https://docs.ansible.com/ansible/latest/collections/google/cloud/)

---

### 7. Terragrunt on GCP
Thin wrapper around Terraform for DRY configurations and multi-environment management.

```hcl
# terragrunt/prod/gke/terragrunt.hcl
terraform {
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//modules/private-cluster?ref=v29.0.0"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  project_id         = "my-prod-project"
  name               = "prod-gke-cluster"
  region             = "us-central1"
  network            = dependency.vpc.outputs.network_name
  subnetwork         = dependency.vpc.outputs.subnets_names[0]
  ip_range_pods      = "pods"
  ip_range_services  = "services"
  enable_private_nodes = true
}
```

**References:**
- [Terragrunt Docs](https://terragrunt.gruntwork.io/)
- [Terragrunt GitHub](https://github.com/gruntwork-io/terragrunt)

---

## IaC Tool Comparison — GCP

| Tool | Language | State Mgmt | Multi-cloud | Best Use Case |
|------|----------|------------|-------------|---------------|
| Deployment Manager | YAML/Python | GCP-managed | No | Legacy GCP-native |
| Config Connector | YAML (K8s) | Kubernetes | No | GKE platform teams |
| Config Controller | YAML (K8s) | Managed | No | Enterprise GitOps |
| Terraform | HCL | GCS bucket | Yes | Industry standard |
| Pulumi | Any language | Pulumi Cloud | Yes | Developer-first |
| Ansible | YAML | Stateless | Yes | Config management |
| Terragrunt | HCL wrapper | GCS bucket | Yes | Multi-env DRY |

---

## Learning Resources

### Beginner
- [Terraform GCP Get Started](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started)
- [GCP Deployment Manager Quickstart](https://cloud.google.com/deployment-manager/docs/quickstart)
- [Config Connector Quickstart](https://cloud.google.com/config-connector/docs/how-to/getting-started)

### Intermediate
- [Google Terraform Modules](https://github.com/terraform-google-modules)
- [GCP Architecture Center](https://cloud.google.com/architecture)
- [Anthos Config Management](https://cloud.google.com/anthos/config-management)

### Advanced
- [GCP Enterprise Foundation Blueprint](https://github.com/terraform-google-modules/terraform-example-foundation)
- [GKE Enterprise Patterns](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [GCP Landing Zone Terraform](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric)

### Community
- [GCP Community GitHub](https://github.com/GoogleCloudPlatform)
- [r/googlecloud](https://www.reddit.com/r/googlecloud/)
- [GCP Slack Community](https://googlecloud-community.slack.com/)
- [Google Cloud Blog](https://cloud.google.com/blog/topics/developers-practitioners)
- [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric)
