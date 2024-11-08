resource "azurerm_key_vault" "kubecon_demo" {
  name                        = "kubecon-2024-demo"
  location                    = azurerm_resource_group.kubecon_demo.location
  resource_group_name         = azurerm_resource_group.kubecon_demo.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}

resource "azurerm_key_vault_secret" "example" {
  name         = "example-azure-secret"
  value        = "secret-from-azure"
  key_vault_id = azurerm_key_vault.kubecon_demo.id
}

# So we can write this secret
resource "azurerm_key_vault_access_policy" "local" {
  key_vault_id = azurerm_key_vault.kubecon_demo.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "minikube" {
  key_vault_id = azurerm_key_vault.kubecon_demo.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.kubecon_demo.object_id

  secret_permissions = [
    "Get",
  ]
}
