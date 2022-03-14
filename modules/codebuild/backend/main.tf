locals {
  backend_codebuild_name = "${var.gcp_project}-build-backend"
  backend_bucket_name    = "${var.gcp_project}-codebuild-backend-logs"

  project_id = data.google_project.project.project_id
  cloud_functions = toset([
    "get_all_accommodations",
    "add_accommodation",
    "create_host",
    "get_all_guests",
    "add_guest"
  ])
}

data "google_project" "project" {}

data "google_service_account" "appengine-default" {
  account_id = "${var.gcp_project}@appspot.gserviceaccount.com"
}

# TODO(mlazowik): replace with service accounts dedicated to different set of permissions, different accounts assigned
#  to different functions.
resource "google_project_iam_member" "appengine-default-secret-accessor" {
  project = data.google_project.project.id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${data.google_service_account.appengine-default.email}"
}

resource "google_cloudbuild_trigger" "build-trigger" {
  name            = local.backend_codebuild_name
  service_account = var.service_account

  github {
    owner = var.github_repo_owner
    name  = var.backend_github_repo_name
    push {
      branch = var.backend_github_repo_branch
    }
  }

  build {
    dynamic "step" {
      for_each = local.cloud_functions
      content {
        name = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
        args = [
          "gcloud",
          "functions",
          "deploy",
          step.value,
          "--region=${var.region}",
          "--source=.",
          "--trigger-http",
          "--runtime=python39",
          "--set-env-vars=PROJECT_ID=613656411888"
        ]

        wait_for = ["-"] # The "-" indicates that this step begins immediately.
      }
    }

    logs_bucket = module.backend_log_bucket.url
  }
}

module "backend_log_bucket" {
  source   = "../logbucket"
  name     = local.backend_bucket_name
  location = var.region
}