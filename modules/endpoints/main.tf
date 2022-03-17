data "google_dns_managed_zone" "zone" {
  name = var.zone_name
}

resource "google_cloud_run_service" "api" {
  name     = "api"
  location = var.location

  template {
    spec {
      containers {
        image = "gcr.io/endpoints-release/endpoints-runtime-serverless:2"
        # XXX(mlazowik): when applying for the first time you have to
        # 1. comment out the env block and google_endpoints_service
        # 2. apply
        # 3. uncomment google_endpoints_service, add the google_cloud_run_service.api.status[0].url (without https://,
        #    get it from https://console.cloud.google.com/run/detail/europe-central2/api/metrics?project=<project_id>)
        #    to the api yaml file host field, and as the `endpoints-cloud-run-domain` var in your terraform main module config
        # 4. apply
        # 5. uncomment the env block
        # 6. apply
        #
        # Related: https://github.com/hashicorp/terraform-provider-google/issues/5528
        env {
          # Looks like this is no longer officially supported but at this point I couldn't be bothered.
          # See: https://github.com/GoogleCloudPlatform/esp-v2/blob/f8d98017f9bce27b9fe0a49bb93045558667ca08/docker/serverless/env_start_proxy.py#L22
          #
          # TODO(mlazowik): consider moving to sth like https://github.com/hashicorp/terraform-provider-google/issues/5528#issuecomment-652411455
          name  = "ENDPOINTS_SERVICE_NAME"
          value = var.endpoints-cloud-run-domain
        }
      }
    }
  }
}

resource "google_endpoints_service" "openapi_service" {
  service_name   = var.endpoints-cloud-run-domain
  project        = var.gcp_project
  openapi_config = file("api.yaml")
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Auth is handled by endpoints, not cloud run
resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.api.location
  project  = google_cloud_run_service.api.project
  service  = google_cloud_run_service.api.name

  policy_data = data.google_iam_policy.noauth.policy_data
}