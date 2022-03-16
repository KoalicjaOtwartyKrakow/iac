variable "gcp_project" {
  type        = string
  description = "GCP Project name"
  nullable    = false
}

variable "region" {
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

variable "dns_zone_name" {
  type     = string
  nullable = false
}

variable "endpoints-cloud-run-domain" {
  type     = string
  nullable = false
}

variable "frontend_creds_path" {
  type        = string
  description = "Path to sops-encrypted json with frontend secrets"
  nullable    = false
}

variable "github_repo_owner" {
  type        = string
  description = "Owner of the repo"
  nullable    = false
}

variable "frontend_github_repo_name" {
  type        = string
  description = "Name of the frontend repo"
  nullable    = false
}

variable "frontend_github_repo_branch" {
  type        = string
  description = "Name of the branch to build from frontend repo"
  nullable    = false
}

variable "backend_github_repo_name" {
  type        = string
  description = "Name of the backend repo"
  nullable    = false
}

variable "backend_github_repo_branch" {
  type        = string
  description = "Name of the branch to build from backend repo"
  nullable    = false
}

variable "db_tier" {
  type        = string
  description = "The machine type to use. Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312"
  nullable    = false
}

variable "db_availability_type" {
  type        = string
  description = "Either ZONAL or REGIONAL"
  nullable    = false
}

variable "db_creds_path" {
  type        = string
  description = "Path to sops-encrypted json with db secrets"
  nullable    = false
}

variable "db_retained_backups_count" {
  type        = number
  description = "Number of days to keep backups for"
  nullable    = false
}

variable "devs_group_email" {
  type     = string
  nullable = false
}
