variable "gcp_project" {
  type        = string
  description = "GCP Project name"
  nullable    = false
}

variable "dns_zone_name" {
  type     = string
  nullable = false
}

variable "env_type" {
  type        = string
  description = "Dev or prod. Dev is less secure, for example backend CORS allows requests from localhost:3000"
  nullable    = false

  validation {
    condition     = contains(["dev", "prod"], var.env_type)
    error_message = "Allowed env types: dev, prod."
  }
}

variable "frontend_bucket_name" {
  type        = string
  description = "Frontend bucket name"
  nullable    = false
}

variable "functions_endpoint_cloud_run_name" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}
