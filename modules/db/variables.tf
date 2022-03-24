variable "tier" {
  type        = string
  description = "The machine type to use. Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312"
  nullable    = false
}

variable "availability_type" {
  type        = string
  description = "Either ZONAL or REGIONAL"
  nullable    = false
}

variable "retained_backups_count" {
  type        = number
  description = "Number of days to keep backups for"
  nullable    = false
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
