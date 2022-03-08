locals {
  frontend_bucket_name = "${var.project}-codebuild-fronted-logs"
}

moved {
  from = google_storage_bucket.log-bucket
  to   = module.fronted_log_bucket.google_storage_bucket.log-bucket
}

module "fronted_log_bucket" {
  source   = "./logbucket"
  name     = local.frontend_bucket_name
  location = var.location
}