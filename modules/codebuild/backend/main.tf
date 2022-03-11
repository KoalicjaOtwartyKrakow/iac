locals {
  backend_codebuild_name = "${var.gcp_project}-build-backend"
  backend_bucket_name    = "${var.gcp_project}-codebuild-backend-logs"
}

resource "google_cloudbuild_trigger" "build-trigger" {
  name            = local.backend_codebuild_name
  disabled        = true # TODO: waiting for fixing issue with cloud function
  service_account = var.service_account

  github {
    owner = var.github_repo_owner
    name  = var.backend_github_repo_name
    push {
      branch = var.backend_github_repo_branch
    }
  }

  build {
    step {
      name = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      args = ["gcloud", "functions", "deploy", "${var.backend_cloudfunction_name}", "--region=${var.region}", "--source=.", "--trigger-http", "--runtime=python39"]
    }

    logs_bucket = module.backend_log_bucket.url
  }
}

module "backend_log_bucket" {
  source   = "../logbucket"
  name     = local.backend_bucket_name
  location = var.region
}