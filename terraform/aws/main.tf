# IAM Identity Center Permission Sets
resource "aws_ssoadmin_permission_set" "pam_permission_sets" {
  for_each = var.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = var.sso_instance_arn
  session_duration = each.value.session_duration

  tags = {
    Name        = each.key
    Type        = "PAM"
    Description = each.value.description
  }
}

# Attach AWS managed policies to permission sets
resource "aws_ssoadmin_managed_policy_attachment" "pam_managed_policies" {
  for_each = {
    for pair in flatten([
      for ps_key, ps_config in var.permission_sets : [
        for policy_arn in ps_config.managed_policies : {
          ps_key     = ps_key
          policy_arn = policy_arn
          key        = "${ps_key}-${policy_arn}"
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = var.sso_instance_arn
  managed_policy_arn = each.value.policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.pam_permission_sets[each.value.ps_key].arn
}

# S3 bucket for storing PAM grant metadata
resource "aws_s3_bucket" "pam_grants" {
  bucket = var.grants_bucket_name

  tags = {
    Name    = "Cloud PAM Grants Storage"
    Purpose = "Store temporary privilege grant metadata"
  }
}

# Enable versioning on grants bucket
resource "aws_s3_bucket_versioning" "pam_grants" {
  bucket = aws_s3_bucket.pam_grants.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on grants bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "pam_grants" {
  bucket = aws_s3_bucket.pam_grants.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to grants bucket
resource "aws_s3_bucket_public_access_block" "pam_grants" {
  bucket = aws_s3_bucket.pam_grants.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to clean up old grant files
resource "aws_s3_bucket_lifecycle_configuration" "pam_grants" {
  bucket = aws_s3_bucket.pam_grants.id

  rule {
    id     = "cleanup-old-grants"
    status = "Enabled"

    expiration {
      days = 90  # Keep grant records for 90 days for audit
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# IAM role for GitHub Actions to manage PAM
resource "aws_iam_role" "github_actions_pam" {
  name        = "cloud-pam-terraform-role"
  description = "Role for GitHub Actions to manage Cloud PAM resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:YOUR_GITHUB_ORG/cloud-pam:*"  # Update with your repo
          }
        }
      }
    ]
  })

  tags = {
    Name    = "Cloud PAM GitHub Actions Role"
    Purpose = "Automation"
  }
}

# Policy for GitHub Actions role
resource "aws_iam_role_policy" "github_actions_pam_policy" {
  name = "cloud-pam-permissions"
  role = aws_iam_role.github_actions_pam.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sso-admin:*",
          "identitystore:*",
          "organizations:ListAccounts",
          "organizations:DescribeAccount"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pam_grants.arn,
          "${aws_s3_bucket.pam_grants.arn}/*"
        ]
      }
    ]
  })
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cloud-pam-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "Cloud PAM Terraform State Locks"
    Purpose = "Terraform"
  }
}

data "aws_caller_identity" "current" {}
