provider "azuread" {}

provider "google" {}

data "google_project" "kubecon_demo" {
    project_id = "dronenb-kubecon-2024-demo"
}

data "azuread_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

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