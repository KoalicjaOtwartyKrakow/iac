module "lb" {
  source = "../modules/lb"
  frontend_bucket_name = module.frontend_www_bucket.name
}

module "frontend_www_bucket" {
  source      = "../modules/frontend_www_bucket"
  location    = var.region
  gcp_project = var.gcp_project
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
}

module "db" {
  source = "../modules/db"

  tier                   = var.db_tier
  availability_type      = var.db_availability_type
  retained_backups_count = var.db_retained_backups_count
}
