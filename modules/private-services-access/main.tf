data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "google-services-addresses" {
  # When a Google service allocates a range on your behalf, the service uses the following format to name the
  # allocation: google-managed-services-[your network name]. If this allocation exists, Google services use the existing
  # one instead of creating another one.
  # https://cloud.google.com/vpc/docs/configure-private-services-access#considerations
  name          = "google-managed-services-${data.google_compute_network.default.name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.default.self_link
}

# Requires the `Compute Network Admin` on the terraform service account.
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.default.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google-services-addresses.name]
}
