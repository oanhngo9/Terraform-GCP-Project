resource "random_password" "password" {
  length  = 16
  special = true
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta
  name     = "dec-gcp-team-wordpress-database"
  region   = "us-central1"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.self_link
    }
    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  provider = google-beta
  name     = "wordpress"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  provider = google-beta
  name     = "wordpressuser"
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
}