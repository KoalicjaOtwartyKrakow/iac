module "frontend_www_bucket" {
  source      = "../modules/frontend_www_bucket"
  location    = var.region
  gcp_project = var.gcp_project
}

moved {
  from = module.codebuild_backend.module.backend_log_bucket.google_storage_bucket.log-bucket
  to   = module.codebuild.module.codebuild_backend.module.backend_log_bucket.google_storage_bucket.log-bucket
}

moved {
  from = module.codebuild_frontend.module.fronted_log_bucket.google_storage_bucket.log-bucket
  to   = module.codebuild.module.codebuild_frontend.module.fronted_log_bucket.google_storage_bucket.log-bucket
}

module "codebuild" {
  source      = "../modules/codebuild"
  gcp_project = var.gcp_project
  region      = var.region

  github_repo_owner           = var.github_repo_owner
  frontend_github_repo_name   = var.frontend_github_repo_name
  frontend_github_repo_branch = var.frontend_github_repo_branch
  frontend_build_bucket_url   = module.frontend_www_bucket.url

  backend_github_repo_name   = var.backend_github_repo_name
  backend_github_repo_branch = var.backend_github_repo_branch
  backend_cloudfunction_name = "add_accommodation"
}

module "private-services-access" {
  source = "../modules/private-services-access"
}

module "db" {
  source = "../modules/db"

  tier                   = var.db_tier
  availability_type      = var.db_availability_type
  retained_backups_count = var.db_retained_backups_count

  # For private IP instance setup, note that the google_sql_database_instance does not actually interpolate values from
  # google_service_networking_connection. You must explicitly add a depends_on.
  #
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#private-ip-instance
  #
  # In our case we depend on the whole module that wraps private services access.
  depends_on = [module.private-services-access]
}
