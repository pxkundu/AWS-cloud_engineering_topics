# Infrastructure as Code (IaC) — Master Reference

A comprehensive resource covering IaC tools, patterns, and industry projects across the three major cloud providers: AWS, Azure, and GCP.

## Structure

```
Infra-as-code/
├── AWS/
│   ├── README.md          # AWS IaC tools overview
│   ├── PROJECTS.md        # 3 industry projects with full codebase
│   └── tools/             # Tool-specific examples
├── Azure/
│   ├── README.md
│   ├── PROJECTS.md
│   └── tools/
└── GCP/
    ├── README.md
    ├── PROJECTS.md
    └── tools/
```

## What is IaC?

Infrastructure as Code is the practice of managing and provisioning infrastructure through machine-readable configuration files rather than manual processes. It enables:

- Version-controlled infrastructure
- Repeatable, consistent environments
- Automated provisioning and teardown
- Drift detection and remediation
- Collaboration via pull requests

## IaC Categories

| Category | Description | Examples |
|----------|-------------|---------|
| Declarative | Define desired state | Terraform, CloudFormation, Pulumi |
| Imperative | Define steps to reach state | Ansible, Chef, Puppet |
| Cloud-native | Provider-specific | CloudFormation, ARM, Deployment Manager |
| Multi-cloud | Provider-agnostic | Terraform, Pulumi, Crossplane |
| GitOps | Git as source of truth | ArgoCD, Flux, Atlantis |

## Learning Path

```
Beginner → Intermediate → Advanced
   │              │             │
   ▼              ▼             ▼
Single         Multi-env    Multi-cloud
resource       modules      GitOps + CI/CD
```

## References

- [IaC on Wikipedia](https://en.wikipedia.org/wiki/Infrastructure_as_code)
- [ThoughtWorks IaC Guide](https://www.thoughtworks.com/insights/blog/infrastructure-code-reason-smile)
- [CNCF Landscape](https://landscape.cncf.io/)
- [HashiCorp Learn](https://developer.hashicorp.com/terraform/tutorials)
