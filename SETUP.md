# Cloud PAM Setup Guide

This guide will help you set up the Cloud PAM system for your environment.

## Prerequisites

- GitHub repository with Actions enabled
- Admin access to AWS, Azure, and/or GCP
- Terraform installed locally
- AWS CLI, Azure CLI, or gcloud SDK (depending on cloud provider)

## Step 1: Clone and Configure Repository

1. Push this code to your GitHub repository
2. Update the following placeholders in the workflow files:

### AWS Workflows
- `.github/workflows/aws-pam-request.yml`
- `.github/workflows/aws-pam-revoke.yml`

Replace:
- `GRANTS_BUCKET`: Your S3 bucket name (e.g., `your-org-pam-grants`)
- `AWS_MANAGEMENT_ACCOUNT_ID`: Your AWS management account ID
- `AWS_TERRAFORM_ROLE_ARN`: ARN of your Terraform execution role

### Azure Workflows
- `.github/workflows/azure-pam-request.yml`
- `.github/workflows/azure-pam-revoke.yml`

Replace:
- `AZURE_CLIENT_ID`: Your Azure AD application client ID
- `AZURE_TENANT_ID`: Your Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

### GCP Workflows
- `.github/workflows/gcp-pam-request.yml`

**Note**: GCP uses its built-in Privileged Access Manager (PAM) for automatic time-based revocation, so no separate revoke workflow is needed.

Replace:
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: Your workload identity provider
- `GCP_SERVICE_ACCOUNT`: Your service account email

## Step 2: Deploy Terraform Infrastructure

### AWS

```bash
cd terraform/aws

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region         = "us-east-1"
environment        = "prod"
sso_instance_arn   = "arn:aws:sso:::instance/YOUR_INSTANCE_ID"
grants_bucket_name = "your-org-pam-grants"
EOF

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

Update `terraform/aws/main.tf` line with your GitHub repository:
```hcl
"token.actions.githubusercontent.com:sub" = "repo:YOUR_ORG/cloud-pam:*"
```

### Azure

```bash
cd terraform/azure

# Login to Azure
az login

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
environment     = "prod"
EOF

# Review and apply
terraform plan
terraform apply
```

Update `terraform/azure/main.tf` with your GitHub repository.

### GCP

```bash
cd terraform/gcp

# Authenticate
gcloud auth application-default login

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id      = "your-gcp-project"
region          = "us-central1"
environment     = "prod"
github_repository = "YOUR_ORG/cloud-pam"
EOF

# Review and apply
terraform plan
terraform apply
```

## Step 3: Configure GitHub Secrets and Variables

### Secrets (Settings → Secrets and variables → Actions)

**For AWS:**
- No secrets needed (uses OIDC)

**For Azure:**
- No secrets needed (uses OIDC)

**For GCP:**
- No secrets needed (uses Workload Identity)

### Variables

Create a repository variable:
- `PAM_APPROVER_TEAM`: GitHub team or usernames for approvals (e.g., `@security-team`)

## Step 4: Set Up OIDC Federation

### AWS

The Terraform configuration creates the IAM role. Ensure GitHub OIDC provider exists:

```bash
aws iam list-open-id-connect-providers
```

If not present, create it:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

### Azure

Federated credentials are created by Terraform. Verify:

```bash
az ad app federated-credential list --id <application-id>
```

### GCP

Workload Identity is configured by Terraform. Verify:

```bash
gcloud iam workload-identity-pools list --location=global
```

## Step 5: Test the Workflows

1. Go to Actions tab in your GitHub repository
2. Select "AWS PAM - Access Request" (or Azure/GCP)
3. Click "Run workflow"
4. Fill in the required information
5. Approve the request when the issue is created
6. Verify access is granted

## Step 6: Verify Auto-Revocation

**AWS and Azure**: The auto-revoke workflows run every 30 minutes. To test manually:

1. Create a grant with a short duration (30mins)
2. Wait for expiration
3. Manually trigger the auto-revoke workflow
4. Verify the grant is removed

**GCP**: Auto-revocation is handled natively by GCP's Privileged Access Manager. Verify in the GCP Console under IAM → Privileged Access.

## Customization

### Adding Custom Permission Sets (AWS)

Edit `terraform/aws/variables.tf` and add to the `permission_sets` map:

```hcl
"PAM-AWS-CustomRole" = {
  description      = "Custom role description"
  session_duration = "PT4H"
  managed_policies = ["arn:aws:iam::aws:policy/YourPolicy"]
  inline_policy    = null
}
```

Then run `terraform apply` and update the workflow file to include the new option.

### Adding Custom Roles (Azure)

Edit `terraform/azure/variables.tf` and add to the `custom_roles` map.

### Adding Custom Roles (GCP)

Edit `terraform/gcp/variables.tf` and add to the `custom_roles` map.

## Monitoring and Audit

### AWS
- Check S3 bucket: `s3://your-bucket/aws-grants/`
- CloudTrail logs for IAM Identity Center events

### Azure
- Check storage account container: `azure-grants`
- Log Analytics workspace for activity logs

### GCP
- Check GCS bucket: `gs://project-id-pam-grants/` (audit trail only)
- **Built-in PAM**: IAM conditions automatically expire access grants
- Cloud Logging for audit trail
- GCP Console: IAM → Policy Troubleshooter to view active conditional bindings
- **Note**: Unlike AWS/Azure, GCP uses native IAM conditional bindings for time-based access, eliminating the need for custom revocation workflows

## Troubleshooting

### "Permission denied" errors
- Verify OIDC federation is configured correctly
- Check service account/role permissions
- Ensure GitHub Actions has correct environment variables

### "User not found" errors
- Verify user email matches the identity provider
- Check user exists in AWS Identity Center / Azure AD / GCP

### Auto-revoke not working
- **AWS/Azure**: Check scheduled workflow is enabled
- **AWS/Azure**: Verify grant files exist in storage
- **AWS/Azure**: Check workflow logs for errors
- **GCP**: Verify IAM conditional binding was created correctly
- **GCP**: Check IAM policy with: `gcloud projects get-iam-policy PROJECT_ID --format=json`

## Security Best Practices

1. **Limit approval team**: Only trusted individuals should be in `PAM_APPROVER_TEAM`
2. **Short durations**: Encourage 1-4 hour grants, avoid extended durations
3. **Regular audits**: Review grant logs monthly
4. **Principle of least privilege**: Only grant minimum required permissions
5. **Monitor failed revocations**: Set up alerts for revocation failures

## Support

For issues or questions:
1. Check GitHub Actions logs
2. Review Terraform state
3. Verify cloud provider permissions
4. Check this repository's Issues tab
