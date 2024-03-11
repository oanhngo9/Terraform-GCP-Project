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

    database_flags {
      name  = "require_secure_transport"
      value = "ON"
    }

    backup_configuration {
      enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "users" {
  name     = "me"
  instance = google_sql_database_instance.default.name
  host     = "me.com"
  password = random_password.password.result
}

resource "google_secret_manager_secret" "ssh-key" {
  secret_id = "ssh-key"
}

resource "google_secret_manager_secret_version" "ssh-key-version" {
  secret      = google_secret_manager_secret.ssh-key.id
  secret_data = random_password.password.result
}

resource "google_sql_database" "default" {
  name     = "oanh-wordpress-db"
  instance = google_sql_database_instance.default.name
}

resource "google_sql_ssl_cert" "default" {
  name_prefix = "mysql-ssl-cert"
  common_name = "www.example.com" // replace with your domain name
  instance    = google_sql_database_instance.default.name
}