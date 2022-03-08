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

variable "main_page_suffix" {
  type        = string
  description = "Region or multiregion location"
  default     = "index.html"
  nullable    = false
}