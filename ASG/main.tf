# Create ASG for the project
resource "google_compute_network" "gcp_vpc_network" {
  name = "gcp-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_autoscaler" "asg" {
  provider = google-beta
  zone   = "us-central1-a"  
  name   = "dec-gcp-team"  
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
  provider = google-beta
  region   = "us-central1"  
  name     = "dec-gcp-team" 
  project  = "gcp-terraform-project"  
}

resource "google_compute_instance_group_manager" "asg_instance" {
  provider = google-beta
  zone     = "us-central1-a"  
  name     = "instance-group-manager-dec-gcp-team"  
  project  = "gcp-terraform-project"  
  version {
    instance_template = google_compute_instance_template.instance_template.self_link
    name              = "primary"
  }
  target_pools       = [google_compute_target_pool.target_pool_1.self_link]
  base_instance_name = "base-name"
}

resource "google_compute_instance_template" "instance_template" {
  provider = google-beta
  name           = "template-dec-gcp-team"  
  machine_type   = "e2-medium" 
  can_ip_forward = false
  project        = "gcp-terraform-project"  

  metadata_startup_script = <<SCRIPT
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
SCRIPT

  disk {
    source_image = data.google_compute_image.debian.self_link  
  }
  network_interface {
    network = google_compute_network.gcp_vpc_network.self_link
    access_config {
    }
  }
}

data "google_compute_image" "debian" {  
  provider = google-beta
  family   = "debian-9"
  project  = "debian-cloud"
}

# Create Firewall
resource "google_compute_firewall" "firewall" {
  provider = google-beta
  name    = "firewall-rule-name"
  network = google_compute_network.gcp_vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create Load Balancer
resource "google_compute_forwarding_rule" "fr" {
  provider = google-beta
  name     = "forwarding-rule-name"
  region   = "us-central1"

  target = google_compute_target_pool.target_pool_1.self_link
  port_range = "80"
}