# Custom IAM roles
resource "google_project_iam_custom_role" "pam_custom_roles" {
  for_each = var.custom_roles

  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
  project     = var.project_id
}

# Service account for GitHub Actions PAM automation
resource "google_service_account" "github_pam" {
  account_id   = "cloud-pam-github-actions"
  display_name = "Cloud PAM GitHub Actions"
  description  = "Service account for GitHub Actions to manage PAM"
  project      = var.project_id
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "github_pam_roles" {
  for_each = toset([
    "roles/iam.securityAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountUser"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_pam.email}"
}

# Workload Identity Pool for GitHub Actions OIDC
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  project                   = var.project_id
}

# Workload Identity Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions to impersonate the service account
resource "google_service_account_iam_member" "github_workload_identity" {
  service_account_id = google_service_account.github_pam.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# GCS bucket for storing grant metadata (alternative to S3)
resource "google_storage_bucket" "pam_grants" {
  name          = "${var.project_id}-pam-grants"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90  # Keep grant records for 90 days
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    project     = "cloud-pam"
    managed_by  = "terraform"
    environment = var.environment
  }
}

# Grant service account access to the bucket
resource "google_storage_bucket_iam_member" "github_pam_bucket_access" {
  bucket = google_storage_bucket.pam_grants.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_pam.email}"
}

# Pub/Sub topic for PAM events (optional - for monitoring/alerting)
resource "google_pubsub_topic" "pam_events" {
  name    = "cloud-pam-events"
  project = var.project_id

  labels = {
    project    = "cloud-pam"
    managed_by = "terraform"
  }
}

# Cloud Logging sink for PAM audit trail
resource "google_logging_project_sink" "pam_audit" {
  name    = "cloud-pam-audit-sink"
  project = var.project_id

  destination = "pubsub.googleapis.com/${google_pubsub_topic.pam_events.id}"

  filter = <<-EOT
    resource.type="project"
    protoPayload.methodName=~"SetIamPolicy"
    protoPayload.serviceName="iam.googleapis.com"
  EOT

  unique_writer_identity = true
}

# Grant Pub/Sub publisher role to the sink
resource "google_pubsub_topic_iam_member" "pam_audit_publisher" {
  topic  = google_pubsub_topic.pam_events.name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.pam_audit.writer_identity
}

data "google_project" "current" {
  project_id = var.project_id
}
