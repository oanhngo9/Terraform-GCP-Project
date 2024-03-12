resource "google_compute_network" "vpc_network" {
  name = "oanh-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "my-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_compute_firewall" "default" {
  name    = "my-firewall-rule"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}