variable "gcp_project" {
  type        = string
  description = "GCP Project name"
  nullable    = false
}

variable "location" {
  type        = string
  description = "Region or multiregion location"
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

variable "db_creds_path" {
  type        = string
  description = "Path to sops-encrypted json with db secrets"
  nullable    = false
}

variable "metabase_db_creds_path" {
  type        = string
  description = "Path to sops-encrypted json with db secrets"
  nullable    = false
}
