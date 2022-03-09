locals {
  frontend_codebuild_name = "${var.gcp_project}-build-fronted"
  frontend_bucket_name    = "${var.gcp_project}-codebuild-fronted-logs"
  cloud_function_url      = "https://${var.region}-${var.gcp_project}.cloudfunctions.net/"
}

resource "google_cloudbuild_trigger" "build-trigger" {
  name = local.frontend_codebuild_name

  github {
    owner = var.github_repo_owner
    name  = var.frontend_github_repo_name
    push {
      branch = var.frontend_github_repo_branch
    }
  }

  build {
    step {
      name       = "node:14-alpine"
      entrypoint = "yarn"
      args       = ["install"]
    }
    step {
      name       = "node:14-alpine"
      entrypoint = "yarn"
      args       = ["run", "build"]
      env = [
        "REACT_APP_KOKON_API_URL=${local.cloud_function_url}",
        "REACT_APP_KOKON_ROUTER_BASENAME=",
        "REACT_APP_KOKON_API_USE_MOCKS=false"
      ]
    }
    # upload dummy file if bucket is empty. See https://github.com/GoogleCloudPlatform/gsutil/issues/417 for more explanation
    step {
      name = "alpine:3.15.0"
      args = ["touch", "dummy.txt"]
    }
    step {
      name = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      args = ["gsutil", "cp", "dummy.txt", "${var.frontend_build_bucket_url}"]
    }
    step {
      name = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      args = ["gsutil", "rm", "-rf", "${var.frontend_build_bucket_url}/*"]
    }
    step {
      name = "gcr.io/google.com/cloudsdktool/cloud-sdk:376.0.0-alpine"
      args = ["gsutil", "cp", "-r", "build/*", "${var.frontend_build_bucket_url}"]
    }

    logs_bucket = module.fronted_log_bucket.url
  }
}

module "fronted_log_bucket" {
  source   = "../logbucket"
  name     = local.frontend_bucket_name
  location = var.region
}