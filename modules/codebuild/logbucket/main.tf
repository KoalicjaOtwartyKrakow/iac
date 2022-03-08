resource "google_storage_bucket" "log-bucket" {
  name                        = var.name
  location                    = var.location
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}
