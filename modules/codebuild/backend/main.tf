locals {
  backend_codebuild_name = "${var.gcp_project}-build-backend"
  backend_bucket_name    = "${var.gcp_project}-codebuild-backend-logs"

  project_id = data.google_project.project.number
  cloud_functions = {
    # More RAM == more cpu
    # See https://cloud.google.com/functions/pricing#compute_time
    # TODO(mlazowik): revert to less after we add pagination
    accommodation_function  = "4096MB",
    # More RAM == more cpu
    # See https://cloud.google.com/functions/pricing#compute_time
    # TODO(mlazowik): revert to less after we add pagination
    guest_function  = "4096MB",
    # More RAM == more cpu
    # See https://cloud.google.com/functions/pricing#compute_time
    # TODO(mlazowik): revert to less after we add pagination
    host_function  = "4096MB",
    get_all_users  = "256MB",
  }

  cloud_functions_secrets = [
    "db_name",
    # TODO(mlazowik): swap to db_app_user when it's confirmed to work
    "db_user",
    # TODO(mlazowik): swap to db_app_pass when it's confirmed to work
    "db_pass",
    "db_socket_dir",
    "instance_connection_name",
    "sentry_dsn",
    "sentry_traces_sample_rate",
    "authorized_emails",
  ]
}

data "google_project" "project" {}

data "google_service_account" "appengine-default" {
  account_id = "${var.gcp_project}@appspot.gserviceaccount.com"
}

# TODO(mlazowik): replace with service accounts dedicated to different set of permissions, different accounts assigned
#  to different functions.
resource "google_secret_manager_secret_iam_member" "appengine-default-secret-accessor" {
  for_each = toset(local.cloud_functions_secrets)

  project = data.google_project.project.id
  secret_id = "projects/${var.gcp_project}/secrets/${each.value}"
  role = "roles/secretmanager.secretAccessor"
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
          "--set-env-vars=PROJECT_ID=${local.project_id}",
          # This secret binding is done at the runtime, not deployment time. This means that the function service
          # account does need to have IAM permissions to read those secrets.r
          "--set-secrets=${join(",", [
            "db_name=db_name:latest",
            "db_user=db_user:latest",
            "db_pass=db_pass:latest",
            "db_socket_dir=db_socket_dir:latest",
            "instance_connection_name=instance_connection_name:latest",
            "sentry_dsn=sentry_dsn:latest",
            "sentry_traces_sample_rate=sentry_traces_sample_rate:latest",
            "authorized_emails=authorized_emails:latest",
          ])}",
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