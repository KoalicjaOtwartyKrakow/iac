locals {
  backend_codebuild_name = "${var.gcp_project}-build-backend"
  backend_bucket_name    = "${var.gcp_project}-codebuild-backend-logs"

  project_id = data.google_project.project.number
  cloud_functions = {
    add_accommodation = "256MB",
    # More RAM == more cpu
    # See https://cloud.google.com/functions/pricing#compute_time
    # TODO(mlazowik): revert to less after we add pagination
    get_all_accommodations  = "4096MB",
    delete_accommodation    = "256MB",
    get_accommodation_by_id = "256MB",
    update_accommodation    = "256MB",
    # More RAM == more cpu
    # See https://cloud.google.com/functions/pricing#compute_time
    # TODO(mlazowik): revert to less after we add pagination
    get_all_guests  = "4096MB",
    add_guest       = "256MB",
    get_guest_by_id = "256MB",
    delete_guest    = "256MB",
    update_guest    = "256MB",
    # More RAM == more cpu
    # See https://cloud.google.com/functions/pricing#compute_time
    # TODO(mlazowik): revert to less after we add pagination
    get_all_hosts  = "4096MB",
    delete_host    = "256MB",
    update_host    = "256MB",
    add_host       = "256MB",
    get_host_by_id = "256MB",
    get_all_users  = "256MB",
  }
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
    step {
      id         = "migrate"
      name       = "python:3.9"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        trimspace(
          <<-EOT
          wget "https://storage.googleapis.com/cloudsql-proxy/$$${CLOUD_SQL_PROXY_VERSION}/cloud_sql_proxy.linux.amd64" -O cloud_sql_proxy &&
          chmod +x cloud_sql_proxy &&
          pip install -r requirements.txt &&
          ./cloud_sql_proxy -instances=$$${INSTANCE_CONNECTION_NAME}=tcp:5432 & sleep 2 &&
          alembic upgrade head
          EOT
        )
      ]
      secret_env = [
        "db_name",
        "db_user",
        "db_pass",
        "INSTANCE_CONNECTION_NAME",
        "db_app_user",  # Name of the role to create for the app
        "db_app_pass"  # Password of the role to create for the app
      ]
      env = [
        "IS_LOCAL_DB=True",
        "CLOUD_SQL_PROXY_VERSION=v1.21.0"
      ]
    }

    dynamic "step" {
      for_each = local.cloud_functions
      content {
        name = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
        args = [
          "gcloud",
          "functions",
          "deploy",
          step.key,
          "--memory=${step.value}",
          "--region=${var.region}",
          "--source=.",
          "--trigger-http",
          "--runtime=python39",
          "--set-env-vars=PROJECT_ID=${local.project_id}"
        ]

        wait_for = ["migrate"] # The "migrate" applied to all steps means that they will run in parallel, after migrate.
      }
    }

    available_secrets {
      secret_manager {
        env          = "db_name"
        version_name = "projects/${var.gcp_project}/secrets/db_name/versions/latest"
      }
      secret_manager {
        env          = "db_pass"
        version_name = "projects/${var.gcp_project}/secrets/db_pass/versions/latest"
      }
      secret_manager {
        env          = "db_user"
        version_name = "projects/${var.gcp_project}/secrets/db_user/versions/latest"
      }
      secret_manager {
        env          = "INSTANCE_CONNECTION_NAME"
        version_name = "projects/${var.gcp_project}/secrets/instance_connection_name/versions/latest"
      }
      secret_manager {
        env          = "db_app_user"
        version_name = "projects/${var.gcp_project}/secrets/db_app_user/versions/latest"
      }
      secret_manager {
        env          = "db_app_pass"
        version_name = "projects/${var.gcp_project}/secrets/db_app_pass/versions/latest"
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