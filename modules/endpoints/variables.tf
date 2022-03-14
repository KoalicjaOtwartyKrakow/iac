variable "gcp_project" {
  type        = string
  description = "GCP Project name"
  nullable    = false
}

variable "endpoints-cloud-run-domain" {
  type     = string
  nullable = false
}

variable "location" {
  type        = string
  description = "Region or multiregion location"
  nullable    = false
}

variable "zone_name" {
  type     = string
  nullable = false
}
