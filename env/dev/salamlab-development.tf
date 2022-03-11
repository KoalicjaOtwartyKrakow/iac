terraform {
  backend "gcs" {
    bucket = "salamlab-development-terraform-state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>4.12.0"
    }
  }
}

provider "google" {
  project = "salamlab-development"
  region  = "europe-central2"

  # Requires the `Service Account Token Creator` role on people that need to run terraform.
  impersonate_service_account = "terraform-development@salamlab-development.iam.gserviceaccount.com"
}

module "main" {
  source      = "../../main"
  gcp_project = "salamlab-development"
  region      = "europe-central2"

  github_repo_owner           = "KoalicjaOtwartyKrakow"
  frontend_github_repo_name   = "frontend"
  frontend_github_repo_branch = "^main$"
  backend_github_repo_name    = "backend"
  backend_github_repo_branch  = "^dev$"
}