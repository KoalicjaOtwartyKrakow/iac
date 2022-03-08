variable "name" {
  type        = string
  description = "Name of the logbucket"
  nullable    = false
}

variable "location" {
  type        = string
  description = "Region or multiregion location"
  nullable    = false
}