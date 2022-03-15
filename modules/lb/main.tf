data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "lb" {
  name = "lb"
}

resource "google_compute_global_forwarding_rule" "lb-http" {
  name       = "lb-http"
  target     = google_compute_target_http_proxy.lb.self_link
  ip_address = google_compute_global_address.lb.address
  port_range = "80"
}

resource "google_compute_target_http_proxy" "lb" {
  name    = "lb"
  url_map = google_compute_url_map.lb.self_link
}

resource "google_compute_url_map" "lb" {
  name = "lb"

  # TODO(mlazowik): replace with 404/redirect to canonical domain when we have it
  default_service = google_compute_backend_bucket.frontend-bucket-backend.self_link

  host_rule {
    # TODO(mlazowik): match the specific domain after we have it
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.frontend-bucket-backend.self_link

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.functions.self_link

      route_action {
        url_rewrite {
          path_prefix_rewrite = "/"
        }
      }
    }
  }
}

resource "google_compute_backend_bucket" "frontend-bucket-backend" {
  name        = "frontend-bucket-backend"
  bucket_name = var.frontend_bucket_name
  enable_cdn  = true

  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
  }
}

resource "google_compute_backend_service" "functions" {
  name = "functions"

  custom_response_headers = flatten([
    var.env_type == "dev" ? ["Access-Control-Allow-Origin: http://localhost:3000"] : [],
  ])

  backend {
    group = google_compute_region_network_endpoint_group.functions.id
  }
}

resource "google_compute_region_network_endpoint_group" "functions" {
  provider = google-beta

  name                  = "functions"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = var.functions_endpoint_cloud_run_name
  }
}
