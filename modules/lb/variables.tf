variable "gcp_project" {
  type        = string
  description = "GCP Project name"
  nullable    = false
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
