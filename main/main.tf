module "frontend_www_bucket" {
  source      = "../modules/frontend_www_bucket"
  location    = var.region
  gcp_project = var.gcp_project
}

moved {
  from = module.codebuild
  to   = module.codebuild_frontend
}
module "codebuild_frontend" {
  source      = "../modules/codebuild/frontend"
  gcp_project = var.gcp_project
  region      = var.region

  github_repo_owner           = var.github_repo_owner
  frontend_github_repo_name   = var.frontend_github_repo_name
  frontend_github_repo_branch = var.frontend_github_repo_branch
  frontend_build_bucket_url   = module.frontend_www_bucket.url
}