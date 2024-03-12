# Generate a random password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"  # Override the list of special characters to use
}

# Create a Cloud SQL user with the randomly generated password
resource "google_sql_user" "user" {
  name     = "db_user"
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
}