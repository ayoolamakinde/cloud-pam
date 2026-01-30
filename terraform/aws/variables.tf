variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "sso_instance_arn" {
  description = "ARN of the AWS IAM Identity Center instance"
  type        = string
}

variable "permission_sets" {
  description = "Map of permission sets to create"
  type = map(object({
    description      = string
    session_duration = string
    managed_policies = list(string)
    inline_policy    = optional(string)
  }))
  default = {
    "PAM-AWS-AdministratorAccess" = {
      description      = "Full administrator access for temporary use"
      session_duration = "PT4H"  # 4 hours
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy    = null
    }
    "PAM-AWS-EKSAdmin" = {
      description      = "EKS cluster administration access"
      session_duration = "PT4H"
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
      ]
      inline_policy = null
    }
    "PAM-AWS-S3FullAccess" = {
      description      = "Full S3 access for data operations"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
      inline_policy    = null
    }
    "PAM-AWS-SecurityAudit" = {
      description      = "Security auditing and review access"
      session_duration = "PT8H"  # 8 hours for audit work
      managed_policies = [
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      inline_policy = null
    }
    "PAM-AWS-ReadOnlyAccess" = {
      description      = "Read-only access across all services"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy    = null
    }
  }
}

variable "grants_bucket_name" {
  description = "Name of the S3 bucket for storing PAM grants"
  type        = string
  default     = "cloud-pam-grants"
}
