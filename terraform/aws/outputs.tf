output "permission_set_arns" {
  description = "ARNs of created permission sets"
  value = {
    for k, v in aws_ssoadmin_permission_set.pam_permission_sets : k => v.arn
  }
}

output "grants_bucket_name" {
  description = "Name of the S3 bucket storing PAM grants"
  value       = aws_s3_bucket.pam_grants.id
}

output "grants_bucket_arn" {
  description = "ARN of the S3 bucket storing PAM grants"
  value       = aws_s3_bucket.pam_grants.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions_pam.arn
}

output "dynamodb_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
