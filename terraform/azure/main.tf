# Resource group for PAM resources
resource "azurerm_resource_group" "pam" {
  name     = var.pam_resource_group_name
  location = var.location

  tags = {
    Project     = "cloud-pam"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# Custom RBAC roles for PAM
resource "azurerm_role_definition" "pam_custom_roles" {
  for_each = var.custom_roles

  name        = each.key
  scope       = "/subscriptions/${var.subscription_id}"
  description = each.value.description

  permissions {
    actions     = each.value.actions
    not_actions = each.value.not_actions
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}"
  ]
}

# Service principal for GitHub Actions PAM automation
resource "azuread_application" "github_pam" {
  display_name = "cloud-pam-github-actions"

  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "github_pam" {
  client_id = azuread_application.github_pam.client_id
  owners    = [data.azuread_client_config.current.object_id]

  tags = ["cloud-pam", "automation", "github-actions"]
}

# Create federated identity credential for GitHub Actions OIDC
resource "azuread_application_federated_identity_credential" "github_pam" {
  application_id = azuread_application.github_pam.id
  display_name   = "github-actions-cloud-pam"
  description    = "GitHub Actions federated credential for Cloud PAM"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:YOUR_GITHUB_ORG/cloud-pam:ref:refs/heads/main"  # Update with your repo
}

# Assign necessary permissions to the service principal
resource "azurerm_role_assignment" "github_pam_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.github_pam.object_id
}

resource "azurerm_role_assignment" "github_pam_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_pam.object_id
}

# Storage account for PAM audit logs (alternative to S3)
resource "azurerm_storage_account" "pam_logs" {
  name                     = "cloudpamlogs${var.environment}"
  resource_group_name      = azurerm_resource_group.pam.name
  location                 = azurerm_resource_group.pam.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 90
    }
  }

  tags = {
    Name    = "Cloud PAM Logs"
    Purpose = "Audit logging for privilege grants"
  }
}

# Container for storing grant metadata
resource "azurerm_storage_container" "azure_grants" {
  name                  = "azure-grants"
  storage_account_name  = azurerm_storage_account.pam_logs.name
  container_access_type = "private"
}

# Log Analytics workspace for monitoring
resource "azurerm_log_analytics_workspace" "pam" {
  name                = "cloud-pam-logs-${var.environment}"
  location            = azurerm_resource_group.pam.location
  resource_group_name = azurerm_resource_group.pam.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Name    = "Cloud PAM Monitoring"
    Purpose = "Monitor and audit PAM activities"
  }
}

data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}
