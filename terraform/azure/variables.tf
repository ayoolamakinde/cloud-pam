variable "subscription_id" {
  description = "Azure subscription ID for PAM management"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "custom_roles" {
  description = "Custom Azure RBAC roles for PAM"
  type = map(object({
    description = string
    actions     = list(string)
    not_actions = list(string)
  }))
  default = {
    "PAM-Azure-TemporaryAdmin" = {
      description = "Temporary administrative access with specific limitations"
      actions = [
        "*/read",
        "Microsoft.Resources/subscriptions/resourceGroups/*",
        "Microsoft.Compute/virtualMachines/*",
        "Microsoft.Storage/storageAccounts/*"
      ]
      not_actions = [
        "Microsoft.Authorization/*/Delete",
        "Microsoft.Authorization/*/Write"
      ]
    }
  }
}

variable "pam_resource_group_name" {
  description = "Resource group name for PAM resources"
  type        = string
  default     = "cloud-pam-rg"
}
