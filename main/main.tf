locals {
  zone_name = "zone"
}

module "terraform-sops" {
  source = "../modules/terraform-sops"
}

module "dns" {
  source = "../modules/dns"

  dns_zone_name = var.dns_zone_name
  lb_ip         = module.lb.lb_ip
}

module "lb" {
  source = "../modules/lb"

  gcp_project   = var.gcp_project
  region        = var.region
  env_type      = var.env_type
  dns_zone_name = var.dns_zone_name

  frontend_bucket_name              = module.frontend_www_bucket.name
  functions_endpoint_cloud_run_name = module.endpoints.functions_endpoint_cloud_run_name
}

module "endpoints" {
  source = "../modules/endpoints"

  gcp_project = var.gcp_project
  location    = var.region
  zone_name   = local.zone_name

  endpoints-cloud-run-domain = var.endpoints-cloud-run-domain
}

module "frontend_www_bucket" {
  source      = "../modules/frontend_www_bucket"
  location    = var.region
  gcp_project = var.gcp_project

  frontend_creds_path = var.frontend_creds_path
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
  db_creds_path          = var.db_creds_path
}

module "iam" {
  source = "../modules/iam"

  devs_group_email = var.devs_group_email
}