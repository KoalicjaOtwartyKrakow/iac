output "dns_zone_ns_records" {
  value = google_dns_managed_zone.zone.name_servers
}