terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.0.1"
    }
  }
}

provider "google" {
  project = "smart-nomad-433514-k5"
  region  = "us-central1"
}
