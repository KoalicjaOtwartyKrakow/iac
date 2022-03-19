locals {
  backend_codebuild_name = "${var.gcp_project}-build-backend"
  backend_bucket_name    = "${var.gcp_project}-codebuild-backend-logs"

  project_id = data.google_project.project.number
  cloud_functions = toset([
    "add_accommodation",
    "get_all_accommodations",
    "delete_accommodation",
    "get_accommodation_by_id",
    "update_accommodation",
    "get_all_guests",
    "add_guest",
    "get_guest_by_id",
    "delete_guest",
    "update_guest",
    "get_all_hosts",
    "delete_host",
    "update_host",
    "add_host",
    "get_host_by_id",
    "get_hosts_by_status",
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
          "--set-env-vars=PROJECT_ID=${local.project_id}"
        ]

        wait_for = ["-"] # The "-" applied to all steps means that they will run in parallel.
      }
    }

    logs_bucket = module.backend_log_bucket.url

    options {
      machine_type = "E2_HIGHCPU_8"
    }
  }
}

module "backend_log_bucket" {
  source   = "../logbucket"
  name     = local.backend_bucket_name
  location = var.region
}