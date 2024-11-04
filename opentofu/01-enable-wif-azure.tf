# Azure AD app registration
resource "azuread_application" "kubecon_demo" {
  display_name = "dronenb-kubecon-2024-demo"
  owners       = [data.azuread_client_config.current.object_id]
  api {
    requested_access_token_version = 2
  }
}
# Create a service principal
resource "azuread_service_principal" "kubecon_demo" {
  client_id = azuread_application.kubecon_demo.client_id
  owners    = [data.azuread_client_config.current.object_id]
}
# Create federated credential
resource "azuread_application_federated_identity_credential" "kubecon_demo" {
  application_id = azuread_application.kubecon_demo.id
  display_name   = "minikube"
  description    = "minikube"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "system:serviceaccount:default:default"
  issuer         = "https://storage.googleapis.com/dronenb-kubecon-2024-demo"
}
