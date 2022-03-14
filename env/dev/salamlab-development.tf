terraform {
  backend "gcs" {
    bucket = "salamlab-development-terraform-state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>4.12.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6.3"
    }
  }
}

provider "google" {
  project = "salamlab-development"
  region  = "europe-central2"

  # Requires the `Service Account Token Creator` role on people that need to run terraform.
  impersonate_service_account = "terraform-development@salamlab-development.iam.gserviceaccount.com"
}

provider "google-beta" {
  project = "salamlab-development"
  region  = "europe-central2"

  # Requires the `Service Account Token Creator` role on people that need to run terraform.
  #
  # Required roles on the terraform service account itself:
  # * Cloud Run Admin
  # * Compute Network Admin
  # * Editor
  # * Project IAM Admin
  # * Secret Manager Admin
  impersonate_service_account = "terraform-development@salamlab-development.iam.gserviceaccount.com"
}

module "main" {
  source      = "../../main"
  gcp_project = "salamlab-development"
  region      = "europe-central2"

  # See the comment inside `google_cloud_run_service`
  endpoints-cloud-run-domain = "api-lrkrxtdxwa-lm.a.run.app"

  github_repo_owner           = "KoalicjaOtwartyKrakow"
  frontend_github_repo_name   = "frontend"
  frontend_github_repo_branch = "^main$"
  backend_github_repo_name    = "backend"
  backend_github_repo_branch  = "^dev$"

  frontend_creds_path = "frontend-creds.enc.json"

  # > The db-f1-micro and db-g1-small machine types aren't included in the Cloud SQL SLA. These machine types are
  # > configured to use a shared-core CPU, and are designed to provide low-cost test and development instances only.
  # > Don't use them for production instances.
  #
  # https://cloud.google.com/sql/docs/mysql/instance-settings
  db_tier = "db-f1-micro"
  # TODO(https://github.com/KoalicjaOtwartyKrakow/iac/issues/16): potentially set to REGIONAL for prod, pending results
  #  of the uptime goals discussion.
  db_availability_type      = "ZONAL"
  db_retained_backups_count = 7
  db_creds_path             = "apartments-db-creds.enc.json"
}
