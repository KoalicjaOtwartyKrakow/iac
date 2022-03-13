terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6.3"
    }
  }
}

data "sops_file" "creds" {
  source_file = var.creds_path
}

resource "google_secret_manager_secret" "creds" {
  # Keys are not sensitive
  for_each = nonsensitive(data.sops_file.creds.data)

  secret_id = each.key

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "creds" {
  # Keys are not sensitive
  for_each = nonsensitive(data.sops_file.creds.data)

  secret = google_secret_manager_secret.creds[each.key].id

  secret_data = each.value
}
