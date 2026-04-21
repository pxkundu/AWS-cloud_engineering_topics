# Azure Infrastructure as Code — Complete Reference

## Azure-Native IaC Tools

### 1. ARM Templates (Azure Resource Manager)
Azure's native JSON-based IaC. Every Azure resource is backed by ARM.

- **Type:** Declarative, Cloud-native
- **Language:** JSON
- **State Management:** Azure-managed
- **Best For:** Azure-only, deep integration with Azure Policy

```json
// arm/storage-account.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": { "type": "string" },
    "location": { "type": "string", "defaultValue": "[resourceGroup().location]" }
  },
  "resources": [{
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2023-01-01",
    "name": "[parameters('storageAccountName')]",
    "location": "[parameters('location')]",
    "sku": { "name": "Standard_LRS" },
    "kind": "StorageV2",
    "properties": {
      "supportsHttpsTrafficOnly": true,
      "minimumTlsVersion": "TLS1_2",
      "allowBlobPublicAccess": false
    }
  }]
}
```

**References:**
- [ARM Template Docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/)
- [ARM Quickstart Templates GitHub](https://github.com/Azure/azure-quickstart-templates)
- [ARM Template Viewer](https://github.com/benc-uk/armview-vscode)

---

### 2. Bicep
Microsoft's DSL that compiles to ARM. Much cleaner syntax than raw JSON ARM templates.

- **Type:** Declarative, Cloud-native
- **Language:** Bicep DSL
- **State Management:** Azure-managed
- **Best For:** Azure teams wanting ARM power with readable syntax

```bicep
// bicep/storage.bicep
@description('Storage account name')
param storageAccountName string

@description('Location')
param location string = resourceGroup().location

@allowed(['Standard_LRS', 'Standard_GRS', 'Premium_LRS'])
param skuName string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    encryption: {
      services: {
        blob: { enabled: true }
        file: { enabled: true }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

output storageAccountId string = storageAccount.id
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
```

**References:**
- [Bicep Docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Bicep GitHub](https://github.com/Azure/bicep)
- [Bicep Registry](https://github.com/Azure/bicep-registry-modules)
- [Bicep Playground](https://aka.ms/bicepdemo)

---

### 3. Azure Developer CLI (azd)
End-to-end developer tool for provisioning + deploying Azure apps. Uses Bicep under the hood.

- **Type:** Declarative + workflow
- **Language:** Bicep + YAML
- **Best For:** Full app lifecycle (infra + code deployment together)

```yaml
# azure.yaml (azd project definition)
name: my-app
services:
  api:
    project: ./src/api
    language: python
    host: containerapp
  web:
    project: ./src/web
    language: js
    host: staticwebapp
infra:
  provider: bicep
  path: infra
```

**References:**
- [Azure Developer CLI Docs](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [azd GitHub](https://github.com/Azure/azure-dev)
- [azd Templates](https://azure.github.io/awesome-azd/)

---

## Multi-Cloud / Third-Party IaC Tools on Azure

### 4. Terraform on Azure
Same HCL workflow, Azure provider with 1000+ resources.

```hcl
# terraform/main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  use_oidc = true  # Workload Identity Federation for CI/CD
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location
  tags     = var.common_tags
}

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  resource_group_name = azurerm_resource_group.main.name
  vnet_location       = var.location
  vnet_name           = "${var.project}-vnet"
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["app-subnet", "data-subnet", "mgmt-subnet"]
}
```

**References:**
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Azure Modules](https://github.com/Azure/terraform-azurerm-modules)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)

---

### 5. Pulumi on Azure

```python
# pulumi/__main__.py
import pulumi
import pulumi_azure_native as azure

rg = azure.resources.ResourceGroup("app-rg",
    location="eastus",
    tags={"environment": "prod"}
)

storage = azure.storage.StorageAccount("appstorage",
    resource_group_name=rg.name,
    location=rg.location,
    sku=azure.storage.SkuArgs(name="Standard_LRS"),
    kind="StorageV2",
    enable_https_traffic_only=True,
    minimum_tls_version="TLS1_2"
)

pulumi.export("storage_account_name", storage.name)
```

**References:**
- [Pulumi Azure Native Provider](https://www.pulumi.com/registry/packages/azure-native/)
- [Pulumi Azure Examples](https://github.com/pulumi/examples/tree/master/azure)

---

### 6. Ansible on Azure

```yaml
# ansible/playbooks/azure-vm.yml
---
- name: Provision Azure VM
  hosts: localhost
  tasks:
    - name: Create resource group
      azure.azcollection.azure_rm_resourcegroup:
        name: "{{ resource_group }}"
        location: eastus

    - name: Create virtual network
      azure.azcollection.azure_rm_virtualnetwork:
        resource_group: "{{ resource_group }}"
        name: app-vnet
        address_prefixes: "10.0.0.0/16"

    - name: Create VM
      azure.azcollection.azure_rm_virtualmachine:
        resource_group: "{{ resource_group }}"
        name: app-vm
        vm_size: Standard_D2s_v3
        admin_username: azureuser
        ssh_password_enabled: false
        ssh_public_keys:
          - path: /home/azureuser/.ssh/authorized_keys
            key_data: "{{ ssh_public_key }}"
        image:
          offer: UbuntuServer
          publisher: Canonical
          sku: 22.04-LTS
          version: latest
```

**References:**
- [Ansible Azure Collection](https://github.com/ansible-collections/azure)
- [Ansible Azure Docs](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/)

---

## IaC Tool Comparison — Azure

| Tool | Language | State Mgmt | Multi-cloud | Best Use Case |
|------|----------|------------|-------------|---------------|
| ARM Templates | JSON | Azure-managed | No | Legacy, deep ARM integration |
| Bicep | Bicep DSL | Azure-managed | No | Modern Azure-native |
| azd | Bicep + YAML | Azure-managed | No | Full app lifecycle |
| Terraform | HCL | Azure Blob | Yes | Multi-cloud, team standard |
| Pulumi | Any language | Pulumi Cloud | Yes | Developer-first |
| Ansible | YAML | Stateless | Yes | Config management |

---

## Learning Resources

### Beginner
- [Bicep Learning Path](https://learn.microsoft.com/en-us/training/paths/fundamentals-bicep/)
- [Terraform Azure Get Started](https://developer.hashicorp.com/terraform/tutorials/azure-get-started)
- [ARM Template Tutorial](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-create-first-template)

### Intermediate
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Bicep Module Registry](https://github.com/Azure/bicep-registry-modules)
- [Terraform Azure Landing Zone](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale)

### Advanced
- [Azure Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Enterprise-Scale Architecture](https://github.com/Azure/Enterprise-Scale)
- [Azure Policy as Code](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/policy-as-code)

### Community
- [Azure Tech Community](https://techcommunity.microsoft.com/t5/azure/ct-p/Azure)
- [r/AZURE](https://www.reddit.com/r/AZURE/)
- [Azure Bicep Discussions](https://github.com/Azure/bicep/discussions)
