variable "name" {
  type     = string
  nullable = false
}

variable "description" {
  type    = string
  default = ""
}

variable "runtime" {
  type    = string
  default = ""
}

variable "memory" {
  type    = number
  default = 256
}

variable "entrypoint" {
  type     = string
  nullable = false
}

variable "timeout" {
  type    = number
  default = 60
}