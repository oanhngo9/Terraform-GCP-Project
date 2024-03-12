data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

resource "random_password" "password" {
  length  = 16
  numeric = false
  special = false
  lower   = true
  upper   = false
}

provider "random" {}

resource "random_id" "project_id" {
  byte_length = 8
}

resource "google_project" "gcp_terraform_project" {
  name            = "gcp-terraform-project"
  project_id      = "gcp-${random_id.project_id.hex}"
  billing_account = data.google_billing_account.acct.id
}

resource "null_resource" "set_project" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "gcloud config set project ${google_project.gcp_terraform_project.project_id}"
  }
}

