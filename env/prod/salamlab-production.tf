terraform {
  backend "gcs" {
    bucket = "salamlab-production-terraform-state"
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
  project = "salamlab-production"
  region  = "europe-central2"

  # Requires the `Service Account Token Creator` role on people that need to run terraform.
  impersonate_service_account = "terraform-production@salamlab-production.iam.gserviceaccount.com"
}

provider "google-beta" {
  project = "salamlab-production"
  region  = "europe-central2"

  # Requires the `Service Account Token Creator` role on people that need to run terraform.
  #
  # Required roles on the terraform service account itself:
  # * Cloud Run Admin
  # * Compute Network Admin
  # * Editor
  # * Project IAM Admin
  # * Secret Manager Admin
  impersonate_service_account = "terraform-production@salamlab-production.iam.gserviceaccount.com"
}

module "main" {
  source      = "../../main"
  gcp_project = "salamlab-production"
  region      = "europe-central2"

  devs_group_email = "apartments-devs@koalicjaotwartykrakow.pl"

  env_type      = "prod"
  gsi_client_id = "510426673347-djors3udlj4vkcgf9haio8156bro1981"

  sentry_creds_path = "sentry-creds.enc.json"

  dns_zone_name = "apartments.r3.salamlab.pl"

  # See the comment inside `google_cloud_run_service`
  endpoints-cloud-run-domain = "api-36b5kwvwaq-lm.a.run.app"

  github_repo_owner           = "KoalicjaOtwartyKrakow"
  frontend_github_repo_name   = "frontend"
  frontend_github_repo_branch = "^main$"
  backend_github_repo_name    = "backend"
  backend_github_repo_branch  = "^main$"

  frontend_creds_path = "frontend-creds.enc.json"

  # > The db-f1-micro and db-g1-small machine types aren't included in the Cloud SQL SLA. These machine types are
  # > configured to use a shared-core CPU, and are designed to provide low-cost test and development instances only.
  # > Don't use them for production instances.
  #
  # https://cloud.google.com/sql/docs/mysql/instance-settings
  #
  # That's what Google says, but the price difference just does not justify using the SLA-backend instances, especially
  # at such low traffic. In practice I have not seen problems with f1/g1 instances, ever.
  db_tier                   = "db-f1-micro"
  db_availability_type      = "REGIONAL"
  db_retained_backups_count = 7
  db_creds_path             = "apartments-db-creds.enc.json"
  metabase_db_creds_path    = "metabase-db-creds.enc.json"

  config_creds_path = "config-creds.enc.json"

  accommodations_list_url = "https://query.apartments.r3.salamlab.pl/model/1-accommodations"
  guests_list_url         = "https://query.apartments.r3.salamlab.pl/model/2-guests"
  hosts_list_url          = "https://query.apartments.r3.salamlab.pl/model/3-hosts"
}

# To be set as the NS records for `dns_zone_name` in the `salamlab-dns` project.
output "dns_zone_ns_records" {
  value = module.main.dns_zone_ns_records
}
