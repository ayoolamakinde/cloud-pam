output "custom_role_ids" {
  description = "IDs of custom IAM roles"
  value = {
    for k, v in google_project_iam_custom_role.pam_custom_roles : k => v.id
  }
}

output "service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_pam.email
}

output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "grants_bucket_name" {
  description = "Name of the GCS bucket for PAM grants"
  value       = google_storage_bucket.pam_grants.name
}

output "grants_bucket_url" {
  description = "URL of the GCS bucket for PAM grants"
  value       = google_storage_bucket.pam_grants.url
}

output "pam_events_topic" {
  description = "Pub/Sub topic for PAM events"
  value       = google_pubsub_topic.pam_events.id
}

output "project_number" {
  description = "GCP project number"
  value       = data.google_project.current.number
}
