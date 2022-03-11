resource "google_cloudfunctions_function" "function" {
  name        = var.name
  description = var.description
  runtime     = var.runtime

  available_memory_mb = var.memory
  trigger_http        = true
  entry_point         = var.entrypoint

  timeout = var.timeout
}