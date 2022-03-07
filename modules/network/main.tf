locals {
  vpc_name = "main-vpc-${var.environment}"
}

resource "google_compute_network" "vpc_network" {
  name = local.vpc_name
}