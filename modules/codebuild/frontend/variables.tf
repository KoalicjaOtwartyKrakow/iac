variable "gcp_project" {
  type        = string
  description = "GCP Project name"
  nullable    = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "service_account" {
  type     = string
  nullable = false
}

variable "sentry_creds_path" {
  type        = string
  description = "Path to sops-encrypted json with sentry secrets"
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

variable "frontend_build_bucket_url" {
  type        = string
  description = "URL (in gs format) to frontend bucket"
  nullable    = false
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
