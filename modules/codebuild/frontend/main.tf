terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6.3"
    }
  }
}

locals {
  frontend_codebuild_name = "${var.gcp_project}-build-fronted"
  frontend_bucket_name    = "${var.gcp_project}-codebuild-fronted-logs"
  env = [
    "REACT_APP_KOKON_API_URL=/api",
    "REACT_APP_KOKON_ROUTER_BASENAME=/",
    "PUBLIC_URL=/",
    "REACT_APP_KOKON_API_USE_MOCKS=false",
    "REACT_APP_ENV=${var.env_type}",
    "REACT_APP_SENTRY_DSN=${data.sops_file.sentry_creds.data["sentry_frontend_dsn"]}",
    "REACT_APP_SENTRY_TRACES_SAMPLE_RATE=${data.sops_file.sentry_creds.data["sentry_frontend_traces_sample_rate"]}",
    "REACT_APP_KOKON_GSI_CLIENT_ID=${var.gsi_client_id}",
    "REACT_APP_KOKON_OVERRIDE_ROUTE_ACCOMMODATIONS=${var.accommodations_list_url}",
    "REACT_APP_KOKON_OVERRIDE_ROUTE_GUESTS=${var.guests_list_url}",
    "REACT_APP_KOKON_OVERRIDE_ROUTE_HOSTS=${var.hosts_list_url}",
  ]
  google_token_env = [
    "REACT_APP_GOOGLE_CLIENTID=${data.sops_file.sentry_creds.data["google_client_id"]}",
    "REACT_APP_GOOGLE_CLIENT_SECRET=${data.sops_file.sentry_creds.data["google_client_secret"]}",
    "GOOGLE_REFRESH_TOKEN=${data.sops_file.sentry_creds.data["google_refresh_token"]}"
  ]
}

data "sops_file" "sentry_creds" {
  source_file = var.sentry_creds_path
}

resource "google_cloudbuild_trigger" "build-trigger" {
  name            = local.frontend_codebuild_name
  service_account = var.service_account

  github {
    owner = var.github_repo_owner
    name  = var.frontend_github_repo_name
    push {
      branch = var.frontend_github_repo_branch
    }
  }

  build {
    step {
      name       = "node:16-alpine"
      id         = "FontAwsome"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        trimspace(
          <<-EOT
          npm config set "@fortawesome:registry" https://npm.fontawesome.com/
          npm config set "//npm.fontawesome.com/:_authToken=$$FONTAWESOME_TOKEN"
          yarn install
          EOT
        )
      ]
      secret_env = ["FONTAWESOME_TOKEN"]
    }
    step {
      name       = "node:16-alpine"
      id         = "Build"
      entrypoint = "yarn"
      args       = ["run", "build"]
      env        = local.env
    }
    step {
      name     = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      id       = "CopyNoCache"
      args     = ["gsutil", "-m", "-h", "Cache-Control: no-store", "cp", "-r", "build/*", "${var.frontend_build_bucket_url}"]
      wait_for = ["Build"]
    }
    step {
      name     = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      id       = "CopyImmutable"
      args     = ["gsutil", "-m", "-h", "Cache-Control: max-age=31536000, immutable", "cp", "-r", "build/static", "${var.frontend_build_bucket_url}"]
      wait_for = ["CopyNoCache"]
    }
    step {
      name     = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      id       = "CopyCached"
      args     = ["gsutil", "-m", "-h", "Cache-Control: max-age=900", "cp", "-r", "build/locales", "${var.frontend_build_bucket_url}"]
      wait_for = ["CopyNoCache"]
    }
    step {
      name       = "cypress/base:16.14.2"
      id         = "TestsE2E"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        trimspace(
          <<-EOT
          npm start &
          sleep 90s &&
          npm run cypress
          EOT
        )
      ]
      env      = concat(local.env, local.google_token_env)
      wait_for = ["Build"]
    }

    available_secrets {
      secret_manager {
        env          = "FONTAWESOME_TOKEN"
        version_name = "projects/${var.gcp_project}/secrets/fontawesome_token/versions/latest"
      }
    }

    logs_bucket = module.fronted_log_bucket.url

    options {
      machine_type = "E2_HIGHCPU_8"
    }
  }
}

module "fronted_log_bucket" {
  source   = "../logbucket"
  name     = local.frontend_bucket_name
  location = var.region
}