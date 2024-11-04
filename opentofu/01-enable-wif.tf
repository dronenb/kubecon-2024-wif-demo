resource "google_storage_bucket" "kubecon_demo" {
  project                     = data.google_project.kubecon_demo.project_id
  name                        = "dronenb-kubecon-2024-demo"
  location                    = "US"
  force_destroy               = true
  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "kubecon_demo" {
  bucket = google_storage_bucket.kubecon_demo.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
