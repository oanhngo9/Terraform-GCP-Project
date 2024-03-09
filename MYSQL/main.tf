resource "google_sql_database_instance" "main" {
  name                = "main-instance"
  database_version    = "MYSQL_5_7"
  deletion_protection = "false"
  region              = "us-central1"
  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
  }
}



resource "google_sql_user" "users" {
  name     = "me"
  instance = google_sql_database_instance.main.name
  host     = "me.com"
  password = "changeme"
}



resource "google_sql_database" "database" {
  name     = "wordpress"
  instance = google_sql_database_instance.main.name
}