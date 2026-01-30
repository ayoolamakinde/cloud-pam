# Cloud PAM

A centralized Privileged Access Management (PAM) system for requesting just-in-time privilege access across AWS, Azure, and GCP.

## Features

- **Multi-Cloud Support**: Manage privileged access across AWS, Azure, and GCP from a single platform
- **Just-In-Time Access**: Request temporary elevated privileges with configurable durations
- **Auto-Revocation**: Automatically revoke access when grants expire
- **Approval Workflow**: Built-in approval process via GitHub Issues
- **Infrastructure as Code**: Terraform configurations for managing permission sets, roles, and entitlements

## Supported Cloud Providers

### AWS
- IAM Identity Center permission sets
- Account-level access grants
- Automated revocation via scheduled workflows

### Azure
- Azure RBAC role assignments
- Subscription-level access grants
- Automated revocation via scheduled workflows

### GCP
- IAM role bindings via GCP's Privileged Access Manager (PAM)
- Project-level access grants with built-in time-based restrictions
- Automated revocation via GCP's native PAM (no separate workflow needed)
- **Note**: GCP PAM can also be requested directly from the Cloud Console, but this workflow ensures consistency across all cloud providers

## Project Structure

```
cloud-pam/
├── .github/workflows/       # GitHub Actions workflows for PAM
│   ├── aws-pam-request.yml
│   ├── aws-pam-revoke.yml
│   ├── azure-pam-request.yml
│   ├── azure-pam-revoke.yml
│   └── gcp-pam-request.yml  # GCP uses built-in PAM for auto-revoke
└── terraform/               # IaC for cloud resources
    ├── aws/                 # AWS permission sets and roles
    ├── azure/               # Azure RBAC roles
    └── gcp/                 # GCP IAM roles
```

## Usage

### Requesting Access

1. Navigate to the Actions tab in your GitHub repository
2. Select the appropriate workflow:
   - `AWS PAM - Access Request`
   - `Azure PAM - Access Request`
   - `GCP PAM - Access Request`
3. Click "Run workflow" and fill in:
   - Permission set/role
   - Account/Subscription/Project
   - Duration (30mins - 4hrs recommended)
   - Justification
4. Wait for approval (if required)
5. Access will be automatically granted and revoked after the duration expires

### Auto-Revocation

Scheduled workflows run every 30 minutes to automatically revoke expired access grants for AWS and Azure. No manual intervention required.

**GCP**: Uses Google Cloud's built-in Privileged Access Manager which handles time-based grant expiration automatically.

## Prerequisites

- GitHub repository with Actions enabled
- Cloud provider credentials configured as GitHub secrets
- S3 bucket (or equivalent) for storing grant metadata
- Terraform for infrastructure provisioning

## Setup

1. Clone this repository
2. Configure cloud provider credentials in GitHub secrets
3. Deploy Terraform configurations for each cloud provider
4. Update workflow files with your specific account/subscription/project IDs
5. Enable GitHub Actions workflows

## Security

- All access grants are temporary with automatic expiration
- Grant metadata is stored securely in cloud storage
- Audit trail maintained via GitHub Actions logs
- Approval workflow ensures proper authorization
