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
  byte_length = 12
}

resource "google_project" "gcp_team_project" {
  name            = "gcp-team-project"
  project_id      = "gcp-${random_id.project_id.hex}"
  billing_account = data.google_billing_account.acct.id

  depends_on = [random_id.project_id]
}

# Set terminal to the project
resource "null_resource" "set_project" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "gcloud config set project ${google_project.gcp_team_project.project_id}"
  }
}

# Enable list of services
resource "null_resource" "enable-apis" {
  depends_on = [
    google_project.gcp_team_project,
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

# Create VPC for the project
resource "google_compute_network" "dec_vpc_network" {
  name = "dec-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.dec_vpc_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.dec_vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]  
}

# Create ASG for the project
resource "google_compute_autoscaler" "asg" {
  zone   = "us-central1-a"  
  name   = "dec-gcp-team-asg" 
  target = google_compute_instance_group_manager.asg_instance.self_link
  autoscaling_policy {
    max_replicas    = 5  
    min_replicas    = 1  
    cooldown_period = 60  
    cpu_utilization {
      target = 0.5 
    }
  }
}

resource "google_compute_target_pool" "target_pool_1" {
  region   = "us-central1"  
  name     = "dec-gcp-team-tp"  
}

resource "google_compute_instance_group_manager" "asg_instance" {
  zone     = "us-central1-a"  
  name     = "instance-group-manager-dec-gcp-team"  
  version {
    instance_template = google_compute_instance_template.new_instance_template.self_link
    name              = "primary"
  }
  target_pools       = [google_compute_target_pool.target_pool_1.self_link]
  base_instance_name = "base-name"
}

resource "google_compute_instance_template" "new_instance_template" {
  name           = "template-dec-gcp-team"  
  machine_type   = "e2-medium" 
  can_ip_forward = false

  metadata = {
    db-name = google_sql_database_instance.instance.name
    db-user = google_sql_user.users.name
    db-password = random_password.password.result
  }

  metadata_startup_script = <<SCRIPT
  #!/bin/bash
  set -e  # Stop the script if any command fails
  sudo apt-get update
  sudo apt-get install -y apache2 unzip wget
  sudo systemctl start apache2
  sudo systemctl enable apache2
  sudo rm -rf /var/www/html/*
  cd /tmp
  wget https://wordpress.org/latest.zip
  unzip latest.zip
  sudo mv wordpress/* /var/www/html/
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository ppa:ondrej/php
  sudo apt-get update
  sudo apt-get install -y php7.3 php7.3-mysql
  sudo systemctl restart apache2
  php --version
  sudo chown -R www-data:www-data /var/www/html
  # Configure WordPress to connect to the MySQL database
  DB_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-name -H "Metadata-Flavor: Google")
  DB_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-user -H "Metadata-Flavor: Google")
  DB_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-password -H "Metadata-Flavor: Google")
  DOMAIN_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/domain-name -H "Metadata-Flavor: Google")
  sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
  sudo bash -c "sed -i \"s/database_name_here/$DB_NAME/g\" /var/www/html/wp-config.php"
  sudo bash -c "sed -i \"s/username_here/$DB_USER/g\" /var/www/html/wp-config.php"
  sudo bash -c "sed -i \"s/password_here/$DB_PASSWORD/g\" /var/www/html/wp-config.php"
  sudo bash -c "echo \"define('WP_HOME','http://$DOMAIN_NAME');\" >> /var/www/html/wp-config.php"
  sudo bash -c "echo \"define('WP_SITEURL','http://$DOMAIN_NAME');\" >> /var/www/html/wp-config.php"
  # Install Certbot and obtain an SSL certificate
  sudo apt-get install -y certbot python-certbot-apache
  sudo certbot --apache -n --agree-tos --email your-email@example.com -d $DOMAIN_NAME
  # Update WordPress configuration to use HTTPS
  sudo bash -c "echo \"define('WP_HOME','https://$DOMAIN_NAME');\" >> /var/www/html/wp-config.php"
  sudo bash -c "echo \"define('WP_SITEURL','https://$DOMAIN_NAME');\" >> /var/www/html/wp-config.php"
SCRIPT

  disk {
    source_image = data.google_compute_image.debian.self_link  
  }
  network_interface {
    network = google_compute_network.dec_vpc_network.self_link  
    access_config {
    }
  }
}

  disk {
    source_image = data.google_compute_image.debian.self_link  
  }
  network_interface {
    network = google_compute_network.dec_vpc_network.self_link  
    access_config {
    }
  }
}

data "google_compute_image" "debian" {  
  family   = "debian-10"
  project  = "debian-cloud"
}

# Create Firewall
resource "google_compute_firewall" "firewall" {
  name    = "firewall-rule-name"
  network = google_compute_network.dec_vpc_network.self_link  

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create Load Balancer
resource "google_compute_forwarding_rule" "fr" {
  name     = "forwarding-rule-name"
  region   = "us-central1"

  target = google_compute_target_pool.target_pool_1.self_link
  port_range = "80"
}

# Generate a random password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"  
}

# Create MYSQL
resource "google_sql_database_instance" "instance" {
  provider = google-beta
  name     = "dec-gcp-team-wordpress-database"
  region   = "us-central1"
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.dec_vpc_network.self_link  
    }
    backup_configuration {
      enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Create a Cloud SQL user with the randomly generated password
resource "google_sql_user" "users" {
  provider = google-beta
  name     = "wordpressuser"
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
}