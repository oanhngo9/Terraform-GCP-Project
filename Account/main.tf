# Show Billing Account Infomation
data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

# Generate 16 characters random password 
resource "random_password" "password" {
  length  = 16
  numeric = false
  special = false
  lower   = true
  upper   = false
}

# Create new Project_ID
provider "random" {}

resource "random_id" "project_id" {
  byte_length = 9
}

resource "google_project" "dec_gcp_team_project" {
  name            = "dec-gcp-team-project"
  project_id      = "gcp-${random_id.project_id.hex}"
  billing_account = data.google_billing_account.acct.id

  depends_on = [random_id.project_id_suffix]
}

# Set terminal to the project
resource "null_resource" "set_project" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "gcloud config set project ${google_project.dec_gcp_team_project.project_id}"
  }
}

# Enable list of services
resource "null_resource" "enable-apis" {
  depends_on = [
    google_project.dec_gcp_team_project,
    null_resource.set_project
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
        gcloud services enable compute.googleapis.com
        gcloud services enable dns.googleapis.com
        gcloud services enable storage-api.googleapis.com
        gcloud services enable container.googleapis.com
        gcloud services enable file.googleapis.com
    EOT
  }
}
