variable "project_id" {
  description = "GCP project ID for PAM management"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "organization_id" {
  description = "GCP organization ID (optional, for org-level roles)"
  type        = string
  default     = ""
}

variable "custom_roles" {
  description = "Custom IAM roles for PAM"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = string
  }))
  default = {
    "pamTemporaryAdmin" = {
      title       = "PAM Temporary Administrator"
      description = "Temporary elevated access for specific operations"
      permissions = [
        "compute.instances.get",
        "compute.instances.list",
        "compute.instances.start",
        "compute.instances.stop",
        "storage.buckets.get",
        "storage.buckets.list",
        "storage.objects.get",
        "storage.objects.list"
      ]
      stage = "GA"
    }
  }
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "YOUR_GITHUB_ORG/cloud-pam"  # Update with your repo
}
