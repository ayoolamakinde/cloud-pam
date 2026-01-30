output "resource_group_name" {
  description = "Name of the PAM resource group"
  value       = azurerm_resource_group.pam.name
}

output "custom_role_ids" {
  description = "IDs of custom RBAC roles"
  value = {
    for k, v in azurerm_role_definition.pam_custom_roles : k => v.id
  }
}

output "service_principal_client_id" {
  description = "Client ID of the GitHub Actions service principal"
  value       = azuread_service_principal.github_pam.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the GitHub Actions service principal"
  value       = azuread_service_principal.github_pam.object_id
}

output "storage_account_name" {
  description = "Name of the storage account for PAM logs"
  value       = azurerm_storage_account.pam_logs.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.pam.id
}
