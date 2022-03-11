data "google_project" "project" {}

resource "google_service_account" "cloudbuild_service_account" {
  account_id = "cloud-build-account"
}

resource "google_project_iam_member" "act_as" {
  project = data.google_project.project.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_project_iam_member" "logs_writer" {
  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

module "codebuild_frontend" {
  source          = "./frontend"
  gcp_project     = var.gcp_project
  region          = var.region
  service_account = google_service_account.cloudbuild_service_account.id

  github_repo_owner           = var.github_repo_owner
  frontend_github_repo_name   = var.frontend_github_repo_name
  frontend_github_repo_branch = var.frontend_github_repo_branch
  frontend_build_bucket_url   = var.frontend_build_bucket_url
}

module "codebuild_backend" {
  source          = "./backend"
  gcp_project     = var.gcp_project
  region          = var.region
  service_account = google_service_account.cloudbuild_service_account.id

  github_repo_owner          = var.github_repo_owner
  backend_github_repo_name   = var.backend_github_repo_name
  backend_github_repo_branch = var.backend_github_repo_branch
  backend_cloudfunction_name = var.backend_cloudfunction_name
}