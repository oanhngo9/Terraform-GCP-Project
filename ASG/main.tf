# Create VPC for the project
resource "google_compute_network" "dec_vpc_network" {
  name = "dec-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
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
sudo rm -f /var/www/html/wp-config.php
cat <<EOF | sudo tee /var/www/html/wp-config.php
<?php
define('DB_NAME', '${google_sql_database_instance.instance.name}');
define('DB_USER', '${google_sql_user.users.name}');
define('DB_PASSWORD', '${random_password.password.result}');
define('DB_HOST', '${google_sql_database_instance.instance.ip_address}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
EOF
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
  database_version = "MYSQL_5_7" // Add this line

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
}

# Create a Cloud SQL user with the randomly generated password
resource "google_sql_user" "wordpressuser" {
  name     = "wordpressuser"
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
  depends_on = [google_sql_database_instance.instance]
}