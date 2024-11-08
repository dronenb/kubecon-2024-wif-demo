# Provider configs
provider "azuread" {}
provider "azurerm" {
  features {}
  subscription_id = "b41dccda-b4bc-4e0b-bfcb-8d220fb7a6a0"
}
provider "google" {}

data "google_project" "kubecon_demo" {
    project_id = "dronenb-kubecon-2024-demo"
}

# So we can refer to ourselves and establish ownership of SP's
data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}

# So we can lookup app ID's + permissions by name instead of by UUID
data "azuread_application_published_app_ids" "well_known" {}
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

# Resource group
resource "azurerm_resource_group" "kubecon_demo" {
  name     = "dronenb-kubecon-2024-demo"
  location = "North Central US"
}

# All the Google API's we're using for the demo
resource "google_project_service" "cloud_resource_api" {
  project            = data.google_project.kubecon_demo.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project            = data.google_project.kubecon_demo.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_api" {
  project            = data.google_project.kubecon_demo.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}