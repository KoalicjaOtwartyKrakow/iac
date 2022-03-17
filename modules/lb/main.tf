data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "lb" {
  name = "lb"
}

resource "google_compute_global_forwarding_rule" "http-redirect" {
  name       = "http-redirect"
  target     = google_compute_target_http_proxy.http-redirect.self_link
  ip_address = google_compute_global_address.lb.address
  port_range = "80"
}

resource "google_compute_target_http_proxy" "http-redirect" {
  name    = "http-redirect"
  url_map = google_compute_url_map.http-redirect.self_link
}

resource "google_compute_url_map" "http-redirect" {
  name = "http-redirect"

  default_url_redirect {
    redirect_response_code = "PERMANENT_REDIRECT" # 308 preservers request method, as opposed to 301
    strip_query            = false
    https_redirect         = true
  }
}

resource "google_compute_global_forwarding_rule" "lb-https" {
  name       = "lb-https"
  target     = google_compute_target_https_proxy.lb.self_link
  ip_address = google_compute_global_address.lb.address
  port_range = "443"
}

resource "google_compute_target_https_proxy" "lb" {
  name    = "lb"
  url_map = google_compute_url_map.lb.self_link

  ssl_certificates = [
    google_compute_managed_ssl_certificate.cert1v1.id
  ]
}

# Max 100 SANs per certificate.
#
# WARNING: to avoid downtime for existing domains while the certificate is being provisioned copy this certificate
# to a new one (eg. cert1v1 -> cert1v2), and after the new one is provisioned remove the old one.
#
# We can't just add a new cert with only the new domains as there is a low (15) limit of certs per target ssl proxy:
# https://cloud.google.com/load-balancing/docs/quotas#target_pools_and_target_proxies
resource "google_compute_managed_ssl_certificate" "cert1v1" {
  name = "cert1v1"

  managed {
    domains = ["${var.dns_zone_name}."]
  }
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

  # Comment this out during the first apply, or an apply that changes this property. Set the desired state manually,
  # then uncomment and apply again to check that you have matched the desired state properly.
  #
  # Reason is a bug in Google's API: https://stackoverflow.com/a/66935277
  custom_response_headers = [
    "Strict-Transport-Security:max-age=31536000; includeSubDomains",
  ]

  # Comment this out during the first apply, or an apply that changes this property. Set the desired state manually,
  # then uncomment and apply again to check that you have matched the desired state properly.
  #
  # Reason is a bug in Google's API: https://stackoverflow.com/a/66935277
  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
  }
}

resource "google_compute_backend_service" "functions" {
  name = "functions"

  custom_response_headers = flatten([
    "Strict-Transport-Security: max-age=31536000; includeSubDomains",
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
