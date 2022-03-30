resource "google_dns_managed_zone" "zone" {
  name     = "zone"
  dns_name = "${var.dns_zone_name}."
}

resource "google_dns_record_set" "lb-app" {
  name = google_dns_managed_zone.zone.dns_name
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.zone.name

  rrdatas = [var.lb_ip]
}

resource "google_dns_record_set" "lb-metabase" {
  name = "query.${google_dns_managed_zone.zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.zone.name

  rrdatas = [var.lb_ip]
}
