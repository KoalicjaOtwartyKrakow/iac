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
  }
}

resource "google_compute_backend_bucket" "frontend-bucket-backend" {
  name        = "frontend-bucket-backend"
  bucket_name = var.frontend_bucket_name
  enable_cdn  = true
}
