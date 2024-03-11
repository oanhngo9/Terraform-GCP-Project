resource "google_sql_database_instance" "default" {
  name             = "oanh-wordpress-db-instance"
  database_version = "MYSQL_5_7"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc_network.self_link
    }

    backup_configuration {
      enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "default" {
  name     = "oanh-wordpress-db"
  instance = google_sql_database_instance.default.name
}