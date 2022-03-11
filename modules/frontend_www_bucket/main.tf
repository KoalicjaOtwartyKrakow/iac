locals {
  frontend_bucket_name = "${var.gcp_project}-www-fronted"
}

resource "google_storage_bucket" "bucket" {
  name     = local.frontend_bucket_name
  location = var.location

  website {
    main_page_suffix = var.main_page_suffix
    not_found_page   = var.main_page_suffix
  }
}

resource "google_storage_bucket_access_control" "public_rule" {
  bucket = google_storage_bucket.bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_default_object_access_control" "public_rule" {
  bucket = google_storage_bucket.bucket.name
  role   = "READER"
  entity = "allUsers"
}
