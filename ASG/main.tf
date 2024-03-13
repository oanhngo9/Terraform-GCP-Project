# Generate 16 characters random password 
resource "random_password" "password" {
  length  = 16
  numeric = false
  special = false
  lower   = true
  upper   = false
}

# ...

# Generate a random password for SQL user
resource "random_password" "sql_user_password" {
  length           = 16
  special          = true
  override_special = "_%@"  
}

# ...

# Create a Cloud SQL user with the randomly generated password
resource "google_sql_user" "users" {
  provider = google-beta
  name     = "wordpressuser"
  instance = google_sql_database_instance.instance.name
  password = random_password.sql_user_password.result
}