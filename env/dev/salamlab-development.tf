terraform {
  backend "gcs" {
    bucket = "salamlab-development-terraform-state"
    prefix = "development.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>4.12.0"
    }
  }
}

provider "google" {
  credentials = file("salamlab-development.json")
  project     = "salamlab-development"
  region      = "europe-central2"
}

module "main" {
  source      = "../../main"
  project     = "salamlab-development"
  location  = "europe-central2"
}