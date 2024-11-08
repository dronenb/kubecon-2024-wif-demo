resource "google_secret_manager_secret" "example" {
  project                   = data.google_project.kubecon_demo.project_id
  secret_id = "example-gcp-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "example" {
  secret      = google_secret_manager_secret.example.id
  secret_data = "secret-from-gcp"
}

resource "google_secret_manager_secret_iam_member" "member" {
  project   = google_secret_manager_secret.example.project
  secret_id = google_secret_manager_secret.example.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "principal://iam.googleapis.com/projects/${data.google_project.kubecon_demo.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.kubecon_demo.workload_identity_pool_id}/subject/system:serviceaccount:default:default"
}