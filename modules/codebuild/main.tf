locals {
  frontend_bucket_name = "${var.project}-codebuild-fronted-logs"
  backend_bucket_name  = "${var.project}-codebuild-backend-logs"
}

module "fronted_log_bucket" {
  source   = "./logbucket"
  name     = local.frontend_bucket_name
  location = var.location
}

module "backend_log_bucket" {
  source   = "./logbucket"
  name     = local.backend_bucket_name
  location = var.location
}