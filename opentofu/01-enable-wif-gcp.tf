resource "google_iam_workload_identity_pool" "kubecon_demo" {
  project                   = data.google_project.kubecon_demo.project_id
  workload_identity_pool_id = "dronenb-kubecon-2024-demo"
  display_name              = "dronenb-kubecon-2024-demo"
  description               = "Created By TF"
}

resource "google_iam_workload_identity_pool_provider" "kubecon_demo" {
  project = data.google_project.kubecon_demo.project_id
  display_name                       = "kubecon-2024-demo"
  description                        = "Created By TF"
  workload_identity_pool_id          = google_iam_workload_identity_pool.kubecon_demo.workload_identity_pool_id
  workload_identity_pool_provider_id = "kubecon-2024-demo"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    issuer_uri        = "https://storage.googleapis.com/dronenb-kubecon-2024-demo"
    allowed_audiences = [
      "//iam.googleapis.com/projects/${data.google_project.kubecon_demo.number}/locations/global/workloadIdentityPools/dronenb-kubecon-2024-demo/providers/kubecon-2024-demo",
    ]
  }
}
