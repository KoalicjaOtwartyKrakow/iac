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

variable "github_repo_owner" {
  type        = string
  description = "Owner of the repo"
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