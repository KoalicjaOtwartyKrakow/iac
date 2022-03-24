locals {
  cloud_build_roles = [
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/storage.admin",
    "roles/storage.objectAdmin",
    "roles/cloudfunctions.admin",
    "roles/cloudsql.client",
    # TODO(mlazowik): look into making this more granular (access only to specific secrets)
    "roles/secretmanager.secretAccessor",
  ]
}

data "google_project" "project" {}

resource "google_service_account" "cloudbuild_service_account" {
  account_id = "cloud-build-account"
}

resource "google_project_iam_member" "roles" {
  for_each = toset(local.cloud_build_roles)
  project  = data.google_project.project.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

module "codebuild_frontend" {
  source          = "./frontend"
  gcp_project     = var.gcp_project
  region          = var.region
  service_account = google_service_account.cloudbuild_service_account.id

  sentry_creds_path = var.sentry_creds_path

  github_repo_owner           = var.github_repo_owner
  frontend_github_repo_name   = var.frontend_github_repo_name
  frontend_github_repo_branch = var.frontend_github_repo_branch
  frontend_build_bucket_url   = var.frontend_build_bucket_url

  env_type      = var.env_type
  gsi_client_id = var.gsi_client_id
}

module "codebuild_backend" {
  source          = "./backend"
  gcp_project     = var.gcp_project
  region          = var.region
  service_account = google_service_account.cloudbuild_service_account.id

  github_repo_owner          = var.github_repo_owner
  backend_github_repo_name   = var.backend_github_repo_name
  backend_github_repo_branch = var.backend_github_repo_branch
}

# We can't have multiple builds of the same type running, especially backend. Trying to deploy a function that is
# already being deployed fails the build. Unfortunately cloud build does not support such functionality.
#
# As a workaround, we limit the number of concurrent builds across all build types to 1. We only have two build types
# per project, so this should not hurt that much.
#
# https://stackoverflow.com/a/63120998
resource "google_service_usage_consumer_quota_override" "cloud-build-1-build-at-a-time" {
  provider       = google-beta
  project        = var.gcp_project
  service        = "cloudbuild.googleapis.com"
  metric         = urlencode("cloudbuild.googleapis.com/ongoing_builds")
  limit          = urlencode("/project")
  override_value = "1"
  force          = true
}
