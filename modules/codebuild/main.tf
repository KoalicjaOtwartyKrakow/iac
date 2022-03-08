locals {
  frontend_bucket_name = "${var.project}-codebuild-fronted-logs"
}

resource "google_storage_bucket" "log-bucket" {
  name = local.frontend_bucket_name
  location = var.location
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