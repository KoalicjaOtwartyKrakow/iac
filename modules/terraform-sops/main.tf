# To be used with https://github.com/carlpett/terraform-provider-sops

resource "google_kms_key_ring" "terraform-sops" {
  name     = "terraform-sops-keyring"
  location = "global"
}

resource "google_kms_crypto_key" "terraform-sops" {
  name            = "terraform-sops-key"
  key_ring        = google_kms_key_ring.terraform-sops.id
  rotation_period = "2592000s" # 30 days

  lifecycle {
    prevent_destroy = true
  }
}
